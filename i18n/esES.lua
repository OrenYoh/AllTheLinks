if(GetLocale() ~= 'esES') then
    return
end

local _, ns = ...
local L = ns.L

L["TITLE"] = "All the links";
L["LINKTO"] = "Enlace a: ";
L["COPYHINT"] = "Pulsa Ctrl+C para copiar el enlace y cerrar esta ventana.";
L["LINKCOPIED"] = "Enlace copiado: ";
L["LINKDESC"] = "Si aparece un error, puede que el perfil del jugador aún no exista en la web\n(nadie ha pedido nunca que se analice) y tengas que buscarlo manualmente.";

L["ARMORY"] = "Arsenal de WoW";
L["CHECKPVP"] = "Check PvP";
L["RAIDERIO"] = "Raider IO";
L["WARCRAFTLOGS"] = "Warcraft Logs";
L["WOWPROGRESS"] = "WoWProgress";
