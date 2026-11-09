local _, ns = ...

-- Energy and its 2-second tick. The game doesn't say when the next tick comes, so it is learned from the energy
-- changes. Readable energy: a rise of about one tick (20, 40 with Adrenaline Rush, or less when it reaches the
-- top) is a tick; other rises (Relentless Strikes' 25, Thistle Tea's 100) are not. Secret energy (Forever): the
-- value can't be compared, so a change is taken as a tick when you didn't just cast something (spending energy,
-- and Relentless Strikes' refund, come right after a cast).
ns.ENERGY_TICK = 2
local CAST_WINDOW = 0.25 -- an energy change this soon after a cast belongs to the cast
local lastTick, lastEnergy, lastCast

local function energyType()
    return Enum and Enum.PowerType and Enum.PowerType.Energy or 3
end

-- Current (maybe secret) and maximum energy.
function ns.Energy_Get()
    local cur = UnitPower and UnitPower("player", energyType()) or 0
    local max = UnitPowerMax and UnitPowerMax("player", energyType()) or 100
    if ns.IsSecret(max) or not max or max <= 0 then max = 100 end
    return cur or 0, max
end

local function isTick(delta, energy, max)
    if delta >= 18 and delta <= 22 then return true end
    if delta >= 38 and delta <= 42 then return true end
    return energy >= max and delta < 18 -- a tick cut short by the top
end

-- Called on every energy change, with the time (GetTime()).
function ns.Energy_OnChange(energy, max, now)
    if ns.IsSecret(energy) then
        if not (lastCast and now - lastCast <= CAST_WINDOW) then lastTick = now end
        lastEnergy = nil
        return
    end
    if lastEnergy and energy > lastEnergy and isTick(energy - lastEnergy, energy, max) then
        lastTick = now
    end
    lastEnergy = energy
end

-- You cast something (UNIT_SPELLCAST_SUCCEEDED): the energy change that follows is not a tick.
function ns.Energy_OnCast(now)
    lastCast = now
end

-- How far into the current tick we are (0..1), or nil if no tick has been seen yet. Ticks keep coming at full
-- energy, so it keeps cycling: that's what you pool energy with.
function ns.Energy_TickProgress(now)
    if not lastTick then return nil end
    return ((now - lastTick) % ns.ENERGY_TICK) / ns.ENERGY_TICK
end

function ns.Energy_Reset()
    lastTick, lastEnergy, lastCast = nil, nil, nil
end
