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

    local function fills()
        local list = {}
        for _, f in ipairs(WowMock.frames) do
            if f._kind == "Texture" and f._parent == ns.Hud_Frame() and f._set.SetColorTexture and f._points
                and #f._points == 2 and f ~= ns.Hud_Frame().mover then
                list[#list + 1] = f
            end
        end
        return list
    end

    it("five points side by side, sized from the settings", function()
        ns.char.comboWidth, ns.char.comboSpacing = 20, 5
        ns.ApplySettings()
        local hud = ns.Hud_Frame()
        assert.are.equal(5 * 20 + 4 * 5, hud:GetWidth())
    end)

    it("points you have take the point color, the rest the empty one; all of them the full color", function()
        WowMock.combo = 2
        ns.Hud_Update()
        local c = ns.char
        local colored = {}
        for _, f in ipairs(fills()) do colored[#colored + 1] = f._set.SetColorTexture end
        assert.are.equal(c.comboColor[1], colored[1][1])
        assert.are.equal(c.comboColor[1], colored[2][1])
        assert.are.equal(c.comboEmptyColor[1], colored[3][1])
        WowMock.combo = 5
        ns.Hud_Update()
        assert.are.equal(c.comboFullColor[2], fills()[1]._set.SetColorTexture[2])
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

    it("a weapon without poison: on screen, in the chat and a sound, once", function()
        ns.Alerts_Update()
        assert.is_true(ns.Alerts_Frame():IsShown())
        assert.is_not_nil(WowMock.FindByText("Main hand: no poison"))
        local printed, sounds = #WowMock.printed, #WowMock.sounds
        ns.Alerts_Update()
        assert.are.equal(printed, #WowMock.printed)
        assert.are.equal(sounds, #WowMock.sounds)
        assert.is_true(sounds >= 1)
    end)

    it("poisoned: nothing to show", function()
        WowMock.enchants = { mh = { 30 * 60000, 0 } }
        ns.Alerts_Update()
        assert.is_false(ns.Alerts_Frame():IsShown())
    end)

    it("about to end: says how long is left", function()
        WowMock.enchants = { mh = { 125000, 0 } }
        ns.Alerts_Update()
        assert.is_not_nil(WowMock.FindByText("Main hand: poison ends in 2:05"))
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
        assert.is_not_nil(WowMock.FindByText("Blinding Powder: 1 left"))
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
