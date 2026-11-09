local ADDON, ns = ...
local L = ns.L

-- Minimap button (as in the sibling addons): left-click shows or hides the bars and the reminder, right-click opens
-- a menu (preferences, lock, poison reminder, reset, about, hide the button), drag moves it around the minimap.
local ICON = "Interface\\AddOns\\" .. ADDON .. "\\Icons\\Emboscao.png"
local button

local function updatePosition()
    local angle = math.rad(ns.char.minimap.angle)
    local radius = Minimap:GetWidth() / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function onDragUpdate()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    ns.char.minimap.angle = math.deg((math.atan2 or math.atan)(cy / scale - my, cx / scale - mx))
    updatePosition()
end

-- The right-click menu: { name =, run = }.
function ns.Minimap_MenuOptions()
    local c = ns.char
    return {
        { name = L["Preferences"], run = function() ns.Prefs_Toggle() end },
        { name = c.enabled and L["Hide the bars and the reminder"] or L["Show the bars and the reminder"],
            run = function() ns.SetEnabled(not ns.char.enabled) end },
        { name = c.locked and L["Unlock position"] or L["Lock position"], run = function() ns.SetLocked(not ns.char.locked) end },
        { name = c.poisonWarn and L["Turn off the poison reminder"] or L["Turn on the poison reminder"],
            run = function()
                ns.char.poisonWarn = not ns.char.poisonWarn
                ns.ApplySettings()
                ns.Prefs_Refresh()
            end },
        { name = L["Reset positions"], run = function()
            ns.Hud_ResetPosition()
            ns.Alerts_ResetPosition()
        end },
        { name = L["About Emboscao!!"], run = function() ns.About_Show() end },
        { name = L["Hide the minimap button"], color = { 0.7, 0.7, 0.7 }, run = function() ns.Minimap_Toggle() end },
    }
end

local function create()
    button = CreateFrame("Button", "EmboscaoMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture(136477) -- Interface\Minimap\UI-Minimap-ZoomButton-Highlight

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetPoint("TOPLEFT", 6, -5)
    background:SetTexture(136467) -- Interface\Minimap\UI-Minimap-Background

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(21, 21)
    icon:SetPoint("TOPLEFT", 5, -4)
    icon:SetTexture(ICON)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT")
    border:SetTexture(136430) -- Interface\Minimap\MiniMap-TrackingBorder

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", function(self, mouse)
        GameTooltip_Hide()
        if mouse == "RightButton" then
            ns.PopupMenu(self, ns.Minimap_MenuOptions(), function(opt) opt.run() end, 220, "right")
        else
            ns.SetEnabled(not ns.char.enabled)
        end
    end)
    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", onDragUpdate)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnlockHighlight()
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Emboscao!!")
        GameTooltip:AddLine(ns.char.enabled and L["Left-click: hide the bars"] or L["Left-click: show the bars"], 1, 1, 1)
        GameTooltip:AddLine(L["Right-click: menu"], 1, 1, 1)
        GameTooltip:AddLine(L["Drag: move"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
end

function ns.Minimap_Init()
    if not Minimap then return end
    -- a fresh table: the saved one is changed in place while dragging
    if not ns.char.minimap then ns.char.minimap = { angle = 200, hide = false } end
    if not button then create() end
    updatePosition()
    button:SetShown(not ns.char.minimap.hide)
end

function ns.Minimap_SetShown(show)
    if not button then return end
    ns.char.minimap.hide = not show
    button:SetShown(show)
end

function ns.Minimap_IsShown()
    return not (ns.char.minimap and ns.char.minimap.hide)
end

function ns.Minimap_Toggle()
    if not button then return end
    ns.Minimap_SetShown(ns.char.minimap.hide)
    ns.Print(ns.char.minimap.hide and L["Minimap button hidden. Show it again with /emboscao minimap."]
        or L["Minimap button shown."])
    ns.Prefs_Refresh()
end

function ns.Minimap_Button() return button end
