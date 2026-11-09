dofile("setupTests.lua")

local function start()
    local ns = LoadAddon()
    StartAddon(ns)
    return ns
end

describe("Bars", function()
    local ns
    before_each(function()
        WowMock.Reset()
        WowMock.inCombat = true
        ns = start()
        ns.char.locked = true
        ns.ApplySettings()
    end)

    -- a secret value as the game hands it: something only its widgets can use
    local SECRET = setmetatable({}, { __lt = function() error("attempt to compare a secret number value") end,
        __le = function() error("attempt to compare a secret number value") end })
    local function withSecrets(f)
        _G.issecretvalue = function(v) return v == SECRET end
        local ok, err = pcall(f)
        _G.issecretvalue = nil
        assert(ok, err)
    end

    it("five points side by side, sized from the settings; each one fills from i-1 to i", function()
        ns.char.comboWidth, ns.char.comboSpacing = 20, 5
        ns.ApplySettings()
        assert.are.equal(5 * 20 + 4 * 5, ns.Hud_Frame():GetWidth())
        assert.are.same({ 2, 3 }, ns.Hud_Points()[3]._set.SetMinMaxValues)
    end)

    it("every point gets the count; the full color when all of them are up", function()
        local c = ns.char
        WowMock.combo = 2
        ns.Hud_Update()
        for _, p in ipairs(ns.Hud_Points()) do assert.are.equal(2, p._set.SetValue[1]) end
        assert.are.equal(c.comboColor[2], ns.Hud_Points()[1]._set.SetStatusBarColor[2])
        WowMock.combo = 5
        ns.Hud_Update()
        assert.are.equal(c.comboFullColor[2], ns.Hud_Points()[1]._set.SetStatusBarColor[2])
    end)

    it("secret energy and combo points: handed to the widgets, never compared", function()
        withSecrets(function()
            WowMock.inCombat = false
            WowMock.power[3] = { SECRET, 100 }
            WowMock.combo = SECRET
            ns.Hud_Update()
            assert.are.equal(SECRET, ns.Hud_Energy()._set.SetValue[1])
            assert.are.equal(SECRET, ns.Hud_Energy().right:GetText())
            assert.are.equal(SECRET, ns.Hud_Points()[1]._set.SetValue[1])
            assert.are.equal(ns.char.comboColor[2], ns.Hud_Points()[1]._set.SetStatusBarColor[2])
            assert.are.equal(1, ns.Hud_Frame():GetAlpha())
            FireEvent("UNIT_POWER_FREQUENT", "player", "ENERGY")
        end)
    end)

    it("hidden when idle, shown with points, in combat or while unlocked", function()
        WowMock.inCombat = false
        ns.Hud_Update()
        assert.are.equal(0, ns.Hud_Frame():GetAlpha())
        WowMock.combo = 1
        ns.Hud_Update()
        assert.are.equal(1, ns.Hud_Frame():GetAlpha())
        WowMock.combo = 0
        ns.char.locked = false
        ns.Hud_Update()
        assert.are.equal(1, ns.Hud_Frame():GetAlpha())
    end)

    it("dragging stores the position", function()
        local hud = ns.Hud_Frame()
        hud:ClearAllPoints()
        hud:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -20)
        WowMock.Fire(hud, "OnDragStop")
        assert.are.same({ "TOPLEFT", "TOPLEFT", 10, -20 }, ns.char.hudPos)
        ns.Hud_ResetPosition()
        assert.is_nil(ns.char.hudPos)
    end)
end)

