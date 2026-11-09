local _, ns = ...

-- Keys are the English text; on esES/esMX clients they are replaced by the Spanish one.
local es = {
    ["initializing..."] = "inicializando...",
    ["initialization complete"] = "inicialización completa",
    ["Usage: /apicarao | prefs | lock | unlock | reset | version"] =
        "Uso: /apicarao | prefs | lock | unlock | reset | version",
    ["Apicarao!! is for rogues: nothing to do on this character."] =
        "Apicarao!! es para pícaros: en este personaje no hace nada.",
    ["Locked."] = "Bloqueado.",
    ["Unlocked: drag the bars and the reminder, right-click them for the preferences."] =
        "Desbloqueado: arrastra las barras y el aviso, clic derecho para las preferencias.",
    ["Positions reset."] = "Posiciones restablecidas.",

    -- bars and reminder
    ["Apicarao!! -- drag to move, right-click: preferences"] = "Apicarao!! -- arrastra para mover, clic derecho: preferencias",
    ["Apicarao!! reminders -- drag to move"] = "Avisos de Apicarao!! -- arrastra para mover",
    ["Poison and reagent reminders show here"] = "Aquí salen los avisos de venenos y componentes",
    ["Main hand"] = "Mano principal",
    ["Off hand"] = "Mano secundaria",
    ["%s: no poison"] = "%s: sin veneno",
    ["%s: poison ends in %s"] = "%s: el veneno se acaba en %s",
    ["%s: %d poison charges left"] = "%s: quedan %d cargas de veneno",
    ["%s: %d left"] = "%s: quedan %d",
    ["Flash Powder"] = "Polvo destellante",
    ["Blinding Powder"] = "Polvo cegador",

    -- preferences
    ["Apicarao!! Preferences"] = "Preferencias de Apicarao!!",
    ["Settings are saved for this character only."] = "Los ajustes se guardan solo para este personaje.",
    ["Settings are shared by all your characters."] = "Los ajustes son comunes a todos tus personajes.",
    ["Character specific preferences"] = "Preferencias por personaje",
    ["Lock the bars and the reminder"] = "Bloquear las barras y el aviso",
    ["Hide the bars when idle (out of combat, nothing to show)"] = "Ocultar las barras sin actividad (fuera de combate, nada que mostrar)",
    ["Scale: %d%%"] = "Escala: %d%%",
    ["Combo points"] = "Puntos de combo",
    ["Width: %d"] = "Ancho: %d",
    ["Height: %d"] = "Alto: %d",
    ["Spacing: %d"] = "Separación: %d",
    ["Point color"] = "Color del punto",
    ["Another color when all the points are up"] = "Otro color cuando tienes todos los puntos",
    ["Color with all the points"] = "Color con todos los puntos",
    ["Empty point color"] = "Color del punto vacío",
    ["Energy"] = "Energía",
    ["Show the energy bar"] = "Mostrar la barra de energía",
    ["Show the next energy tick (spark)"] = "Mostrar el próximo tick de energía (chispa)",
    ["Show the energy value"] = "Mostrar el valor de energía",
    ["Energy color"] = "Color de la energía",
    ["Duration bars"] = "Barras de duración",
    ["Show the duration bars"] = "Mostrar las barras de duración",
    ["Poisons"] = "Venenos",
    ["Remind me to apply poisons"] = "Avisarme de poner venenos",
    ["Off hand too"] = "También la mano secundaria",
    ["Also in combat"] = "También en combate",
    ["Play a sound"] = "Hacer sonar un aviso",
    ["Warn %d minutes before it ends"] = "Avisar %d minutos antes de que se acabe",
    ["Don't look at the charges"] = "No mirar las cargas",
    ["Warn with fewer than %d charges"] = "Avisar con menos de %d cargas",
    ["Reagents"] = "Componentes",
    ["Warn when Flash Powder or Blinding Powder run low"] = "Avisar cuando quede poco Polvo destellante o Polvo cegador",
    ["Fewer than %d"] = "Menos de %d",
    ["Reset positions"] = "Restablecer posiciones",
    ["Reset everything"] = "Restablecer todo",
    ["Show chat messages at startup"] = "Mostrar mensajes en el chat al iniciar",
}

local locale = GetLocale and GetLocale() or "enUS"
local active = (locale == "esES" or locale == "esMX") and es or {}

-- English text is the key: a missing translation shows the English one.
ns.L = setmetatable({}, { __index = function(_, key) return active[key] or key end })
ns.L_ES = es -- for the tests (every key used has a translation)
