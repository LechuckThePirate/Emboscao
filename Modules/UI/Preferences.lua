local _, ns = ...
local L = ns.L

-- Preferences window (/apicarao, or right-click on the bars or the reminder while they are unlocked). Two
-- columns: the bars on the left, timers / poisons / reagents on the right. While it is open the bars and the
-- reminder stay visible (and the combo points count up) so every change can be seen.
local WIDTH, HEIGHT = 680, 760
local COL_X = { 16, 352 }
local SLIDER_W = 290
local prefs, refreshPrefs

local function makeHeader(parent, x, y, text)
    local header = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    header:SetPoint("TOPLEFT", x + 4, y)
    header:SetText(text)
    return header
end

local function makeSlider(parent, x, y, min, max, step, getValue, setValue, labelFor)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", x + 8, y)

    local slider = CreateFrame("Slider", nil, parent)
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(SLIDER_W, 16)
    slider:SetPoint("TOPLEFT", x + 12, y - 22)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local bar = slider:CreateTexture(nil, "BACKGROUND")
    bar:SetPoint("LEFT", 0, 0)
    bar:SetPoint("RIGHT", 0, 0)
    bar:SetHeight(4)
    bar:SetColorTexture(1, 1, 1, 0.25)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:GetThumbTexture():SetSize(20, 20)

    local refreshing = false
    slider:SetScript("OnValueChanged", function(_, value)
        value = tonumber(("%.2f"):format(math.floor(value / step + 0.5) * step)) -- on the step grid
        label:SetText(labelFor(value))
        if not refreshing then setValue(value) end
    end)
    function slider.Refresh()
        refreshing = true
        local value = getValue()
        slider:SetValue(value)
        label:SetText(labelFor(value))
        refreshing = false
    end
    return slider
end

local function makeCheck(parent, x, y, text, getValue, setValue)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", x + 4, y)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    label:SetWidth(SLIDER_W - 20)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    check:SetScript("OnClick", function(self) setValue(self:GetChecked() and true or false) end)
    function check.Refresh() check:SetChecked(getValue() and true or false) end
    return check
end

local function makeButton(parent, x, y, width, text, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 24)
    button:SetPoint("TOPLEFT", x + 8, y)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

-- The game's color picker; its API changed in 10.2.5 (SetupColorPickerAndShow, alpha instead of opacity).
function ns.PickColor(color, onChange)
    local r, g, b, a = color[1], color[2], color[3], color[4] or 1
    local picker = ColorPickerFrame
    if not picker then return end
    local function current()
        local nr, ng, nb = picker:GetColorRGB()
        local na = a
        if picker.GetColorAlpha then
            na = picker:GetColorAlpha() or a
        elseif OpacitySliderFrame then
            na = 1 - OpacitySliderFrame:GetValue()
        end
        return { nr, ng, nb, na }
    end
    local info = {
        r = r, g = g, b = b, opacity = a, hasOpacity = true,
        swatchFunc = function() onChange(current()) end,
        opacityFunc = function() onChange(current()) end,
        cancelFunc = function() onChange({ r, g, b, a }) end,
    }
    if picker.SetupColorPickerAndShow then
        picker:SetupColorPickerAndShow(info)
    else
        picker.func, picker.opacityFunc, picker.cancelFunc = info.swatchFunc, info.opacityFunc, info.cancelFunc
        picker.hasOpacity, picker.opacity = true, 1 - a
        picker:SetColorRGB(r, g, b)
        picker:Hide()
        picker:Show()
    end
end

local function makeColor(parent, x, y, text, key)
    local swatch = CreateFrame("Button", nil, parent)
    swatch:SetSize(20, 20)
    swatch:SetPoint("TOPLEFT", x + 6, y)
    local border = swatch:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    border:SetColorTexture(1, 1, 1, 0.8)
    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 2, -2)
    fill:SetPoint("BOTTOMRIGHT", -2, 2)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", swatch, "RIGHT", 6, 0)
    label:SetText(text)
    function swatch.Refresh()
        local c = ns.char[key]
        fill:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
    end
    swatch:SetScript("OnClick", function()
        ns.PickColor(ns.char[key], function(color)
            ns.char[key] = color
            swatch.Refresh()
            ns.ApplySettings()
        end)
    end)
    return swatch
end

