local _, ns = ...
local L = ns.L

-- The reminder: a movable list (icon + text) of what needs attention -- a weapon without poison or about to
-- lose it, reagents running low. Checked every second. When something new shows up: a sound (out of combat)
-- and a chat line, once; it then stays on screen until it is fixed.
local ROWS, ROW_H = 4, 22
local CHECK_EVERY = 1
local frame, rows = nil, {}
local known = {}  -- issue keys already announced
local SOUND_RAID_WARNING = 8959

local function inCombat() return UnitAffectingCombat("player") and true or false end

local function clock(seconds)
    seconds = math.max(0, math.floor(seconds))
    return ("%d:%02d"):format(math.floor(seconds / 60), seconds % 60)
end

local function handName(slot)
    return slot == ns.SLOT_MAIN_HAND and L["Main hand"] or L["Off hand"]
end

-- The lines to show now: { { key =, icon =, text =, color = } }.
function ns.Alerts_Collect()
    local c = ns.char
    local lines = {}
    if c.poisonWarn and (c.poisonInCombat or not inCombat()) then
        for _, issue in ipairs(ns.Poisons_Check({ minutes = c.poisonMinutes, charges = c.poisonCharges, offHand = c.poisonOffHand })) do
            local text, color
            if issue.status == "missing" then
                text, color = L["%s: no poison"]:format(handName(issue.slot)), { 1, 0.2, 0.2 }
            elseif issue.status == "expiring" then
                text, color = L["%s: poison ends in %s"]:format(handName(issue.slot), clock(issue.left)), { 1, 0.6, 0.1 }
            else
                text, color = L["%s: %d poison charges left"]:format(handName(issue.slot), issue.charges), { 1, 0.6, 0.1 }
            end
            lines[#lines + 1] = { key = issue.slot .. ":" .. issue.status, icon = GetInventoryItemTexture("player", issue.slot),
                text = text, color = color }
        end
    end
    if c.reagentWarn and not inCombat() then
        for _, low in ipairs(ns.Reagents_Check(c.reagentMin)) do
            local icon = GetItemIcon and GetItemIcon(low.item)
            lines[#lines + 1] = { key = "item:" .. low.item, icon = icon,
                text = L["%s: %d left"]:format(low.name, low.count), color = { 1, 0.82, 0 } }
        end
    end
    return lines
end

local function savePosition()
    local point, _, relPoint, x, y = frame:GetPoint(1)
    ns.char.alertPos = { point, relPoint, x, y }
end

local function create()
    frame = CreateFrame("Frame", "ApicaraoAlert", UIParent)
    frame:SetSize(260, ROWS * ROW_H)
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
    frame.mover:SetAllPoints()
    frame.mover:SetColorTexture(0, 0.5, 1, 0.25)
    frame.moverLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.moverLabel:SetPoint("BOTTOM", frame, "TOP", 0, 4)
    frame.moverLabel:SetText(L["Apicarao!! reminders -- drag to move"])
    for i = 1, ROWS do
        local row = {}
        row.icon = frame:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(ROW_H - 2, ROW_H - 2)
        row.icon:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        row.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.text:SetJustifyH("LEFT")
        rows[i] = row
    end
end

local function announce(lines)
    local now = {}
    local fresh = {}
    for _, line in ipairs(lines) do
        now[line.key] = true
        if not known[line.key] then fresh[#fresh + 1] = line end
    end
    known = now
    if #fresh == 0 then return end
    for _, line in ipairs(fresh) do ns.Print(line.text) end
    if ns.char.poisonSound and not inCombat() then PlaySound(SOUND_RAID_WARNING, "Master") end
end

function ns.Alerts_Update()
    if not frame then return end
    local lines = ns.Alerts_Collect()
    announce(lines)
    local setup = not ns.char.locked or ns.Prefs_IsShown()
    if #lines == 0 and setup then
        lines = { { key = "sample", icon = "Interface\\Icons\\Ability_Rogue_DualWeild", text = L["Poison and reagent reminders show here"],
            color = { 0.7, 0.7, 0.7 } } }
    end
    for i, row in ipairs(rows) do
        local line = lines[i]
        row.icon:SetShown(line ~= nil)
        row.text:SetShown(line ~= nil)
        if line then
            row.icon:SetTexture(line.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.text:SetText(line.text)
            row.text:SetTextColor(line.color[1], line.color[2], line.color[3])
        end
    end
    frame:SetShown(#lines > 0)
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
