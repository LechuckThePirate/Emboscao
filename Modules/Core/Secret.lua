local _, ns = ...

-- "Secret values": Forever (like Retail 12.x) hides some numbers from addons -- your energy, and in combat maybe
-- more. A secret can be handed to the game's widgets (StatusBar:SetValue, FontString:SetText) but comparing it or
-- doing arithmetic with it is a Lua error. Everything that compares a game value checks this first.
function ns.IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value) == true
end
