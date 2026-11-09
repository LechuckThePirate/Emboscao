local _, ns = ...

-- Combo points. In the Classic clients they live on the target (GetComboPoints("player", "target")); the
-- power API (UnitPower with the ComboPoints type) is the fallback where that function is gone.
local function comboType()
    return Enum and Enum.PowerType and Enum.PowerType.ComboPoints or 4
end

-- Returns the points you have and how many you can have (5 unless the game says otherwise).
function ns.Combo_Get()
    local max = 5
    if UnitPowerMax then
        local m = UnitPowerMax("player", comboType())
        if m and m > 0 then max = m end
    end
    local points
    if GetComboPoints then
        points = GetComboPoints("player", "target")
    elseif UnitPower then
        points = UnitPower("player", comboType())
    end
    points = points or 0
    if points > max then points = max end
    return points, max
end
