local addonName, ns = ...;
local L = ns.L;

local REALMS = ns.realmsNames;
local REALMSDATA = ns.realmsData;
local REGIONID = GetCurrentRegion();
local regionName;

local realmsSimplifiedNameByName = {};
local LINKS_LIST = {"ARMORY", "CHECKPVP", "RAIDERIO", "WARCRAFTLOGS", "WOWPROGRESS"};
local LINKS = {
    ["ARMORY"] = "https://worldofwarcraft.com/%regionLocale%/character/%region%/%realmLower%/%name%",
    ["RAIDERIO"] = "https://raider.io/characters/%region%/%realmLower%/%name%",
    ["CHECKPVP"] = "https://check-pvp.com/%region%/%realmSimplified%/%name%",
    ["WOWPROGRESS"] = "https://www.wowprogress.com/character/%region%/%realmLower%/%name%",
    ["WARCRAFTLOGS"] = "https://www.warcraftlogs.com/character/%region%/%realmLower%/%name%"
};

for _, realmData in pairs(REALMSDATA) do
    local realmOriginalName, _, realmSimplifiedName = strsplit(",", realmData);
    if realmSimplifiedName ~= nil then
        realmsSimplifiedNameByName[realmOriginalName] = realmSimplifiedName;
    else
        realmsSimplifiedNameByName[realmOriginalName] = realmOriginalName;
    end
end

if REGIONID == 1 then
    regionName = "us";
elseif REGIONID == 2 then
    -- GetCurrentRegion() doesn't return the correct ID on TW servers (it returns KR region), so we check with local list
    local guid = UnitGUID("player");
    local realmID = tonumber(strmatch(guid, "^Player%-(%d+)"));

    if REALMSDATA[realmID] ~= nil then
        local _, region, _ = strsplit(",", string.lower(REALMSDATA[realmID]));
        regionName = region;
    else
        regionName = "kr";
    end
elseif REGIONID == 3 then
    regionName = "eu";
elseif REGIONID == 4 then
    regionName = "tw";
else
    regionName = "cn";
    return;
end

local ATLFrame;
local ATLFrameEditBox;
local ATLFrameEditBoxLabel;
local ATLFrameEditBoxDescription;

local function openLinkFrame(data)
    local name = data.name
    local realm = data.realm
    local site = data.site
    local link = "";

    if LINKS[site] == nil then
        return;
    else
        link = LINKS[site];
    end

    local realmNoSpace = string.gsub(realm, " ", "");
    local realmLowercase = REALMS[realmNoSpace];

    if (string.find(realmLowercase, "-")) then
        link = string.gsub(link, "%%realm%%", realm);
    else
        link = string.gsub(link, "%%realm%%", realm);
    end

    link = string.gsub(link, "%%realmLower%%", realmLowercase);

    if (realmsSimplifiedNameByName[realm]) then
        link = string.gsub(link, "%%realmSimplified%%", realmsSimplifiedNameByName[realm]);
    end

    link = string.gsub(link, " ", "%%20");

    -- Region locale (format "xx-xx", e.g "en-us")
    local locale = string.lower(GetLocale());
    locale = string.sub(locale, 0, 2) .. "-" .. string.sub(locale, 3);
    link = string.gsub(link, "%%regionLocale%%", locale);

    -- Region (format "xx", e.g "eu")
    link = string.gsub(link, "%%region%%", regionName);

    -- Name
    link = string.gsub(link, "%%name%%", name);

    -- Creating the frame
    if ATLFrame == nil then

        ATLFrame = CreateFrame("Frame", "ATLEditBox", UIParent, "DialogBoxFrame");
        ATLFrame:SetPoint("CENTER");
        ATLFrame:SetSize(600, 180);

        ATLFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight",
            edgeSize = 16,
            insets = { left = 8, right = 6, top = 8, bottom = 8 },
        })
        ATLFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.6);

        -- EditBox
        ATLFrameEditBox = CreateFrame("EditBox", "ATLEditBoxInputBox", ATLEditBox, "InputBoxTemplate");
        ATLFrameEditBox:SetWidth(500);
        ATLFrameEditBox:SetHeight(40);
        ATLFrameEditBox:SetPoint("CENTER", 0, 0);
        ATLFrameEditBox:SetAutoFocus(true);
        ATLFrameEditBox:SetText(link);
        ATLFrameEditBox:HighlightText();
        ATLFrameEditBox:SetScript("OnEscapePressed", function() ATLFrame:Hide() end)
        ATLFrameEditBoxLabel = ATLFrameEditBox:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
        ATLFrameEditBoxLabel:SetText(L["LINKTO"] .. L[site]);
        ATLFrameEditBoxLabel:SetPoint("TOP", ATLFrameEditBox, "TOP", 0, 45);

        ATLFrameEditBoxDescription = ATLFrameEditBox:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
        ATLFrameEditBoxDescription:SetText(L["LINKDESC"]);
        ATLFrameEditBoxDescription:SetPoint("TOP", ATLFrameEditBox, "TOP", 0, 25);
        ATLFrameEditBoxDescription:SetWordWrap(true);
        ATLFrameEditBoxDescription:SetNonSpaceWrap(true);
        ATLFrameEditBoxDescription:SetTextColor(1, 1, 1, 1);

        ATLFrame:Show();
    else
        ATLFrameEditBox:SetText(link);
        ATLFrameEditBox:HighlightText();
        ATLFrameEditBoxLabel:SetText(L["LINKTO"] .. L[site]);
        ATLFrame:Show();
    end

    tinsert(UISpecialFrames, ATLFrame:GetName());
end

local function AddATLMenu(ownerRegion, rootDescription, contextData)
    -- Append a new section to the end of the menu.
    rootDescription:CreateDivider()
    rootDescription:CreateTitle(addonName)

    local submenu = rootDescription:CreateButton(L["TITLE"])

    for _, value in pairs(LINKS_LIST) do
        submenu:CreateButton(L[value], openLinkFrame, {name = contextData.name, realm = contextData.server or GetRealmName(), site = value})
    end
end

Menu.ModifyMenu("MENU_UNIT_SELF", AddATLMenu)
Menu.ModifyMenu("MENU_UNIT_PLAYER", AddATLMenu)
Menu.ModifyMenu("MENU_UNIT_ENEMY_PLAYER", AddATLMenu)
Menu.ModifyMenu("MENU_UNIT_FRIEND", AddATLMenu)
Menu.ModifyMenu("MENU_UNIT_COMMUNITIES_WOW_MEMBER", AddATLMenu)
Menu.ModifyMenu("MENU_UNIT_COMMUNITIES_GUILD_MEMBER", AddATLMenu)
