local addonName, ns = ...;
local L = ns.L;

local REALMS = ns.realmsNames;
local REALMSDATA = ns.realmsData;

local LINKS_LIST = {"ARMORY", "CHECKPVP", "RAIDERIO", "WARCRAFTLOGS", "WOWPROGRESS"};
local LINKS = {
    ["ARMORY"] = "https://worldofwarcraft.com/%regionLocale%/character/%region%/%realmLower%/%name%",
    ["RAIDERIO"] = "https://raider.io/characters/%region%/%realmLower%/%name%",
    ["CHECKPVP"] = "https://check-pvp.com/%region%/%realmSimplified%/%name%",
    ["WOWPROGRESS"] = "https://www.wowprogress.com/character/%region%/%realmLower%/%name%",
    ["WARCRAFTLOGS"] = "https://www.warcraftlogs.com/character/%region%/%realmLower%/%name%"
};

-- Unit menus the links are added to (Blizzard's UnitPopup menus, tagged "MENU_UNIT_<menu>")
local MENUS = {
    "SELF", "PLAYER", "ENEMY_PLAYER", "FOCUS", "PARTY", "RAID_PLAYER", "RAID", "ARENAENEMY",
    "FRIEND", "FRIEND_OFFLINE", "GUILD", "GUILD_OFFLINE", "RECENT_ALLY", "RECENT_ALLY_OFFLINE",
    "CHAT_ROSTER", "PVP_SCOREBOARD", "COMMUNITIES_WOW_MEMBER", "COMMUNITIES_GUILD_MEMBER",
};

-- Realm names as Blizzard gives them for other realms have no spaces ("AeriePeak"), so every
-- realm lookup is keyed by the name without spaces. The realm data's third field, when present,
-- is the realm's English name (EU, KR, TW and CN realms with localized names).
local realmsSimplifiedNameByName = {};

for _, realmData in pairs(REALMSDATA) do
    local realmOriginalName, _, realmSimplifiedName = strsplit(",", realmData);
    realmsSimplifiedNameByName[(string.gsub(realmOriginalName, " ", ""))] = realmSimplifiedName or realmOriginalName;
end

local regionName;

-- Region name, read the first time a menu opens (once the player is in the world), nil in China
-- where the sites have no profiles.
local function getRegionName()
    if regionName ~= nil then
        return regionName;
    end

    local regionID = GetCurrentRegion();

    if regionID == 1 then
        regionName = "us";
    elseif regionID == 2 then
        -- GetCurrentRegion() doesn't return the correct ID on TW servers (it returns KR region), so we check with local list
        local guid = UnitGUID("player");
        local realmID = guid and tonumber(strmatch(guid, "^Player%-(%d+)"));

        if realmID and REALMSDATA[realmID] ~= nil then
            local _, region = strsplit(",", string.lower(REALMSDATA[realmID]));
            regionName = region;
        else
            regionName = "kr";
        end
    elseif regionID == 3 then
        regionName = "eu";
    elseif regionID == 4 then
        regionName = "tw";
    else
        regionName = "cn";
    end

    return regionName;
end

-- Realm slug used by the sites ("aerie-peak"): from the realm list, else made from the realm's
-- name (apostrophes removed, spaces and parentheses as hyphens), which matches every realm of the
-- list with a latin name.
local function getRealmSlug(realm)
    local slug = REALMS[(string.gsub(realm, " ", ""))];

    if slug ~= nil then
        return slug;
    end

    slug = string.gsub(realm, "'", "");
    slug = string.gsub(slug, "[%s%(%)]+", "-");
    slug = string.gsub(slug, "%-+", "-");
    slug = string.gsub(slug, "^%-", "");
    slug = string.gsub(slug, "%-$", "");

    return string.lower(slug);
end

local ATLFrame;
local ATLFrameEditBox;
local ATLFrameEditBoxLabel;
local ATLFrameEditBoxDescription;

local function openLinkFrame(data)
    local name = data.name
    local realm = data.realm
    local site = data.site
    local link = LINKS[site];

    if link == nil then
        return;
    end

    -- Values are inserted with a replacement function so a "%" in them is never read as a pattern
    link = string.gsub(link, "%%realmLower%%", function() return getRealmSlug(realm) end);
    link = string.gsub(link, "%%realmSimplified%%", function()
        return realmsSimplifiedNameByName[(string.gsub(realm, " ", ""))] or realm;
    end);

    link = string.gsub(link, " ", "%%20");

    -- Region locale (format "xx-xx", e.g "en-us")
    local locale = string.lower(GetLocale());
    locale = string.sub(locale, 0, 2) .. "-" .. string.sub(locale, 3);
    link = string.gsub(link, "%%regionLocale%%", locale);

    -- Region (format "xx", e.g "eu")
    link = string.gsub(link, "%%region%%", getRegionName());

    -- Name
    link = string.gsub(link, "%%name%%", function() return name end);

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
        ATLFrameEditBox = CreateFrame("EditBox", "ATLEditBoxInputBox", ATLFrame, "InputBoxTemplate");
        ATLFrameEditBox:SetWidth(500);
        ATLFrameEditBox:SetHeight(40);
        ATLFrameEditBox:SetPoint("CENTER", 0, 0);
        ATLFrameEditBox:SetAutoFocus(true);
        ATLFrameEditBox:SetScript("OnEscapePressed", function() ATLFrame:Hide() end)
        ATLFrameEditBoxLabel = ATLFrameEditBox:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
        ATLFrameEditBoxLabel:SetPoint("TOP", ATLFrameEditBox, "TOP", 0, 45);

        ATLFrameEditBoxDescription = ATLFrameEditBox:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
        ATLFrameEditBoxDescription:SetText(L["LINKDESC"]);
        ATLFrameEditBoxDescription:SetPoint("TOP", ATLFrameEditBox, "TOP", 0, 25);
        ATLFrameEditBoxDescription:SetWordWrap(true);
        ATLFrameEditBoxDescription:SetNonSpaceWrap(true);
        ATLFrameEditBoxDescription:SetTextColor(1, 1, 1, 1);

        tinsert(UISpecialFrames, ATLFrame:GetName());
    end

    ATLFrameEditBox:SetText(link);
    ATLFrameEditBox:HighlightText();
    ATLFrameEditBoxLabel:SetText(L["LINKTO"] .. L[site]);
    ATLFrame:Show();
end

local function isSecret(value)
    return issecretvalue ~= nil and issecretvalue(value);
end

local function AddATLMenu(ownerRegion, rootDescription, contextData)
    if contextData == nil or getRegionName() == "cn" then
        return;
    end

    local name, server = contextData.name, contextData.server;

    -- Names of restricted units are secret values (patch 12.0), which addons can't read
    if isSecret(name) or isSecret(server) or type(name) ~= "string" or name == "" then
        return;
    end

    -- Only players have profiles (the focus menu also opens on NPCs)
    if contextData.unit and not UnitIsPlayer(contextData.unit) then
        return;
    end

    if type(server) ~= "string" or server == "" then
        server = GetRealmName();
    end

    -- Append a new section to the end of the menu.
    rootDescription:CreateDivider()
    rootDescription:CreateTitle(addonName)

    local submenu = rootDescription:CreateButton(L["TITLE"])

    for _, value in ipairs(LINKS_LIST) do
        submenu:CreateButton(L[value], openLinkFrame, {name = name, realm = server, site = value})
    end
end

for _, menu in ipairs(MENUS) do
    Menu.ModifyMenu("MENU_UNIT_" .. menu, AddATLMenu)
end
