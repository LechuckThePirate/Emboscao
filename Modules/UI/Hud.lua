local _, ns = ...
local L = ns.L

-- The bars: combo points side by side, energy under them (with the tick spark) and the duration bars under
-- that. No window: just the bars, dragged around while unlocked (a dark box and a label show where it is).
local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local GAP = 3          -- between the rows
local UPDATE_EVERY = 0.05
local hud, points, energy, timerBars = nil, {}, nil, {}
local previewPoints, previewSince = 0, 0
local appliedMax -- the points laid out by Hud_Apply

local function inCombat() return UnitAffectingCombat("player") and true or false end

local function savePosition()
    local point, _, relPoint, x, y = hud:GetPoint(1)
    ns.char.hudPos = { point, relPoint, x, y }
end

local function placeAt(frame, pos, default)
    frame:ClearAllPoints()
    pos = pos or default
    frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

-- One combo point: a StatusBar from i-1 to i fed the whole count, so it is full when you have at least i points.
-- The game draws it, which works even when the count is a secret value.
local function newPoint(parent, i)
    local p = CreateFrame("StatusBar", nil, parent)
    p:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    p:SetMinMaxValues(i - 1, i)
    p.border = p:CreateTexture(nil, "BACKGROUND", nil, -2)
    p.border:SetPoint("TOPLEFT", -1, 1)
    p.border:SetPoint("BOTTOMRIGHT", 1, -1)
    p.border:SetColorTexture(0, 0, 0, 0.9)
    p.empty = p:CreateTexture(nil, "BACKGROUND", nil, -1)
    p.empty:SetAllPoints()
    return p
end

local function newStatusBar(parent)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetStatusBarTexture(BAR_TEXTURE)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", 1, -1)
    bg:SetColorTexture(0, 0, 0, 0.7)
    bar.left = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.left:SetPoint("LEFT", 3, 0)
    bar.right = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.right:SetPoint("RIGHT", -3, 0)
    return bar
end

