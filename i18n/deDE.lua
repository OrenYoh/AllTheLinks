if(GetLocale() ~= 'deDE') then
    return
end

local _, ns = ...
local L = ns.L

L["TITLE"] = "All the links";
L["LINKTO"] = "Link zu: ";
L["COPYHINT"] = "Drücke Strg+C, um den Link zu kopieren und dieses Fenster zu schließen.";
L["LINKCOPIED"] = "Link kopiert: ";
L["LINKDESC"] = "Bei einem Fehler existiert das Profil des Spielers auf der Website vielleicht noch nicht\n(niemand hat es je scannen lassen) und du musst es eventuell manuell suchen.";

L["ARMORY"] = "WoW-Arsenal";
L["CHECKPVP"] = "Check PvP";
L["RAIDERIO"] = "Raider IO";
L["WARCRAFTLOGS"] = "Warcraft Logs";
L["WOWPROGRESS"] = "WoWProgress";
