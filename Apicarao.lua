local ADDON, ns = ...

-- Addon entry point: events and /apicarao. Loaded last, once the modules (Modules/) are in. Only rogues get
-- the bars and the reminder; on any other class the addon stays quiet.

function ns.Print(...)
    print("|cff33ff99Apicarao!!|r:", ...)
end

function ns.Version()
    local getMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    return getMeta and getMeta(ADDON, "Version") or "?"
end

local function announce(text)
    if ns.char and ns.char.quiet then return end
    print(("|cff33ff99Apicarao!!|r v%s -- %s"):format(ns.Version(), text))
end

function ns.IsRogue()
    local _, class = UnitClass("player")
    return class == "ROGUE"
end

-- After any change of settings: everything re-reads them.
function ns.ApplySettings()
    if not ns.active then return end
    ns.Hud_Apply()
    ns.Alerts_Apply()
end

-- Lock or unlock the bars and the reminder (slash command, the padlock, the preferences).
function ns.SetLocked(locked)
    ns.char.locked = locked and true or false
    ns.ApplySettings()
    ns.Prefs_Refresh()
    ns.Print(ns.char.locked and ns.L["Locked."]
        or ns.L["Unlocked: drag the bars and the reminder, right-click them for the preferences."])
end

local announcedReady = false
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON then return end
        ns.InitSettings()
        if not ns.IsRogue() then return end
        ns.active = true
        announce(ns.L["initializing..."])
        ns.Hud_Init()
        ns.Alerts_Init()
    elseif event == "PLAYER_ENTERING_WORLD" and ns.active then
        ns.ApplySettings()
        if not announcedReady then
            announcedReady = true
            C_Timer.After(1, function() announce(ns.L["initialization complete"]) end)
        end
    end
end)

SLASH_APICARAO1 = "/apicarao"
SLASH_APICARAO2 = "/apic"
SlashCmdList.APICARAO = function(msg)
    msg = strtrim((msg or ""):lower())
    if not ns.active then
        ns.Print(ns.L["Apicarao!! is for rogues: nothing to do on this character."])
        return
    end
    if msg == "version" then
        ns.Print("v" .. ns.Version())
    elseif msg == "" or msg == "prefs" or msg == "options" or msg == "config" then
        ns.Prefs_Toggle()
    elseif msg == "lock" or msg == "unlock" then
        ns.SetLocked(msg == "lock")
    elseif msg == "reset" then
        ns.Hud_ResetPosition()
        ns.Alerts_ResetPosition()
        ns.Print(ns.L["Positions reset."])
    else
        ns.Print(ns.L["Usage: /apicarao | prefs | lock | unlock | reset | version"])
    end
end
