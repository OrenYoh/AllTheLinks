if(GetLocale() ~= 'itIT') then
    return
end

local _, ns = ...
local L = ns.L

L["TITLE"] = "All the links";
L["LINKTO"] = "Link a: ";
L["COPYHINT"] = "Premi Ctrl+C per copiare il link e chiudere questa finestra.";
L["LINKCOPIED"] = "Link copiato: ";
L["LINKDESC"] = "In caso di errore, il profilo del giocatore potrebbe non esistere ancora sul sito\n(nessuno ne ha mai chiesto la scansione) e potresti doverlo cercare manualmente.";

L["ARMORY"] = "Armeria di WoW";
L["CHECKPVP"] = "Check PvP";
L["RAIDERIO"] = "Raider IO";
L["WARCRAFTLOGS"] = "Warcraft Logs";
L["WOWPROGRESS"] = "WoWProgress";
