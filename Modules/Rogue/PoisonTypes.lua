local _, ns = ...

-- The rogue's poisons on Forever, by type, each rank with its recipe (spell) and reagents. Taken from Fabrikao's
-- Forever recipe data (skill line 40, Poisons); Forever adds Sebacious, Atrophic, Numbing and Occult to the classic
-- five. Ranks go from lowest to highest.
local EMPTY_VIAL, LEADED_VIAL, CRYSTAL_VIAL = 3371, 3372, 8925
local DECAY, DETERIORATION, PAIN, AGONY, DEATHWEED = 2928, 8924, 2930, 8923, 5173

ns.POISON_TYPES = {
    { key = "instant", name = "Instant Poison", ranks = {
        { spell = 8681, item = 6947, reagents = { { DECAY, 1 }, { EMPTY_VIAL, 1 } } },
        { spell = 8687, item = 6949, reagents = { { DECAY, 3 }, { LEADED_VIAL, 1 } } },
        { spell = 8691, item = 6950, reagents = { { DETERIORATION, 1 }, { LEADED_VIAL, 1 } } },
        { spell = 11341, item = 8926, reagents = { { DETERIORATION, 2 }, { CRYSTAL_VIAL, 1 } } },
        { spell = 11342, item = 8927, reagents = { { DETERIORATION, 3 }, { CRYSTAL_VIAL, 1 } } },
        { spell = 11343, item = 8928, reagents = { { DETERIORATION, 4 }, { CRYSTAL_VIAL, 1 } } },
    } },
    { key = "deadly", name = "Deadly Poison", ranks = {
        { spell = 2835, item = 2892, reagents = { { DEATHWEED, 1 }, { LEADED_VIAL, 1 } } },
        { spell = 2837, item = 2893, reagents = { { DEATHWEED, 2 }, { LEADED_VIAL, 1 } } },
        { spell = 11357, item = 8984, reagents = { { DEATHWEED, 3 }, { CRYSTAL_VIAL, 1 } } },
        { spell = 11358, item = 8985, reagents = { { DEATHWEED, 5 }, { CRYSTAL_VIAL, 1 } } },
        { spell = 25347, item = 20844, reagents = { { DEATHWEED, 7 }, { CRYSTAL_VIAL, 1 } } },
    } },
    { key = "crippling", name = "Crippling Poison", ranks = {
        { spell = 3420, item = 3775, reagents = { { PAIN, 1 }, { EMPTY_VIAL, 1 } } },
        { spell = 3421, item = 3776, reagents = { { AGONY, 3 }, { CRYSTAL_VIAL, 1 } } },
    } },
    { key = "mindnumbing", name = "Mind-numbing Poison", ranks = {
        { spell = 5763, item = 5237, reagents = { { DECAY, 1 }, { PAIN, 1 }, { EMPTY_VIAL, 1 } } },
        { spell = 8694, item = 6951, reagents = { { DECAY, 4 }, { PAIN, 4 }, { LEADED_VIAL, 1 } } },
        { spell = 11400, item = 9186, reagents = { { DETERIORATION, 2 }, { AGONY, 2 }, { CRYSTAL_VIAL, 1 } } },
    } },
    { key = "wound", name = "Wound Poison", ranks = {
        { spell = 13220, item = 10918, reagents = { { PAIN, 1 }, { DEATHWEED, 1 }, { LEADED_VIAL, 1 } } },
        { spell = 13228, item = 10920, reagents = { { PAIN, 1 }, { DEATHWEED, 2 }, { LEADED_VIAL, 1 } } },
        { spell = 13229, item = 10921, reagents = { { AGONY, 1 }, { DEATHWEED, 2 }, { CRYSTAL_VIAL, 1 } } },
        { spell = 13230, item = 10922, reagents = { { AGONY, 2 }, { DEATHWEED, 2 }, { CRYSTAL_VIAL, 1 } } },
    } },
    { key = "sebacious", name = "Sebacious Poison", ranks = {
        { spell = 439500, item = 217345, reagents = { { AGONY, 4 }, { CRYSTAL_VIAL, 1 } } },
    } },
    { key = "atrophic", name = "Atrophic Poison", ranks = {
        { spell = 439503, item = 217347, reagents = { { DETERIORATION, 7 }, { CRYSTAL_VIAL, 1 } } },
    } },
    { key = "numbing", name = "Numbing Poison", ranks = {
        { spell = 439505, item = 217346, reagents = { { DETERIORATION, 3 }, { CRYSTAL_VIAL, 1 }, { AGONY, 1 } } },
    } },
    { key = "occult", name = "Occult Poison", ranks = {
        { spell = 458822, item = 226374, reagents = { { DEATHWEED, 5 }, { CRYSTAL_VIAL, 1 }, { AGONY, 5 } } },
        { spell = 1214168, item = 234444, reagents = { { DEATHWEED, 7 }, { CRYSTAL_VIAL, 1 } } },
    } },
}

local byKey = {}
for _, t in ipairs(ns.POISON_TYPES) do byKey[t.key] = t end

function ns.ItemCount(itemID)
    local getCount = (C_Item and C_Item.GetItemCount) or GetItemCount
    return getCount and getCount(itemID) or 0
end

function ns.ItemIcon(itemID)
    if C_Item and C_Item.GetItemIconByID then return C_Item.GetItemIconByID(itemID) end
    if GetItemIcon then return GetItemIcon(itemID) end
end

local function spellName(id)
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
    if GetSpellInfo then return (GetSpellInfo(id)) end
end

local function knows(spell)
    return IsPlayerSpell ~= nil and IsPlayerSpell(spell) == true
end

-- The type's name in the client's language (its first rank's recipe), ours until the game answers.
local function typeName(t)
    return spellName(t.ranks[1].spell) or ns.L[t.name]
end

-- What can be said about a poison type now:
--   name; item / stock: the highest rank in the bags and how many (nil / 0 without any);
--   known: a rank's recipe is learned; craftable: how many of the highest learned rank the bags' reagents make.
function ns.PoisonType_Status(key)
    local t = byKey[key]
    if not t then return nil end
    local status = { key = key, name = typeName(t), stock = 0, known = false, craftable = 0 }
    for i = #t.ranks, 1, -1 do
        local rank = t.ranks[i]
        local have = ns.ItemCount(rank.item)
        if have > 0 and not status.item then status.item, status.stock = rank.item, have end
        if not status.known and knows(rank.spell) then
            status.known = true
            local can = math.huge
            for _, reagent in ipairs(rank.reagents) do
                can = math.min(can, math.floor(ns.ItemCount(reagent[1]) / reagent[2]))
            end
            status.craftable = can
        end
    end
    -- the picture of the highest rank you have or know (for the menus), else the first one's
    status.icon = ns.ItemIcon(status.item or t.ranks[1].item)
    return status
end

-- The type a hand gets: the preference ("auto", "none" or a type's key). Auto: Instant in the main hand; Deadly in
-- the off hand when you know it or carry it, else Instant.
function ns.Poisons_AutoFor(slot)
    if slot == ns.SLOT_OFF_HAND then
        local deadly = ns.PoisonType_Status("deadly")
        if deadly.known or deadly.stock > 0 then return "deadly" end
    end
    return "instant"
end

function ns.Poisons_ChoiceFor(slot)
    local choice = slot == ns.SLOT_OFF_HAND and ns.char.poisonOffType or ns.char.poisonMainType
    if choice ~= "auto" and (choice == "none" or byKey[choice]) then return choice end
    return ns.Poisons_AutoFor(slot)
end
