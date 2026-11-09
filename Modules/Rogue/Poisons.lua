local _, ns = ...

-- Poisons on the weapons: GetWeaponEnchantInfo tells whether each hand has a temporary enchant, how long it
-- has left (milliseconds) and its charges. Any temporary enchant counts (a sharpening stone is your choice).
-- Rogues learn poisons at level 20; below that there is nothing to remind.
ns.SLOT_MAIN_HAND, ns.SLOT_OFF_HAND = 16, 17
ns.POISONS_LEVEL = 20
local WEAPON_CLASS = 2

local function itemClass(itemID)
    local getInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not getInfo then return nil end
    return (select(6, getInfo(itemID)))
end

-- A weapon in that slot (not a shield or an off-hand item). Unknown class: take it as a weapon.
function ns.Poisons_HasWeapon(slot)
    local id = GetInventoryItemID("player", slot)
    if not id then return false end
    local class = itemClass(id)
    return class == nil or class == WEAPON_CLASS
end

-- One hand's state: "missing", "expiring" (less than `minutes` left), "charges" (fewer than `charges`, 0 = off)
-- or "ok"; then the seconds left and the charges.
function ns.Poisons_Evaluate(has, expirationMs, charges, minutes, minCharges)
    if not has then return "missing", 0, 0 end
    local left = (expirationMs or 0) / 1000
    if left > 0 and left < minutes * 60 then return "expiring", left, charges end
    if minCharges and minCharges > 0 and charges and charges > 0 and charges < minCharges then
        return "charges", left, charges
    end
    return "ok", left, charges
end

-- What needs a poison now: { { slot =, status =, left =, charges = } }, empty when all is fine.
function ns.Poisons_Check(opts)
    local issues = {}
    if (UnitLevel("player") or 0) < ns.POISONS_LEVEL or not GetWeaponEnchantInfo then return issues end
    local hasMH, mhExp, mhCharges, _, hasOH, ohExp, ohCharges = GetWeaponEnchantInfo()
    local hands = { { ns.SLOT_MAIN_HAND, hasMH, mhExp, mhCharges } }
    if opts.offHand then hands[2] = { ns.SLOT_OFF_HAND, hasOH, ohExp, ohCharges } end
    for _, hand in ipairs(hands) do
        local slot = hand[1]
        if ns.Poisons_HasWeapon(slot) then
            local status, left, charges = ns.Poisons_Evaluate(hand[2], hand[3], hand[4], opts.minutes, opts.charges)
            if status ~= "ok" then
                issues[#issues + 1] = { slot = slot, status = status, left = left, charges = charges }
            end
        end
    end
    return issues
end