local function create()
    hud = CreateFrame("Frame", "ApicaraoHud", UIParent)
    hud:SetClampedToScreen(true)
    hud:SetMovable(true)
    hud:RegisterForDrag("LeftButton")
    hud:SetScript("OnDragStart", function(self) if not ns.char.locked then self:StartMoving() end end)
    hud:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePosition()
    end)
    hud:SetScript("OnMouseUp", function(_, button) if button == "RightButton" then ns.Prefs_Toggle() end end)

    -- where it is while unlocked
    hud.mover = hud:CreateTexture(nil, "BACKGROUND")
    hud.mover:SetPoint("TOPLEFT", -4, 4)
    hud.mover:SetPoint("BOTTOMRIGHT", 4, -4)
    hud.mover:SetColorTexture(0, 0.5, 1, 0.25)
    hud.moverLabel = hud:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hud.moverLabel:SetPoint("BOTTOM", hud, "TOP", 0, 6)
    hud.moverLabel:SetText(L["Apicarao!! -- drag to move, right-click: preferences"])

    -- padlock left of the points, only while unlocked: one click locks the bars and the reminder (locked, they
    -- let the clicks through, so unlocking goes through /apicarao unlock or the preferences)
    local lock = CreateFrame("Button", nil, hud)
    lock:SetSize(18, 18)
    lock:SetPoint("RIGHT", hud, "LEFT", -8, 0)
    lock:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
    lock:SetPushedTexture("Interface\\Buttons\\LockButton-Locked-Up")
    lock:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    lock:SetScript("OnClick", function() ns.SetLocked(true) end)
    lock:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Lock position"], 1, 1, 1)
        GameTooltip:AddLine(L["Unlock again with /apicarao unlock"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    lock:SetScript("OnLeave", GameTooltip_Hide)
    hud.lock = lock

    energy = newStatusBar(hud)
    energy.spark = energy:CreateTexture(nil, "OVERLAY")
    energy.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    energy.spark:SetBlendMode("ADD")
    energy.left:Hide()
    energy.right:ClearAllPoints()
    energy.right:SetPoint("CENTER")

    local elapsed = 0
    hud:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + (dt or 0)
        if elapsed < UPDATE_EVERY then return end
        elapsed = 0
        ns.Hud_Update()
    end)
end

local function point(i)
    if not points[i] then points[i] = newPoint(hud, i) end
    return points[i]
end

local function timerBar(i)
    if not timerBars[i] then
        local bar = newStatusBar(hud)
        bar.icon = bar:CreateTexture(nil, "ARTWORK")
        bar.icon:SetPoint("RIGHT", bar, "LEFT", -2, 0)
        timerBars[i] = bar
    end
    return timerBars[i]
end

local function totalWidth(max)
    local c = ns.char
    return max * c.comboWidth + (max - 1) * c.comboSpacing
end

-- Clicks: taken only while unlocked and out of combat (ns.TakesMouse); the padlock too.
function ns.Hud_UpdateMouse()
    if not hud then return end
    local takes = ns.TakesMouse()
    if not takes then hud:StopMovingOrSizing() end
    hud:EnableMouse(takes)
    hud.lock:EnableMouse(takes)
end

-- Sizes, positions and colors from the settings.
function ns.Hud_Apply()
    if not hud then return end
    local c = ns.char
    hud:SetScale(c.scale)
    placeAt(hud, c.hudPos, { "CENTER", "CENTER", 0, -160 })
    ns.Hud_UpdateMouse()
    hud.mover:SetShown(not c.locked)
    hud.moverLabel:SetShown(not c.locked)
    hud.lock:SetShown(not c.locked)
    local _, max = ns.Combo_Get()
    appliedMax = max
    local width = totalWidth(max)
    for i = 1, math.max(max, #points) do
        local p = point(i)
        p:ClearAllPoints()
        p:SetPoint("TOPLEFT", hud, "TOPLEFT", (i - 1) * (c.comboWidth + c.comboSpacing), 0)
        p:SetSize(c.comboWidth, c.comboHeight)
        p:SetShown(i <= max)
        local e = c.comboEmptyColor
        p.empty:SetColorTexture(e[1], e[2], e[3], e[4] or 1)
    end
    energy:ClearAllPoints()
    energy:SetPoint("TOPLEFT", hud, "TOPLEFT", 1, -(c.comboHeight + GAP + 1))
    energy:SetSize(width - 2, c.energyHeight)
    local e = c.energyColor
    energy:SetStatusBarColor(e[1], e[2], e[3], e[4] or 1)
    energy.spark:SetSize(12, c.energyHeight * 2.2)
    hud:SetSize(width, c.comboHeight)
    ns.Hud_Update()
end

-- In preview (preferences open, or unlocked) with no real points, the points count up so the colors show.
local function shownPoints(real, max, now)
    if ns.IsSecret(real) or real > 0 or not (ns.Prefs_IsShown() or not ns.char.locked) then return real end
    if now - previewSince >= 0.8 then
        previewSince = now
        previewPoints = (previewPoints + 1) % (max + 1)
    end
    return previewPoints
end

-- The "all the points" color needs to compare the count, so it's skipped while the count is secret.
local function colorPoints(have, max)
    local c = ns.char
    local full = c.useFullColor and not ns.IsSecret(have) and have >= max
    local color = full and c.comboFullColor or c.comboColor
    for i = 1, max do
        points[i]:SetStatusBarColor(color[1], color[2], color[3], color[4] or 1)
        points[i]:SetValue(have)
    end
end

local function layoutTimers(active, top, width)
    local c = ns.char
    for i, bar in ipairs(timerBars) do bar:SetShown(i <= #active) end
    for i, aura in ipairs(active) do
        local bar = timerBar(i)
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", hud, "TOPLEFT", c.timerHeight + 3, top - (i - 1) * (c.timerHeight + GAP))
        bar:SetSize(width - c.timerHeight - 4, c.timerHeight)
        bar.icon:SetSize(c.timerHeight + 1, c.timerHeight + 1)
        bar.icon:SetTexture(aura.icon)
        local color = aura.timer.color
        bar:SetStatusBarColor(color[1], color[2], color[3], 1)
        bar:SetMinMaxValues(0, aura.duration)
        bar:SetValue(aura.left)
        bar.left:SetText(aura.name)
        bar.right:SetText(("%d"):format(math.ceil(aura.left)))
        bar:Show()
    end
end

-- Whether the bars have anything to say: in combat, points, energy not full, a timer running, or being set up.
-- A secret count means the game is hiding it: there is something to show.
function ns.Hud_ShouldShow(points_, energyCur, energyMax, activeTimers)
    local c = ns.char
    if not c.hideIdle or not c.locked or ns.Prefs_IsShown() then return true end
    if inCombat() or activeTimers > 0 then return true end
    if ns.IsSecret(points_) or points_ > 0 then return true end
    return not ns.IsSecret(energyCur) and energyCur < energyMax
end

function ns.Hud_Update()
    if not hud then return end
    local c = ns.char
    local now = GetTime()
    local real, max = ns.Combo_Get()
    if max ~= appliedMax then ns.Hud_Apply() return end
    local cur, emax = ns.Energy_Get()
    local active = c.showTimers and ns.Auras_Active(c, now) or {}
    if not ns.Hud_ShouldShow(real, cur, emax, #active) then
        hud:SetAlpha(0)
        return
    end
    hud:SetAlpha(1)
    colorPoints(shownPoints(real, max, now), max)

    local width = totalWidth(max)
    local top = -(c.comboHeight + GAP)
    energy:SetShown(c.showEnergy)
    if c.showEnergy then
        energy:SetMinMaxValues(0, emax)
        energy:SetValue(cur)
        -- the number itself, not tostring(): the game's text widget takes a secret one
        if c.energyText then energy.right:SetText(cur) else energy.right:SetText("") end
        local progress = c.energyTick and ns.Energy_TickProgress(now)
        energy.spark:SetShown(progress ~= nil and progress ~= false)
        if progress then
            energy.spark:ClearAllPoints()
            energy.spark:SetPoint("CENTER", energy, "LEFT", progress * (width - 2), 0)
        end
        top = top - c.energyHeight - GAP
    end
    layoutTimers(active, top, width)
end

-- Energy changes feed the tick detection (Modules/Rogue/Energy.lua).
local function onEnergy()
    local cur, max = ns.Energy_Get()
    ns.Energy_OnChange(cur, max, GetTime())
end

local function register(frame, event)
    pcall(frame.RegisterEvent, frame, event) -- an event this client doesn't have is skipped
end

function ns.Hud_Init()
    if not hud then create() end
    local events = CreateFrame("Frame")
    for _, event in ipairs({ "UNIT_POWER_FREQUENT", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "PLAYER_TARGET_CHANGED",
        "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UNIT_AURA", "UNIT_SPELLCAST_SUCCEEDED" }) do
        register(events, event)
    end
    events:SetScript("OnEvent", function(_, event, unit, kind)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if unit == "player" then ns.Energy_OnCast(GetTime()) end
            return
        end
        -- UNIT_POWER_FREQUENT only: UNIT_POWER_UPDATE repeats the same change (two "ticks" from one rise)
        if event == "UNIT_POWER_FREQUENT" and unit == "player" and kind == "ENERGY" then
            onEnergy()
        end
        ns.Hud_Update()
    end)
    onEnergy()
    ns.Hud_Apply()
end

function ns.Hud_ResetPosition()
    ns.char.hudPos = nil
    ns.Hud_Apply()
end

function ns.Hud_Frame() return hud end
function ns.Hud_Points() return points end
function ns.Hud_Energy() return energy end
