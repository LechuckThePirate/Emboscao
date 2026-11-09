dofile("setupTests.lua")

local FILES = { "Modules/Core/Secret.lua", "Modules/Rogue/Combo.lua", "Modules/Rogue/Energy.lua", "Modules/Rogue/Poisons.lua",
    "Modules/Rogue/Reagents.lua", "Modules/Rogue/Auras.lua" }

describe("Combo points", function()
    local ns
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon({ files = FILES })
    end)

    it("reads the points on the target, out of 5", function()
        WowMock.combo = 3
        local points, max = ns.Combo_Get()
        assert.are.equal(3, points)
        assert.are.equal(5, max)
    end)

    it("falls back to the power API without GetComboPoints", function()
        local saved = GetComboPoints
        _G.GetComboPoints = nil
        WowMock.combo = 2
        assert.are.equal(2, (ns.Combo_Get()))
        _G.GetComboPoints = saved
    end)
end)

describe("Energy tick", function()
    local ns
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon({ files = FILES })
    end)

    it("knows nothing until a tick is seen", function()
        assert.is_nil(ns.Energy_TickProgress(10))
    end)

    it("a rise of 20 is a tick; the progress cycles every 2 seconds", function()
        ns.Energy_OnChange(40, 100, 9)
        ns.Energy_OnChange(60, 100, 10)
        assert.are.equal(0, ns.Energy_TickProgress(10))
        assert.are.equal(0.5, ns.Energy_TickProgress(11))
        assert.are.equal(0.25, ns.Energy_TickProgress(12.5))
    end)

    it("Relentless Strikes (25) and Thistle Tea (100) are not ticks", function()
        ns.Energy_OnChange(0, 100, 1)
        ns.Energy_OnChange(25, 100, 2)
        assert.is_nil(ns.Energy_TickProgress(3))
        ns.Energy_OnChange(0, 100, 3)
        ns.Energy_OnChange(100, 100, 3.3)
        assert.is_nil(ns.Energy_TickProgress(4))
    end)

    it("a short rise up to full energy is a tick; Adrenaline Rush's 40 too", function()
        ns.Energy_OnChange(95, 100, 1)
        ns.Energy_OnChange(100, 100, 2)
        assert.are.equal(0, ns.Energy_TickProgress(2))
        ns.Energy_OnChange(20, 100, 3)
        ns.Energy_OnChange(60, 100, 4)
        assert.are.equal(0, ns.Energy_TickProgress(4))
    end)

    it("spending energy is not a tick", function()
        ns.Energy_OnChange(100, 100, 1)
        ns.Energy_OnChange(60, 100, 2)
        assert.is_nil(ns.Energy_TickProgress(2))
    end)
end)

