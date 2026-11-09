local _, ns = ...

-- Keys are the English text; on esES/esMX clients they are replaced by the Spanish one.
local es = {
    ["initializing..."] = "inicializando...",
    ["initialization complete"] = "inicialización completa",
    ["Usage: /emboscao | prefs | toggle | lock | unlock | reset | minimap | about | version"] =
        "Uso: /emboscao | prefs | toggle | lock | unlock | reset | minimap | about | version",
    ["Bars and reminder shown."] = "Barras y aviso mostrados.",
    ["Bars and reminder hidden."] = "Barras y aviso ocultos.",

    -- minimap button
    ["Left-click: hide the bars"] = "Clic izquierdo: ocultar las barras",
    ["Left-click: show the bars"] = "Clic izquierdo: mostrar las barras",
    ["Right-click: menu"] = "Clic derecho: menú",
    ["Drag: move"] = "Arrastrar: mover",
    ["Preferences"] = "Preferencias",
    ["Hide the bars and the reminder"] = "Ocultar las barras y el aviso",
    ["Show the bars and the reminder"] = "Mostrar las barras y el aviso",
    ["Unlock position"] = "Desbloquear posición",
    ["Turn off the poison reminder"] = "Desactivar el aviso de venenos",
    ["Turn on the poison reminder"] = "Activar el aviso de venenos",
    ["About Emboscao!!"] = "Acerca de Emboscao!!",
    ["Hide the minimap button"] = "Ocultar el botón del minimapa",
    ["Show the minimap button"] = "Mostrar el botón del minimapa",
    ["Minimap button hidden. Show it again with /emboscao minimap."] =
        "Botón del minimapa oculto. Vuelve a mostrarlo con /emboscao minimap.",
    ["Minimap button shown."] = "Botón del minimapa mostrado.",

    -- about
    ["Version %s"] = "Versión %s",
    ["by LechuckThePirate"] = "por LechuckThePirate",
    ["Rogue toolset: combo point bars, energy and its tick, poison reminders with click to apply, reagent reminders."] =
        "Herramientas de pícaro: barras de puntos de combo, energía y su tick, avisos de venenos con clic para aplicarlos, avisos de componentes.",
    ["Commands: /emboscao (preferences), /emboscao toggle, lock, unlock, reset, minimap, about, version."] =
        "Comandos: /emboscao (preferencias), /emboscao toggle, lock, unlock, reset, minimap, about, version.",
    ["Found a bug or have an idea? Please report it on GitHub (click to select, then Ctrl+C):"] =
        "¿Has encontrado un fallo o tienes una idea? Cuéntalo en GitHub (clic para seleccionar y luego Ctrl+C):",
    ["Emboscao!! is for rogues: nothing to do on this character."] =
        "Emboscao!! es para pícaros: en este personaje no hace nada.",
    ["Locked."] = "Bloqueado.",
    ["Unlocked: drag the bars and the reminder, right-click them for the preferences."] =
        "Desbloqueado: arrastra las barras y el aviso, clic derecho para las preferencias.",
    ["Positions reset."] = "Posiciones restablecidas.",
    ["Lock position"] = "Bloquear posición",
    ["Unlock again with /emboscao unlock"] = "Para desbloquear de nuevo: /emboscao unlock",

    -- bars and reminder
    ["Emboscao!! -- drag to move, right-click: preferences"] = "Emboscao!! -- arrastra para mover, clic derecho: preferencias",
    ["Emboscao!! reminders -- drag to move"] = "Avisos de Emboscao!! -- arrastra para mover",
    ["Main hand"] = "Mano principal",
    ["Off hand"] = "Mano secundaria",
    ["%s: no poison"] = "%s: sin veneno",
    ["%s: poison ends in %s"] = "%s: el veneno se acaba en %s",
    ["%s: %d poison charges left"] = "%s: quedan %d cargas de veneno",
    ["%s: %d left"] = "%s: quedan %d",
    ["(you can make %d)"] = "(puedes fabricar %d)",
    ["no %s in your bags"] = "no llevas %s",
    ["Click: apply %s (%d in your bags)"] = "Clic: aplicar %s (llevas %d)",
    ["%s: %s"] = "%s: %s",
    ["Don't apply"] = "No aplicar",
    ["Automatic (%s)"] = "Automático (%s)",
    ["%d in bags"] = "llevas %d",
    ["can make %d"] = "puedes fabricar %d",
    ["no reagents"] = "sin componentes",
    ["not learned"] = "no aprendido",
    ["Instant Poison"] = "Veneno instantáneo",
    ["Deadly Poison"] = "Veneno mortal",
    ["Crippling Poison"] = "Veneno entorpecedor",
    ["Mind-numbing Poison"] = "Veneno de aturdimiento mental",
    ["Wound Poison"] = "Veneno hiriente",
    ["Flash Powder"] = "Polvo destellante",
    ["Blinding Powder"] = "Polvo cegador",

    -- preferences
    ["Emboscao!! Preferences"] = "Preferencias de Emboscao!!",
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
    ["Reminder icon size: %d"] = "Tamaño de los iconos de aviso: %d",
    ["Reset positions"] = "Restablecer posiciones",
    ["Reset everything"] = "Restablecer todo",
    ["Show chat messages at startup"] = "Mostrar mensajes en el chat al iniciar",
}

local locale = GetLocale and GetLocale() or "enUS"
local active = (locale == "esES" or locale == "esMX") and es or {}

-- English text is the key: a missing translation shows the English one.
ns.L = setmetatable({}, { __index = function(_, key) return active[key] or key end })
ns.L_ES = es -- for the tests (every key used has a translation)
