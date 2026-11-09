local _, ns = ...
local L = ns.L

-- The reminder: a movable row of big icons, one per thing that needs attention, readable at a glance -- the
-- weapon without poison with a red X over it, the weapon whose poison is ending with the time left (orange),
-- a reagent running low with how many are left (yellow). Checked every second. When something new shows up:
-- a sound (out of combat) and a chat line with the details, once; the icon stays until it is fixed.
local MAX_ICONS = 4
local CHECK_EVERY = 1
local SOUND_RAID_WARNING = 8959
local RED_X = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"
local COLORS = {
    missing = { 1, 0.1, 0.1 },
    expiring = { 1, 0.55, 0.05 },
    charges = { 1, 0.55, 0.05 },
    reagent = { 1, 0.82, 0 },
    sample = { 0.5, 0.5, 0.5 },
}
local frame, icons = nil, {}
local known = {}  -- issue keys already announced

local function inCombat() return UnitAffectingCombat("player") and true or false end

local function clock(seconds)
    seconds = math.max(0, math.floor(seconds))
    if seconds >= 60 then return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60) end
    return tostring(seconds)
end

local function handName(slot)
    return slot == ns.SLOT_MAIN_HAND and L["Main hand"] or L["Off hand"]
end

-- What needs attention now: { { key =, status =, icon =, badge = (text over the icon), text = (chat line) } }.
function ns.Alerts_Collect()
    local c = ns.char
    local list = {}
    if c.poisonWarn and (c.poisonInCombat or not inCombat()) then
        for _, issue in ipairs(ns.Poisons_Check({ minutes = c.poisonMinutes, charges = c.poisonCharges, offHand = c.poisonOffHand })) do
            local hand = handName(issue.slot)
            local entry = { key = issue.slot .. ":" .. issue.status, status = issue.status,
                icon = GetInventoryItemTexture("player", issue.slot) }
            if issue.status == "missing" then
                entry.text = L["%s: no poison"]:format(hand)
            elseif issue.status == "expiring" then
                entry.badge = clock(issue.left)
                entry.text = L["%s: poison ends in %s"]:format(hand, clock(issue.left))
            else
                entry.badge = tostring(issue.charges)
                entry.text = L["%s: %d poison charges left"]:format(hand, issue.charges)
            end
            list[#list + 1] = entry
        end
    end
    if c.reagentWarn and not inCombat() then
        for _, low in ipairs(ns.Reagents_Check(c.reagentMin)) do
            local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(low.item))
                or (GetItemIcon and GetItemIcon(low.item))
            list[#list + 1] = { key = "item:" .. low.item, status = "reagent", icon = icon, badge = tostring(low.count),
                text = L["%s: %d left"]:format(low.name, low.count) }
        end
    end
    return list
end

local function savePosition()
    local point, _, relPoint, x, y = frame:GetPoint(1)
    ns.char.alertPos = { point, relPoint, x, y }
end

-- One icon: a colored border, the item's picture, a red X (missing) and a big number (time, charges, count).
local function newIcon()
    local button = CreateFrame("Frame", nil, frame)
    button.border = button:CreateTexture(nil, "BACKGROUND")
    button.border:SetAllPoints()
    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetPoint("TOPLEFT", 3, -3)
    button.texture:SetPoint("BOTTOMRIGHT", -3, 3)
    button.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- trims the icon's own frame
    button.cross = button:CreateTexture(nil, "OVERLAY")
    button.cross:SetPoint("CENTER")
    button.cross:SetTexture(RED_X)
    button.badge = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
    button.badge:SetPoint("BOTTOM", 0, 4)
    button.badge:SetShadowOffset(2, -2)
    return button
end

local function create()
    frame = CreateFrame("Frame", "ApicaraoAlert", UIParent)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) if not ns.char.locked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePosition()
    end)
    frame:SetScript("OnMouseUp", function(_, button) if button == "RightButton" then ns.Prefs_Toggle() end end)
    frame.mover = frame:CreateTexture(nil, "BACKGROUND")
    frame.mover:SetPoint("TOPLEFT", -4, 4)
    frame.mover:SetPoint("BOTTOMRIGHT", 4, -4)
    frame.mover:SetColorTexture(0, 0.5, 1, 0.25)
    frame.moverLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.moverLabel:SetPoint("BOTTOM", frame, "TOP", 0, 6)
    frame.moverLabel:SetText(L["Apicarao!! reminders -- drag to move"])
    for i = 1, MAX_ICONS do icons[i] = newIcon() end
end

local function announce(list)
    local now, fresh = {}, {}
    for _, entry in ipairs(list) do
        now[entry.key] = true
        if not known[entry.key] then fresh[#fresh + 1] = entry end
    end
    known = now
    if #fresh == 0 then return end
    for _, entry in ipairs(fresh) do ns.Print(entry.text) end
    if ns.char.poisonSound and not inCombat() then PlaySound(SOUND_RAID_WARNING, "Master") end
end

local function layout(count)
    local size, gap = ns.char.alertIconSize, math.floor(ns.char.alertIconSize / 6)
    for i, icon in ipairs(icons) do
        icon:SetSize(size, size)
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", frame, "TOPLEFT", (i - 1) * (size + gap), 0)
        icon.cross:SetSize(size * 0.8, size * 0.8)
    end
    frame:SetSize(math.max(1, count) * (size + gap) - gap, size)
end

function ns.Alerts_Update()
    if not frame then return end
    local list = ns.Alerts_Collect()
    announce(list)
    local setup = not ns.char.locked or ns.Prefs_IsShown()
    if #list == 0 and setup then
        -- something to drag and to see the size with
        list = { { status = "missing", icon = "Interface\\Icons\\INV_Sword_04" },
            { status = "expiring", icon = "Interface\\Icons\\INV_Sword_04", badge = "4:59" } }
    end
    for i, icon in ipairs(icons) do
        local entry = list[i]
        icon:SetShown(entry ~= nil)
        if entry then
            local color = COLORS[entry.status] or COLORS.sample
            icon.border:SetColorTexture(color[1], color[2], color[3], 1)
            icon.texture:SetTexture(entry.icon or QUESTION)
            icon.cross:SetShown(entry.status == "missing")
            icon.badge:SetText(entry.badge or "")
            icon.badge:SetTextColor(color[1], color[2], color[3])
        end
    end
    layout(math.min(#list, MAX_ICONS))
    frame:SetShown(#list > 0)
end

-- The icons shown now (for the tests): { { status =, badge =, cross = } }.
function ns.Alerts_Shown()
    local shown = {}
    if not (frame and frame:IsShown()) then return shown end
    for _, icon in ipairs(icons) do
        if icon:IsShown() then
            shown[#shown + 1] = { badge = icon.badge:GetText(), cross = icon.cross:IsShown() }
        end
    end
    return shown
end

function ns.Alerts_Apply()
    if not frame then return end
    local c = ns.char
    frame:SetScale(c.scale)
    frame:ClearAllPoints()
    local pos = c.alertPos or { "CENTER", "CENTER", 0, 180 }
    frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    frame:EnableMouse(not c.locked)
    frame.mover:SetShown(not c.locked)
    frame.moverLabel:SetShown(not c.locked)
    ns.Alerts_Update()
end

function ns.Alerts_Init()
    if not frame then create() end
    if C_Timer and C_Timer.NewTicker then C_Timer.NewTicker(CHECK_EVERY, ns.Alerts_Update) end
    ns.Alerts_Apply()
end

function ns.Alerts_ResetPosition()
    ns.char.alertPos = nil
    ns.Alerts_Apply()
end

function ns.Alerts_Frame() return frame end
