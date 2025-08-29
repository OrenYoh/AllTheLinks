local L, _, ns = {}, ...;

ns.L = setmetatable(L,{__index=function(t,k)
    local v = tostring(k);
    rawset(t,k,v);
    return v;
end});

L["TITLE"] = "All the links";
L["LINKTO"] = "Link to: ";
L["LINKDESC"] = "If you have an error, the player's profile may not exist yet on the website\n(no one ever asked for that profile to be scanned), and you may have to look for it manually.";

L["ARMORY"] = "WoW Armory";
L["CHECKPVP"] = "Check PvP";
L["RAIDERIO"] = "Raider IO";
L["WARCRAFTLOGS"] = "Warcraft Logs";
L["WOWPROGRESS"] = "WoWProgress";
