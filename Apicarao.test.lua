dofile("setupTests.lua")

describe("Apicarao", function()
    local ns
    before_each(function()
        WowMock.Reset()
        ns = LoadAddon()
    end)

    it("a rogue gets the bars and the reminder", function()
        StartAddon(ns)
        assert.is_true(ns.active)
        assert.is_not_nil(ns.Hud_Frame())
        assert.is_not_nil(ns.Alerts_Frame())
    end)

    it("any other class: nothing is created, the slash command says why", function()
        WowMock.class = { "Mage", "MAGE", 8 }
        StartAddon(ns)
        assert.is_nil(ns.active)
        assert.is_nil(ns.Hud_Frame())
        SlashCmdList.APICARAO("")
        assert.matches("for rogues", WowMock.printed[#WowMock.printed])
    end)

    it("lock / unlock", function()
        StartAddon(ns)
        SlashCmdList.APICARAO("lock")
        assert.is_true(ns.char.locked)
        assert.is_false(ns.Hud_Frame():IsMouseEnabled())
        SlashCmdList.APICARAO("unlock")
        assert.is_false(ns.char.locked)
        assert.is_true(ns.Hud_Frame():IsMouseEnabled())
    end)

    it("opens the preferences with no arguments", function()
        StartAddon(ns)
        SlashCmdList.APICARAO("")
        assert.is_true(ns.Prefs_IsShown())
        SlashCmdList.APICARAO("prefs")
        assert.is_false(ns.Prefs_IsShown())
    end)
end)

describe("Localization", function()
    it("every key used in the code has a Spanish translation", function()
        local ns = LoadAddon({ files = { "Localization/Locale.lua" } })
        local missing = {}
        for _, file in ipairs(TocFiles()) do
            local source = io.open(file):read("*a")
            for key in source:gmatch('L%["(.-)"%]') do
                if not ns.L_ES[key] then missing[#missing + 1] = key end
            end
        end
        assert.are.same({}, missing)
    end)
end)