describe("Poisons", function()
    local ns
    local opts = { minutes = 5, charges = 10, offHand = true }
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon({ files = FILES })
        WowMock.inventory = { [16] = 100, [17] = 101 }
        WowMock.items = { [100] = { classID = 2 }, [101] = { classID = 2 } }
    end)

    it("evaluates one hand", function()
        assert.are.equal("missing", (ns.Poisons_Evaluate(false, 0, 0, 5, 10)))
        assert.are.equal("expiring", (ns.Poisons_Evaluate(true, 4 * 60000, 50, 5, 10)))
        assert.are.equal("charges", (ns.Poisons_Evaluate(true, 20 * 60000, 6, 5, 10)))
        assert.are.equal("ok", (ns.Poisons_Evaluate(true, 20 * 60000, 6, 5, 0)))
        assert.are.equal("ok", (ns.Poisons_Evaluate(true, 20 * 60000, 0, 5, 10)))
    end)

    it("nothing below level 20", function()
        WowMock.level = 19
        assert.are.same({}, ns.Poisons_Check(opts))
    end)

    it("lists the hands without poison or about to lose it", function()
        WowMock.enchants = { oh = { 2 * 60000, 30 } }
        local issues = ns.Poisons_Check(opts)
        assert.are.equal(2, #issues)
        assert.are.equal(16, issues[1].slot)
        assert.are.equal("missing", issues[1].status)
        assert.are.equal("expiring", issues[2].status)
        assert.are.equal(120, issues[2].left)
    end)

    it("ignores the off hand when told, or when it holds no weapon", function()
        assert.are.equal(1, #ns.Poisons_Check({ minutes = 5, charges = 0, offHand = false }))
        WowMock.items[101] = { classID = 4 }
        assert.are.equal(1, #ns.Poisons_Check(opts))
        WowMock.inventory[16] = nil
        assert.are.equal(0, #ns.Poisons_Check(opts))
    end)

    it("only weapons that take poisons: not a fishing pole", function()
        WowMock.items[100] = { classID = 2, subclassID = 20 }
        WowMock.items[101] = { classID = 2, subclassID = 7 }
        local issues = ns.Poisons_Check(opts)
        assert.are.equal(1, #issues)
        assert.are.equal(17, issues[1].slot)
        for _, subclass in ipairs({ 0, 4, 7, 13, 15 }) do
            WowMock.items[100] = { classID = 2, subclassID = subclass }
            assert.is_true(ns.Poisons_HasWeapon(16))
        end
        WowMock.items[100] = { classID = 2, subclassID = 14 }
        assert.is_false(ns.Poisons_HasWeapon(16))
    end)

    it("all fine: no issues", function()
        WowMock.enchants = { mh = { 30 * 60000, 40 }, oh = { 30 * 60000, 40 } }
        assert.are.equal(0, #ns.Poisons_Check(opts))
    end)
end)

describe("Reagents", function()
    local ns
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon({ files = FILES })
    end)

    it("only the spells you know", function()
        WowMock.spells = { [1856] = true }
        WowMock.items = { [5140] = { count = 2 } }
        local low = ns.Reagents_Check(5)
        assert.are.equal(1, #low)
        assert.are.equal(5140, low[1].item)
        assert.are.equal(2, low[1].count)
        assert.are.equal("Flash Powder", low[1].name)
    end)

    it("enough in the bags: nothing", function()
        WowMock.spells = { [1857] = true, [2094] = true }
        WowMock.items = { [5140] = { count = 10 }, [5530] = { count = 5 } }
        assert.are.equal(0, #ns.Reagents_Check(5))
    end)

    it("without IsPlayerSpell, by level", function()
        local saved = IsPlayerSpell
        _G.IsPlayerSpell = nil
        WowMock.level = 30
        local low = ns.Reagents_Check(5)
        assert.are.equal(1, #low)
        assert.are.equal(5140, low[1].item)
        _G.IsPlayerSpell = saved
    end)
end)

describe("Timers", function()
    local ns
    local all = { timerSliceAndDice = true, timerRupture = true, timerGarrote = true, timerExposeArmor = true }
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon({ files = FILES })
    end)

    it("Slice and Dice on you and your Rupture on the target", function()
        WowMock.units.target = { name = "Boar", hostile = true }
        WowMock.auras.player = { { name = "Spell5171", duration = 21, expirationTime = 30 } }
        WowMock.auras.target = {
            { name = "Spell1943", duration = 16, expirationTime = 25, sourceUnit = "player", harmful = true },
            { name = "Spell8647", duration = 30, expirationTime = 40, sourceUnit = "party1", harmful = true },
        }
        local active = ns.Auras_Active(all, 20)
        assert.are.equal(2, #active)
        assert.are.equal("timerSliceAndDice", active[1].timer.key)
        assert.are.equal(10, active[1].left)
        assert.are.equal("timerRupture", active[2].timer.key)
        assert.are.equal(5, active[2].left)
    end)

    it("a timer turned off, or with no target, is not listed", function()
        WowMock.auras.player = { { name = "Spell5171", duration = 21, expirationTime = 30 } }
        WowMock.auras.target = { { name = "Spell1943", duration = 16, expirationTime = 25, sourceUnit = "player", harmful = true } }
        assert.are.equal(0, #ns.Auras_Active({ timerRupture = true }, 20))
    end)

    it("uses C_UnitAuras where it exists", function()
        _G.C_UnitAuras = { GetAuraDataByIndex = function(unit, i)
            if unit == "player" and i == 1 then return { name = "Spell5171", duration = 21, expirationTime = 30 } end
        end }
        local active = ns.Auras_Active(all, 25)
        _G.C_UnitAuras = nil
        assert.are.equal(1, #active)
        assert.are.equal(5, active[1].left)
    end)
end)

describe("Secret values", function()
    local ns
    local SECRET = setmetatable({}, { __lt = function() error("compare") end, __le = function() error("compare") end })
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon({ files = FILES })
        _G.issecretvalue = function(v) return v == SECRET end
    end)
    after_each(function() _G.issecretvalue = nil end)

    it("secret energy: a change is a tick unless you just cast something", function()
        ns.Energy_OnCast(10)
        ns.Energy_OnChange(SECRET, 100, 10.1)
        assert.is_nil(ns.Energy_TickProgress(10.1))
        ns.Energy_OnChange(SECRET, 100, 11)
        assert.are.equal(0, ns.Energy_TickProgress(11))
        assert.are.equal(0.5, ns.Energy_TickProgress(12))
    end)

    it("secret combo points come through untouched", function()
        WowMock.combo = SECRET
        assert.are.equal(SECRET, (ns.Combo_Get()))
    end)

    it("secret poison info is not reported", function()
        assert.are.equal("ok", (ns.Poisons_Evaluate(SECRET, SECRET, SECRET, 5, 10)))
    end)

    it("secret auras are skipped", function()
        WowMock.auras.player = { { name = SECRET, duration = 21, expirationTime = 30 } }
        assert.are.equal(0, #ns.Auras_Active({ timerSliceAndDice = true }, 20))
    end)
end)

describe("Energy filling up", function()
    local ns
    local SECRET = setmetatable({}, { __lt = function() error("compare") end, __le = function() error("compare") end })
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon({ files = FILES })
    end)
    after_each(function() _G.issecretvalue = nil end)

    it("readable energy: below the top", function()
        assert.is_true(ns.Energy_Recovering(60, 100, 5))
        assert.is_false(ns.Energy_Recovering(100, 100, 5))
    end)

    it("secret energy: a change in the last 2.5 seconds", function()
        _G.issecretvalue = function(v) return v == SECRET end
        assert.is_false(ns.Energy_Recovering(SECRET, 100, 5))
        ns.Energy_OnChange(SECRET, 100, 10)
        assert.is_true(ns.Energy_Recovering(SECRET, 100, 12))
        assert.is_false(ns.Energy_Recovering(SECRET, 100, 13))
    end)
end)

describe("Poison types", function()
    local ns
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon({ files = { "Modules/Core/Secret.lua", "Modules/Rogue/Poisons.lua", "Modules/Rogue/Auras.lua",
            "Modules/Rogue/PoisonTypes.lua" } })
        ns.char = { poisonMainType = "auto", poisonOffType = "auto" }
    end)

    it("the highest rank in the bags is the one to apply", function()
        WowMock.items = { [6947] = { count = 3 }, [6950] = { count = 2 } }
        local s = ns.PoisonType_Status("instant")
        assert.are.equal(6950, s.item)
        assert.are.equal(2, s.stock)
        assert.is_false(s.known)
    end)

    it("learned: how many of the highest learned rank the reagents make", function()
        WowMock.spells = { [8681] = true, [8687] = true } -- Instant I and II
        WowMock.items = { [2928] = { count = 7 }, [3372] = { count = 5 } } -- Dust of Decay, Leaded Vial
        local s = ns.PoisonType_Status("instant")
        assert.is_true(s.known)
        assert.are.equal(2, s.craftable) -- rank II: 3 dust each
        assert.is_nil(s.item)
    end)

    it("each hand its own poison; automatic: Instant right, Deadly left when you have it", function()
        assert.are.equal("instant", ns.Poisons_ChoiceFor(16))
        assert.are.equal("instant", ns.Poisons_ChoiceFor(17))
        WowMock.spells = { [2835] = true }
        assert.are.equal("deadly", ns.Poisons_ChoiceFor(17))
        ns.char.poisonMainType, ns.char.poisonOffType = "wound", "crippling"
        assert.are.equal("wound", ns.Poisons_ChoiceFor(16))
        assert.are.equal("crippling", ns.Poisons_ChoiceFor(17))
        ns.char.poisonOffType = "none"
        assert.are.equal("none", ns.Poisons_ChoiceFor(17))
    end)
end)

describe("Hidden auras", function()
    local ns
    local all = { timerSliceAndDice = true }
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon({ files = FILES })
    end)
    after_each(function()
        _G.C_UnitAuras = nil
        _G.C_Secrets = nil
    end)

    it("a read that errors (secret auras in combat) is caught, and not retried for a second", function()
        local calls = 0
        _G.C_UnitAuras = { GetAuraDataByIndex = function()
            calls = calls + 1
            error("GetAuraDataByIndex(): Auras cannot be accessed when secret")
        end }
        assert.are.same({}, ns.Auras_Active(all, 10))
        assert.are.same({}, ns.Auras_Active(all, 10.5))
        assert.are.equal(1, calls)
        ns.Auras_Active(all, 11.2)
        assert.are.equal(2, calls)
    end)

    it("when the game says auras are secret, they aren't read at all", function()
        local calls = 0
        _G.C_Secrets = { ShouldAurasBeSecret = function() return true end }
        _G.C_UnitAuras = { GetAuraDataByIndex = function() calls = calls + 1 end }
        assert.are.same({}, ns.Auras_Active(all, 10))
        assert.are.equal(0, calls)
    end)
end)
