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

-- The poison a hand gets on a click: { type =, name =, item =, stock =, craftable =, known = } or nil ("none").
local function poisonFor(slot)
    local choice = ns.Poisons_ChoiceFor(slot)
    if choice == "none" then return nil end
    return ns.PoisonType_Status(choice)
end

-- What needs attention now: { { key =, status =, icon =, weapon = (small weapon picture), badge = (text over the
-- icon), text = (chat line), slot =, poison = (what a click applies) } }. Each hand is its own entry with its own poison.
function ns.Alerts_Collect()
    local c = ns.char
    local list = {}
    if c.poisonWarn and (c.poisonInCombat or not inCombat()) then
        for _, issue in ipairs(ns.Poisons_Check({ minutes = c.poisonMinutes, charges = c.poisonCharges, offHand = c.poisonOffHand })) do
            local hand = handName(issue.slot)
            local weapon = GetInventoryItemTexture("player", issue.slot)
            local poison = poisonFor(issue.slot)
            -- the poison's picture when there is one to apply, with the weapon small in a corner
            local entry = { key = issue.slot .. ":" .. issue.status, status = issue.status, slot = issue.slot,
                poison = poison, icon = (poison and poison.item and poison.icon) or weapon,
                weapon = (poison and poison.item) and weapon or nil }
            if issue.status == "missing" then
                entry.text = L["%s: no poison"]:format(hand)
            elseif issue.status == "expiring" then
                entry.badge = clock(issue.left)
                entry.text = L["%s: poison ends in %s"]:format(hand, clock(issue.left))
            else
                entry.badge = tostring(issue.charges)
                entry.text = L["%s: %d poison charges left"]:format(hand, issue.charges)
            end
            -- nothing to apply: say so, and whether the reagents in the bags make some
            if poison and not poison.item then
                local more = L["no %s in your bags"]:format(poison.name)
                if poison.craftable > 0 then more = more .. " " .. L["(you can make %d)"]:format(poison.craftable) end
                entry.text = entry.text .. " -- " .. more
            end
            list[#list + 1] = entry
        end
    end
    -- the chosen poisons running low (each type once, even when both hands use it)
    if c.poisonWarn and c.reagentWarn and not inCombat() and (UnitLevel("player") or 0) >= ns.POISONS_LEVEL then
        local seen = {}
        for _, slot in ipairs({ ns.SLOT_MAIN_HAND, ns.SLOT_OFF_HAND }) do
            local poison = (slot == ns.SLOT_MAIN_HAND or c.poisonOffHand) and ns.Poisons_HasWeapon(slot) and poisonFor(slot)
            if poison and not seen[poison.key] and (poison.known or poison.stock > 0) and poison.stock < c.reagentMin then
                seen[poison.key] = true
                local text = L["%s: %d left"]:format(poison.name, poison.stock)
                if poison.craftable > 0 then text = text .. " " .. L["(you can make %d)"]:format(poison.craftable) end
                list[#list + 1] = { key = "poison:" .. poison.key, status = "reagent", icon = poison.icon,
                    badge = tostring(poison.stock), text = text }
            end
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
    -- which weapon it is, small in the top left corner, when the big picture is the poison
    button.weapon = button:CreateTexture(nil, "OVERLAY", nil, 2)
    button.weapon:SetPoint("TOPLEFT", -4, 4)
    button.weaponBorder = button:CreateTexture(nil, "OVERLAY", nil, 1)
    button.weaponBorder:SetPoint("TOPLEFT", button.weapon, "TOPLEFT", -2, 2)
    button.weaponBorder:SetPoint("BOTTOMRIGHT", button.weapon, "BOTTOMRIGHT", 2, -2)
    button.weaponBorder:SetColorTexture(0, 0, 0, 1)
    -- a font of our own (not a template every client may not have), sized with the icon in layout()
    button.badge = button:CreateFontString(nil, "OVERLAY")
    button.badge:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 20, "THICKOUTLINE")
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
        icon.weapon:SetSize(math.floor(size * 0.4), math.floor(size * 0.4))
        icon.badge:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", math.max(10, math.floor(size * 0.36)), "THICKOUTLINE")
    end
    frame:SetSize(math.max(1, count) * (size + gap) - gap, size)
