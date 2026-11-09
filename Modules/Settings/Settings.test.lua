dofile("setupTests.lua")

describe("Settings", function()
    local ns, applied

    local function login(charDB, accountDB)
        _G.EmboscaoDB, _G.EmboscaoCharDB = accountDB, charDB
        ns = LoadAddon({ files = { "Modules/Settings/Settings.lua" } })
        applied = 0
        ns.ApplySettings = function() applied = applied + 1 end
        ns.InitSettings()
        return ns
    end

    before_each(function() WowMock.Reset() end)

    it("creates the saved variables on the first login, per character", function()
        login(nil, nil)
        assert.is_not_nil(EmboscaoDB)
        assert.is_not_nil(EmboscaoCharDB)
        assert.is_true(ns.IsPerCharacter())
    end)

    it("a setting never touched reads as its default; false is kept", function()
        login({}, {})
        assert.are.equal(5, ns.char.poisonMinutes)
        assert.is_true(ns.char.showEnergy)
        ns.char.showEnergy = false
        assert.is_false(ns.char.showEnergy)
    end)

    it("per character, changes don't touch the shared ones", function()
        local char, account = { poisonMinutes = 8 }, {}
        login(char, account)
        ns.char.poisonMinutes = 3
        assert.are.equal(3, char.poisonMinutes)
        assert.are.equal(8, account.shared.poisonMinutes)
    end)

    it("switching to shared reads the shared ones and applies them", function()
        local char, account = { poisonMinutes = 3 }, {}
        login(char, account)
        account.shared.poisonMinutes = 9
        ns.SetPerCharacter(false)
        assert.are.equal(9, ns.char.poisonMinutes)
        assert.are.equal(3, char.poisonMinutes)
        assert.are.equal(1, applied)
    end)

    it("switching back to per character copies the shared ones", function()
        local char, account = { perCharacter = false }, { shared = { comboWidth = 50 } }
        login(char, account)
        ns.SetPerCharacter(true)
        assert.are.equal(50, char.comboWidth)
        assert.is_true(ns.IsPerCharacter())
    end)

    it("reset goes back to the defaults and keeps the per character choice", function()
        login({ comboWidth = 50, hudPos = { "CENTER", 1, 2 } }, {})
        ns.ResetSettings()
        assert.are.equal(32, ns.char.comboWidth)
        assert.is_nil(ns.char.hudPos)
        assert.is_true(ns.IsPerCharacter())
        assert.are.equal(1, applied)
    end)
end)