describe("Reminder", function()
    local ns
    before_each(function()
        WowMock.Reset()
        WowMock.inventory = { [16] = 100 }
        WowMock.items = { [100] = { classID = 2 } }
        ns = start()
        ns.char.locked = true
    end)

    local function printed(text)
        for _, line in ipairs(WowMock.printed) do
            if line:find(text, 1, true) then return true end
        end
        return false
    end

    it("a weapon without poison: its icon with a red X, a chat line and a sound, once", function()
        ns.Alerts_Update()
        assert.is_true(ns.Alerts_Frame():IsShown())
        assert.are.same({ { badge = "", cross = true } }, ns.Alerts_Shown())
        assert.is_true(printed("Main hand: no poison"))
        local lines, sounds = #WowMock.printed, #WowMock.sounds
        ns.Alerts_Update()
        assert.are.equal(lines, #WowMock.printed)
        assert.are.equal(sounds, #WowMock.sounds)
        assert.is_true(sounds >= 1)
    end)

    it("poisoned: nothing to show", function()
        WowMock.enchants = { mh = { 30 * 60000, 0 } }
        ns.Alerts_Update()
        assert.is_false(ns.Alerts_Frame():IsShown())
    end)

    it("about to end: the time left over the icon, no X", function()
        WowMock.enchants = { mh = { 125000, 0 } }
        ns.Alerts_Update()
        assert.are.same({ { badge = "2:05", cross = false } }, ns.Alerts_Shown())
        assert.is_true(printed("Main hand: poison ends in 2:05"))
        WowMock.enchants = { mh = { 42000, 0 } }
        ns.Alerts_Update()
        assert.are.equal("42", ns.Alerts_Shown()[1].badge)
    end)

    it("the icons take the size from the settings, side by side", function()
        WowMock.inventory[17] = 100
        ns.char.alertIconSize = 60
        ns.Alerts_Update()
        assert.are.equal(2, #ns.Alerts_Shown())
        assert.are.equal(60 * 2 + 10, ns.Alerts_Frame():GetWidth())
        assert.are.equal(60, ns.Alerts_Frame():GetHeight())
    end)

    it("unlocked with nothing to warn about: sample icons to place it", function()
        WowMock.enchants = { mh = { 30 * 60000, 0 } }
        ns.char.locked = false
        ns.Alerts_Update()
        assert.are.equal(2, #ns.Alerts_Shown())
    end)

    it("in combat, quiet unless told otherwise", function()
        WowMock.inCombat = true
        ns.Alerts_Update()
        assert.is_false(ns.Alerts_Frame():IsShown())
        ns.char.poisonInCombat = true
        local sounds = #WowMock.sounds
        ns.Alerts_Update()
        assert.is_true(ns.Alerts_Frame():IsShown())
        assert.are.equal(sounds, #WowMock.sounds) -- no sound in combat
    end)

    it("low reagents of a known spell", function()
        WowMock.enchants = { mh = { 30 * 60000, 0 } }
        WowMock.spells = { [2094] = true }
        WowMock.items[5530] = { count = 1 }
        ns.Alerts_Update()
        assert.are.same({ { badge = "1", cross = false } }, ns.Alerts_Shown())
        assert.is_true(printed("Blinding Powder: 1 left"))
    end)
end)

describe("Preferences", function()
    local ns
    before_each(function()
        WowMock.Reset()
        ns = start()
    end)

    it("a checkbox changes its setting", function()
        ns.Prefs_Toggle()
        local label = WowMock.FindByText("Show the energy bar")
        local check = WowMock.Find(function(f) return f._kind == "CheckButton" and label._set.SetPoint[2] == f end)
        check:SetChecked(false)
        check:Click()
        assert.is_false(ns.char.showEnergy)
    end)

    it("picking a color stores a new table", function()
        local shown
        _G.ColorPickerFrame = WowMock.NewFrame("Frame", "ColorPickerFrame")
        _G.ColorPickerFrame.SetupColorPickerAndShow = function(_, info) shown = info end
        _G.ColorPickerFrame.GetColorRGB = function() return 0.1, 0.2, 0.3 end
        _G.ColorPickerFrame.GetColorAlpha = function() return 0.5 end
        local got
        ns.PickColor({ 1, 1, 1, 1 }, function(c) got = c end)
        shown.swatchFunc()
        assert.are.same({ 0.1, 0.2, 0.3, 0.5 }, got)
        shown.cancelFunc()
        assert.are.same({ 1, 1, 1, 1 }, got)
        _G.ColorPickerFrame = nil
    end)
end)

describe("Padlock", function()
    it("shows while unlocked and locks with a click", function()
        WowMock.Reset()
        local ns = start()
        local lock = ns.Hud_Frame().lock
        assert.is_true(lock:IsShown())
        lock:Click()
        assert.is_true(ns.char.locked)
        assert.is_false(lock:IsShown())
        assert.is_false(ns.Hud_Frame():IsMouseEnabled())
        SlashCmdList.APICARAO("unlock")
        assert.is_true(lock:IsShown())
    end)
end)

describe("Combat", function()
    it("everything lets the clicks through in combat, even unlocked; back after it", function()
        WowMock.Reset()
        local ns = start()
        local hud, alert = ns.Hud_Frame(), ns.Alerts_Frame()
        assert.is_true(hud:IsMouseEnabled())
        FireEvent("PLAYER_REGEN_DISABLED")
        assert.is_false(hud:IsMouseEnabled())
        assert.is_false(hud.lock:IsMouseEnabled())
        assert.is_false(alert:IsMouseEnabled())
        ns.ApplySettings() -- a setting changed mid-fight doesn't give the mouse back
        assert.is_false(hud:IsMouseEnabled())
        FireEvent("PLAYER_REGEN_ENABLED")
        assert.is_true(hud:IsMouseEnabled())
        assert.is_true(hud.lock:IsMouseEnabled())
        assert.is_true(alert:IsMouseEnabled())
    end)
end)

describe("Showing out of combat", function()
    local ns
    before_each(function()
        WowMock.Reset()
        ns = start()
        ns.char.locked = true
        ns.ApplySettings()
    end)

    it("an enemy targeted shows the bars; a dead one doesn't", function()
        ns.Hud_Update()
        assert.are.equal(0, ns.Hud_Frame():GetAlpha())
        WowMock.units.target = { name = "Boar", hostile = true }
        ns.Hud_Update()
        assert.are.equal(1, ns.Hud_Frame():GetAlpha())
        WowMock.units.target.dead = true
        ns.Hud_Update()
        assert.are.equal(0, ns.Hud_Frame():GetAlpha())
    end)

    it("secret energy filling up keeps them shown, then they hide", function()
        local SECRET = {}
        _G.issecretvalue = function(v) return v == SECRET end
        WowMock.power[3] = { SECRET, 100 }
        WowMock.time = 50
        FireEvent("UNIT_POWER_FREQUENT", "player", "ENERGY")
        ns.Hud_Update()
        local shown = ns.Hud_Frame():GetAlpha()
        WowMock.time = 60
        ns.Hud_Update()
        local later = ns.Hud_Frame():GetAlpha()
        _G.issecretvalue = nil
        assert.are.equal(1, shown)
        assert.are.equal(0, later)
    end)
end)
