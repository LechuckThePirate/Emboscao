local _, ns = ...

-- Duration bars: Slice and Dice on you and your own bleeds / Expose Armor on the target. Auras are matched by
-- the spell's name in the client's language, so every rank counts.
ns.TIMERS = {
    { key = "timerSliceAndDice", spell = 5171, unit = "player", filter = "HELPFUL", color = { 0.95, 0.75, 0.2 } },
    { key = "timerRupture", spell = 1943, unit = "target", filter = "HARMFUL|PLAYER", color = { 0.8, 0.1, 0.1 } },
    { key = "timerGarrote", spell = 703, unit = "target", filter = "HARMFUL|PLAYER", color = { 0.85, 0.35, 0.35 } },
    { key = "timerExposeArmor", spell = 8647, unit = "target", filter = "HARMFUL|PLAYER", color = { 0.6, 0.6, 0.75 } },
}

function ns.SpellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return (GetSpellInfo(id)) end
end

function ns.SpellIcon(id)
    if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
    if GetSpellInfo then return (select(3, GetSpellInfo(id))) end
end

-- Forever hides auras in combat: asking for one then is a Lua error ("Auras cannot be accessed when secret"), not a
-- secret value. When the game says they are secret, or a read fails, nothing is read again until a second has passed.
local RETRY_AFTER = 1
local hiddenUntil = 0

local function aurasHidden(now)
    if now < hiddenUntil then return true end
    if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then
        hiddenUntil = now + RETRY_AFTER
        return true
    end
    return false
end

-- One aura by name: its duration and expiration time, or nil.
local function findAura(unit, filter, name, now)
    for i = 1, 40 do
        local auraName, duration, expiration, source
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, filter)
            if not ok then
                hiddenUntil = now + RETRY_AFTER
                return nil
            end
            if not aura then return nil end
            auraName, duration, expiration, source = aura.name, aura.duration, aura.expirationTime, aura.sourceUnit
        elseif UnitAura then
            local n, _, _, _, d, e, s = UnitAura(unit, i, filter)
            if not n then return nil end
            auraName, duration, expiration, source = n, d, e, s
        else
            return nil
        end
        -- a hidden (secret) aura can't be matched or timed: skipped
        local hidden = ns.IsSecret(auraName) or ns.IsSecret(duration) or ns.IsSecret(expiration) or ns.IsSecret(source)
        if not hidden and auraName == name and (unit == "player" or source == nil or source == "player") then
            return duration, expiration
        end
    end
end

-- The enabled timers running now, in table order: { { timer =, name =, icon =, left =, duration = } }.
function ns.Auras_Active(settings, now)
    local active = {}
    if aurasHidden(now) then return active end
    for _, timer in ipairs(ns.TIMERS) do
        if settings[timer.key] and (timer.unit == "player" or UnitExists(timer.unit)) and not aurasHidden(now) then
            local name = ns.SpellName(timer.spell)
            local duration, expiration
            if name then duration, expiration = findAura(timer.unit, timer.filter, name, now) end
            if duration and duration > 0 and expiration and expiration > now then
                active[#active + 1] = { timer = timer, name = name, icon = ns.SpellIcon(timer.spell),
                    left = expiration - now, duration = duration }
            end
        end
    end
    return active
end