local function create()
    prefs = CreateFrame("Frame", "ApicaraoPreferencesFrame", UIParent, "BackdropTemplate")
    prefs:SetSize(WIDTH, HEIGHT)
    prefs:SetPoint("CENTER")
    prefs:SetFrameStrata("DIALOG")
    prefs:SetClampedToScreen(true)
    prefs:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    prefs:SetBackdropColor(0, 0, 0, 0.9)
    prefs:SetMovable(true)
    prefs:EnableMouse(true)
    prefs:RegisterForDrag("LeftButton")
    prefs:SetScript("OnDragStart", prefs.StartMoving)
    prefs:SetScript("OnDragStop", prefs.StopMovingOrSizing)
    tinsert(UISpecialFrames, "ApicaraoPreferencesFrame")

    local close = CreateFrame("Button", nil, prefs, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local title = prefs:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText(L["Apicarao!! Preferences"])

    local widgets = {}
    local note = prefs:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("BOTTOM", 0, 14)
    local function refreshAll()
        for _, widget in ipairs(widgets) do widget.Refresh() end
        note:SetText(ns.IsPerCharacter() and L["Settings are saved for this character only."]
            or L["Settings are shared by all your characters."])
    end
    refreshPrefs = refreshAll
    local function get(key) return function() return ns.char[key] end end
    local function set(key)
        return function(value)
            ns.char[key] = value
            ns.ApplySettings()
        end
    end
    local function add(widget) widgets[#widgets + 1] = widget end

    -- Each column is laid out top to bottom: these move its cursor.
    local x, y
    local function check(text, key) add(makeCheck(prefs, x, y, text, get(key), set(key))); y = y - 26 end
    local function slider(min, max, step, key, labelFor)
        add(makeSlider(prefs, x, y, min, max, step, get(key), set(key), labelFor)); y = y - 50
    end
    local function color(text, key) add(makeColor(prefs, x, y, text, key)); y = y - 26 end
    local function header(text) y = y - 6; makeHeader(prefs, x, y, text); y = y - 20 end
    local function px(fmt) return function(v) return fmt:format(v) end end

    -- left column: general, combo points, energy
    x, y = COL_X[1], -46
    add(makeCheck(prefs, x, y, L["Character specific preferences"],
        function() return ns.IsPerCharacter() end,
        function(value)
            ns.SetPerCharacter(value)
            refreshAll()
        end))
    y = y - 26
    check(L["Lock the bars and the reminder"], "locked")
    check(L["Hide the bars when idle (out of combat, nothing to show)"], "hideIdle")
    slider(0.5, 2, 0.05, "scale", function(v) return L["Scale: %d%%"]:format(math.floor(v * 100 + 0.5)) end)

    header(L["Combo points"])
    slider(10, 80, 1, "comboWidth", px(L["Width: %d"]))
    slider(4, 40, 1, "comboHeight", px(L["Height: %d"]))
    slider(0, 20, 1, "comboSpacing", px(L["Spacing: %d"]))
    color(L["Point color"], "comboColor")
    check(L["Another color when all the points are up"], "useFullColor")
    color(L["Color with all the points"], "comboFullColor")
    color(L["Empty point color"], "comboEmptyColor")

    header(L["Energy"])
    check(L["Show the energy bar"], "showEnergy")
    check(L["Show the next energy tick (spark)"], "energyTick")
    check(L["Show the energy value"], "energyText")
    slider(2, 30, 1, "energyHeight", px(L["Height: %d"]))
    color(L["Energy color"], "energyColor")

    -- right column: timers, poisons, reagents, buttons
    x, y = COL_X[2], -46
    header(L["Duration bars"])
    check(L["Show the duration bars"], "showTimers")
    for _, timer in ipairs(ns.TIMERS) do
        check(ns.SpellName(timer.spell) or timer.key, timer.key)
    end
    slider(4, 30, 1, "timerHeight", px(L["Height: %d"]))

    header(L["Poisons"])
    check(L["Remind me to apply poisons"], "poisonWarn")
    check(L["Off hand too"], "poisonOffHand")
    check(L["Also in combat"], "poisonInCombat")
    check(L["Play a sound"], "poisonSound")
    slider(1, 30, 1, "poisonMinutes", function(v) return L["Warn %d minutes before it ends"]:format(v) end)
    slider(0, 40, 1, "poisonCharges", function(v)
        if v == 0 then return L["Don't look at the charges"] end
        return L["Warn with fewer than %d charges"]:format(v)
    end)

    header(L["Reagents"])
    check(L["Warn when Flash Powder or Blinding Powder run low"], "reagentWarn")
    slider(1, 20, 1, "reagentMin", function(v) return L["Fewer than %d"]:format(v) end)
    slider(24, 128, 4, "alertIconSize", function(v) return L["Reminder icon size: %d"]:format(v) end)

    y = y - 10
    makeButton(prefs, x, y, 142, L["Reset positions"], function()
        ns.Hud_ResetPosition()
        ns.Alerts_ResetPosition()
    end)
    makeButton(prefs, x + 152, y, 142, L["Reset everything"], function()
        ns.ResetSettings()
        refreshAll()
    end)
    y = y - 30
    add(makeCheck(prefs, x, y, L["Show chat messages at startup"],
        function() return not ns.char.quiet end,
        function(value) ns.char.quiet = (not value) or nil end))

    prefs:SetScript("OnShow", function()
        refreshAll()
        ns.ApplySettings()
    end)
    prefs:SetScript("OnHide", function() ns.ApplySettings() end)
    prefs:Hide()
end

function ns.Prefs_Refresh()
    if prefs and prefs:IsShown() then refreshPrefs() end
end

function ns.Prefs_IsShown()
    return prefs ~= nil and prefs:IsShown()
end

function ns.Prefs_Toggle()
    if not prefs then create() end
    prefs:SetShown(not prefs:IsShown())
end
