local _, ns = ...

-- Settings per character or for the whole account, as in Aggreao, Embolsao and Completao ("Character specific
-- preferences"). The SWITCHABLE keys are read from and written to the active store: the character's
-- (ApicaraoCharDB) or the account's shared one (ApicaraoDB.shared). The rest of ns.char always belongs to the
-- character. A key that was never set reads as its default (DEFAULTS), so a checkbox can store a plain true / false.
-- Colors are { r, g, b, a } tables; they are always replaced, never changed in place (a default is shared).
ns.DEFAULTS = {
    locked = false,           -- the bars and the reminder can't be dragged (and clicks go through them)
    scale = 1,
    hideIdle = true,          -- hide the bars out of combat with no combo points and full energy

    -- combo points: one bar per point, side by side
    comboWidth = 32,
    comboHeight = 12,
    comboSpacing = 3,
    comboColor = { 1, 0.82, 0.1, 1 },       -- a point you have
    comboFullColor = { 1, 0.25, 0.15, 1 },  -- every point, when you have all of them
    comboEmptyColor = { 0.15, 0.15, 0.15, 0.7 },
    useFullColor = true,

    -- energy bar under the points, with a spark for the next 2-second tick
    showEnergy = true,
    energyHeight = 8,
    energyTick = true,
    energyText = true,
    energyColor = { 1, 0.9, 0.2, 1 },

    -- duration bars: Slice and Dice on you, your Rupture / Garrote / Expose Armor on the target
    showTimers = true,
    timerHeight = 10,
    timerSliceAndDice = true,
    timerRupture = true,
    timerGarrote = true,
    timerExposeArmor = true,

    -- poison reminder
    poisonWarn = true,
    poisonMinutes = 5,        -- warn when a poison has less than this left
    poisonCharges = 10,       -- or fewer charges than this (0 = don't look at the charges)
    poisonOffHand = true,     -- the off hand too
    poisonInCombat = false,   -- keep showing the reminder in combat
    poisonSound = true,

    -- reagents of the spells you know (Vanish, Blind)
    reagentWarn = true,
    reagentMin = 5,

    alertIconSize = 56,       -- the reminder's icons
}

local SWITCHABLE = {
    quiet = true, hudPos = true, alertPos = true,
    locked = true, scale = true, hideIdle = true,
    comboWidth = true, comboHeight = true, comboSpacing = true, comboColor = true, comboFullColor = true,
    comboEmptyColor = true, useFullColor = true,
    showEnergy = true, energyHeight = true, energyTick = true, energyText = true, energyColor = true,
    showTimers = true, timerHeight = true, timerSliceAndDice = true, timerRupture = true, timerGarrote = true,
    timerExposeArmor = true,
    poisonWarn = true, poisonMinutes = true, poisonCharges = true, poisonOffHand = true, poisonInCombat = true,
    poisonSound = true, reagentWarn = true, reagentMin = true, alertIconSize = true,
}

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do copy[k] = deepCopy(v) end
    return copy
end

local function activeStore()
    return ApicaraoCharDB.perCharacter and ApicaraoCharDB or ApicaraoDB.shared
end

-- On load (ADDON_LOADED): prepares the saved variables and ns.db / ns.char.
function ns.InitSettings()
    ApicaraoDB = ApicaraoDB or {}
    ApicaraoCharDB = ApicaraoCharDB or {}
    ns.db = ApicaraoDB
    -- the first time, the shared settings come from the character that first uses them
    if not ApicaraoDB.shared then
        ApicaraoDB.shared = {}
        for key in pairs(SWITCHABLE) do ApicaraoDB.shared[key] = deepCopy(ApicaraoCharDB[key]) end
    end
    -- per character by default; a new one starts with a copy of the shared ones
    if ApicaraoCharDB.perCharacter == nil then
        for key in pairs(SWITCHABLE) do
            if ApicaraoCharDB[key] == nil then ApicaraoCharDB[key] = deepCopy(ApicaraoDB.shared[key]) end
        end
        ApicaraoCharDB.perCharacter = true
    end
    ns.char = setmetatable({}, {
        __index = function(_, key)
            local value
            if SWITCHABLE[key] then value = activeStore()[key] else value = ApicaraoCharDB[key] end
            if value == nil then return ns.DEFAULTS[key] end
            return value
        end,
        __newindex = function(_, key, value)
            if SWITCHABLE[key] then activeStore()[key] = value else ApicaraoCharDB[key] = value end
        end,
    })
end

function ns.IsPerCharacter()
    return ApicaraoCharDB.perCharacter and true or false
end

-- Switching to per character copies the shared settings, so the change isn't noticed; switching back to
-- shared leaves the character's copy saved, unused. Then whatever is in the new store is applied.
function ns.SetPerCharacter(enabled)
    enabled = enabled and true or false
    if enabled == ns.IsPerCharacter() then return end
    if enabled then
        for key in pairs(SWITCHABLE) do ApicaraoCharDB[key] = deepCopy(ApicaraoDB.shared[key]) end
    end
    ApicaraoCharDB.perCharacter = enabled
    if ns.ApplySettings then ns.ApplySettings() end
end

-- Back to the defaults (positions included); the per character / shared choice stays.
function ns.ResetSettings()
    for key in pairs(SWITCHABLE) do activeStore()[key] = nil end
    if ns.ApplySettings then ns.ApplySettings() end
end
