if(GetLocale() ~= 'koKR') then
    return
end

local _, ns = ...
local L = ns.L

L["TITLE"] = "All the links";
L["LINKTO"] = "링크: ";
L["COPYHINT"] = "Ctrl+C를 눌러 링크를 복사하고 이 창을 닫으세요.";
L["LINKCOPIED"] = "링크 복사됨: ";
L["LINKDESC"] = "오류가 발생하면 해당 플레이어의 프로필이 아직 웹사이트에 없을 수 있습니다\n(아무도 스캔을 요청하지 않음). 직접 검색해야 할 수도 있습니다.";

L["ARMORY"] = "WoW 전투정보실";
L["CHECKPVP"] = "Check PvP";
L["RAIDERIO"] = "Raider IO";
L["WARCRAFTLOGS"] = "Warcraft Logs";
L["WOWPROGRESS"] = "WoWProgress";
