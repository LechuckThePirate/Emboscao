local _, ns = ...

-- Reagents of the rogue spells you know: Flash Powder (Vanish) and Blinding Powder (Blind). A spell is known
-- through IsPlayerSpell (any rank); where that's missing, by the level it is learned at.
ns.REAGENTS = {
    { item = 5140, name = "Flash Powder", spells = { 1856, 1857, 26889 }, level = 22 },
    { item = 5530, name = "Blinding Powder", spells = { 2094 }, level = 34 },
}

local function knows(reagent)
    if IsPlayerSpell then
        for _, id in ipairs(reagent.spells) do
            if IsPlayerSpell(id) then return true end
        end
        return false
    end
    return (UnitLevel("player") or 0) >= reagent.level
end

local function count(itemID)
    local getCount = (C_Item and C_Item.GetItemCount) or GetItemCount
    return getCount and getCount(itemID) or 0
end

-- The game's name (in the client's language) once it has the item cached; ours until then.
local function itemName(reagent)
    local getName = (C_Item and C_Item.GetItemNameByID) or GetItemInfo
    return (getName and getName(reagent.item)) or ns.L[reagent.name]
end

-- Reagents running low: { { item =, name =, count = } } with fewer than `min` in the bags.
function ns.Reagents_Check(min)
    local low = {}
    for _, reagent in ipairs(ns.REAGENTS) do
        if knows(reagent) then
            local have = count(reagent.item)
            if have < min then
                low[#low + 1] = { item = reagent.item, name = itemName(reagent), count = have }
            end
        end
    end
    return low
end