end

function ns.Alerts_Update()
    if not frame then return end
    if not ns.char.enabled then
        frame:Hide()
        ns.Alerts_UpdateApply(nil)
        return
    end
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
            icon.weapon:SetShown(entry.weapon ~= nil)
            icon.weaponBorder:SetShown(entry.weapon ~= nil)
            if entry.weapon then icon.weapon:SetTexture(entry.weapon) end
        end
    end
    layout(math.min(#list, MAX_ICONS))
    frame:SetShown(#list > 0)
    ns.Alerts_UpdateApply(list)
end

---------------------------------------------------------------------------------------------------
-- Click to apply. Using an item on a weapon is a protected action, so each poison icon gets an invisible secure
-- button over it running the macro "/use item:<poison>" + "/use <weapon slot>". Secure buttons can only be set up,
-- moved, shown or hidden out of combat: they are live only then, and only with the reminder locked (unlocked, a
-- click drags it). PLAYER_REGEN_DISABLED (just before the lockdown) hides them and cuts their anchors.
---------------------------------------------------------------------------------------------------
local applyButtons = {}

local function showApplyTooltip(self)
    local entry = self.entry
    if not entry then return end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(entry.text or "", 1, 1, 1)
    local poison = entry.poison
    GameTooltip:AddLine(L["Click: apply %s (%d in your bags)"]:format(poison.name, poison.stock), 0.3, 1, 0.3)
    GameTooltip:Show()
end

local function applyButton(i)
    if not applyButtons[i] then
        local b = CreateFrame("Button", "ApicaraoApplyButton" .. i, UIParent, "SecureActionButtonTemplate")
        b:RegisterForClicks("AnyUp", "AnyDown")
        b:SetAttribute("type1", "macro")
        b:SetScript("OnEnter", showApplyTooltip)
        b:SetScript("OnLeave", GameTooltip_Hide)
        b:Hide()
        applyButtons[i] = b
    end
    return applyButtons[i]
end

local function canSetUp()
    return not (InCombatLockdown and InCombatLockdown()) and not ns.inCombat
end

-- Out of combat: one live button over each poison icon that has a poison in the bags to apply.
function ns.Alerts_UpdateApply(list)
    if not canSetUp() then return end
    local live = ns.char.locked and frame:IsShown()
    for i = 1, MAX_ICONS do
        local entry = list and list[i]
        local poison = entry and entry.poison
        local active = live and entry ~= nil and entry.slot ~= nil and poison ~= nil and poison.item ~= nil
        if active or applyButtons[i] then
            local b = applyButton(i)
            if active then
                b.entry = entry
                b:SetAttribute("macrotext1", ("/use item:%d\n/use %d"):format(poison.item, entry.slot))
                b:ClearAllPoints()
                b:SetAllPoints(icons[i])
                b:Show()
            else
                b.entry = nil
                b:Hide()
                b:ClearAllPoints()
            end
        end
    end
end

-- Combat starts: every apply button goes away while that is still allowed.
local function hideApplyButtons()
    for _, b in ipairs(applyButtons) do
        b.entry = nil
        b:Hide()
        b:ClearAllPoints()
    end
end

function ns.Alerts_ApplyButtons() return applyButtons end

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

-- Clicks: taken only while unlocked and out of combat (ns.TakesMouse).
function ns.Alerts_UpdateMouse()
    if not frame then return end
    local takes = ns.TakesMouse()
    if not takes then frame:StopMovingOrSizing() end
    frame:EnableMouse(takes)
    if ns.inCombat then hideApplyButtons() end
end

function ns.Alerts_Apply()
    if not frame then return end
    local c = ns.char
    frame:SetScale(c.scale)
    frame:ClearAllPoints()
    local pos = c.alertPos or { "CENTER", "CENTER", 0, 180 }
    frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    ns.Alerts_UpdateMouse()
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
