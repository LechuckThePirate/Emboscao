-- luacheck: Lua 5.1, the game's version. Runs in CI; locally:
--   luacheck -q -- Emboscao.lua Localization Modules Emboscao.test.lua test setupTests.lua
std = "lua51"
max_line_length = 160
codes = true

exclude_files = {
    "tools/",
    ".github/",
    "images/",
    ".claude/",
}

-- what the addon defines as globals
globals = {
    "EmboscaoDB", "EmboscaoCharDB",
    "SlashCmdList", "SLASH_EMBOSCAO1", "SLASH_EMBOSCAO2",
}

-- the game's API and frames it uses
-- the color picker of old clients is set up by writing its fields
read_globals = {
    ColorPickerFrame = { read_only = false, other_fields = true },
    "C_AddOns", "C_Item", "C_Secrets", "CLOSE", "GetCursorPosition", "InCombatLockdown", "IsMouseButtonDown", "Minimap", "C_Spell", "C_Timer", "C_UnitAuras", "CreateFrame", "Enum",
    "GetAddOnMetadata", "GetComboPoints", "GetInventoryItemID", "GetInventoryItemTexture", "GetItemCount", "GetItemIcon",
    "GetItemInfo", "GetItemInfoInstant", "GetLocale", "GameTooltip", "GameTooltip_Hide", "GetSpellInfo", "GetTime", "GetWeaponEnchantInfo", "IsPlayerSpell",
    "OpacitySliderFrame", "PlaySound", "STANDARD_TEXT_FONT", "issecretvalue", "UIParent", "UISpecialFrames", "UnitAffectingCombat", "UnitAura", "UnitCanAttack", "UnitClass", "UnitIsDead",
    "UnitExists", "UnitLevel", "UnitPower", "UnitPowerMax", "strtrim", "tinsert",
}

-- tests (busted): they define and change the simulated game's globals on purpose
files["**/*.test.lua"] = { std = "+busted", globals = { "_G" }, allow_defined_top = true, ignore = { "111", "112", "113", "121", "122" } }
files["setupTests.lua"] = { std = "+busted", allow_defined_top = true, ignore = { "111", "112", "113", "121", "122" } }
files["test/"] = { std = "+busted", allow_defined_top = true, ignore = { "111", "112", "113", "121", "122", "131", "212" } }
