local ADDON, ns = ...
local L = ns.L

-- About window: what the addon does, its version, the commands and where to report a bug (the URL in a box that
-- can be selected and copied: the game can't open links).
local ICON = "Interface\\AddOns\\" .. ADDON .. "\\Icons\\Emboscao.png"
local URL = "https://github.com/LechuckThePirate/Emboscao"
local WIDTH, HEIGHT = 420, 340
local about

local function create()
    about = CreateFrame("Frame", "EmboscaoAboutFrame", UIParent, "BackdropTemplate")
    about:SetSize(WIDTH, HEIGHT)
    about:SetPoint("CENTER")
    -- above the preferences (DIALOG), with a solid background so they don't show through
    about:SetFrameStrata("FULLSCREEN_DIALOG")
    about:SetToplevel(true)
    about:SetClampedToScreen(true)
    about:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    about:SetBackdropColor(0.06, 0.05, 0.09, 1)
    about:SetMovable(true)
    about:EnableMouse(true)
    about:RegisterForDrag("LeftButton")
    about:SetScript("OnDragStart", about.StartMoving)
    about:SetScript("OnDragStop", about.StopMovingOrSizing)
    tinsert(UISpecialFrames, "EmboscaoAboutFrame")

    local close = CreateFrame("Button", nil, about, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local icon = about:CreateTexture(nil, "ARTWORK")
    icon:SetSize(72, 72)
    icon:SetPoint("TOPLEFT", 18, -18)
    icon:SetTexture(ICON)

    local title = about:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 14, -6)
    title:SetText("Emboscao!!")

    local version = about:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    about.version = version

    local author = about:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    author:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -4)
    author:SetText(L["by LechuckThePirate"])

    local body = about:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    body:SetPoint("TOPLEFT", 20, -108)
    body:SetWidth(WIDTH - 40)
    body:SetJustifyH("LEFT")
    body:SetSpacing(3)
    body:SetText(L["Rogue toolset: combo point bars, energy and its tick, Slice and Dice and bleed timers, poison and reagent reminders."]
        .. "\n\n" .. L["Commands: /emboscao (preferences), /emboscao toggle, lock, unlock, reset, minimap, about, version."])

    local report = about:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    report:SetPoint("TOPLEFT", 20, -230)
    report:SetWidth(WIDTH - 40)
    report:SetJustifyH("LEFT")
    report:SetText(L["Found a bug or have an idea? Please report it on GitHub (click to select, then Ctrl+C):"])

    local box = CreateFrame("EditBox", nil, about, "InputBoxTemplate")
    box:SetSize(WIDTH - 50, 22)
    box:SetPoint("TOPLEFT", 26, -264)
    box:SetAutoFocus(false)
    box:SetText(URL)
    -- read only: whatever is typed, the URL comes back
    box:SetScript("OnTextChanged", function(self) if self:GetText() ~= URL then self:SetText(URL) end end)
    box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    box:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    local ok = CreateFrame("Button", nil, about, "UIPanelButtonTemplate")
    ok:SetSize(100, 24)
    ok:SetPoint("BOTTOM", 0, 16)
    ok:SetText(CLOSE or "Close")
    ok:SetScript("OnClick", function() about:Hide() end)
    about:Hide()
end

function ns.About_Show()
    if not about then create() end
    about.version:SetText(L["Version %s"]:format(ns.Version()))
    about:Show()
    about:Raise()
end

function ns.About_Frame() return about end

function ns.About_IsShown()
    return about ~= nil and about:IsShown()
end
