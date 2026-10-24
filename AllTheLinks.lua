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

-- Site icons (the sites' favicons), shown before each link in the menu
local ICONS = {
    ["ARMORY"] = "armory",
    ["CHECKPVP"] = "checkpvp",
    ["RAIDERIO"] = "raiderio",
    ["WARCRAFTLOGS"] = "warcraftlogs",
    ["WOWPROGRESS"] = "wowprogress",
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

-- The link popup: a dark panel with a thin edge, a soft glow along its top, the site's icon and
-- name as its title, and the link in a flat field selected for copying.
local COLORS = {
    body = { 0.07, 0.07, 0.075, 0.95 },
    edge = { 0.8, 0.8, 0.8, 0.3 },
    glow = { 0.7, 0.7, 0.72, 0.1 },
    field = { 0.13, 0.13, 0.14, 1 },
    fieldFocus = { 0.17, 0.17, 0.18, 1 },
    fieldEdge = { 0.85, 0.85, 0.85 },
    title = { 1, 1, 1 },
    text = { 0.95, 0.95, 0.95 },
    muted = { 0.62, 0.62, 0.64 },
    close = { 0.75, 0.75, 0.75 },
};
-- How strong the field's edge is while idle, under the pointer and focused
local FIELD_EDGE_ALPHA = { idle = 0.25, hover = 0.5, focus = 0.9 };
local WIDTH, PADDING, HEADER, FIELD_HEIGHT = 560, 20, 22, 28;

local ATLFrame;
local ATLTitle;
local ATLIcon;
local ATLDescription;
local ATLHint;
local ATLField;

-- A font of the given size, copied from one of the game's fonts so every alphabet keeps its glyphs
local function createFont(name, base, size, color, shadow)
    local font = CreateFont(name);
    font:CopyFontObject(base);
    local file, _, flags = base:GetFont();
    font:SetFont(file, size, flags);
    font:SetTextColor(color[1], color[2], color[3], 1);
    if shadow then
        font:SetShadowColor(0, 0, 0, 0.85);
        font:SetShadowOffset(1, -1);
    else
        font:SetShadowOffset(0, 0);
    end
    return font;
end

-- A one pixel line along each side of a frame, drawn inside it
local function createEdges(frame, r, g, b, a)
    local edges = {};
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local line = frame:CreateTexture(nil, "BORDER");
        line:SetColorTexture(r, g, b, 1);
        line:SetAlpha(a);
        if side == "TOP" or side == "BOTTOM" then
            line:SetPoint(side .. "LEFT");
            line:SetPoint(side .. "RIGHT");
            line:SetHeight(1);
        else
            line:SetPoint("TOP" .. side);
            line:SetPoint("BOTTOM" .. side);
            line:SetWidth(1);
        end
        edges[side] = line;
    end
    return edges;
end

local function setEdgesAlpha(edges, a)
    for _, line in pairs(edges) do
        line:SetAlpha(a);
    end
end

-- Ctrl+C (Cmd+C on Mac) copies the selected link (the game does that itself: addons can't use the
-- clipboard), then the frame closes on the next frame, once the copy is done.
local function onFieldKeyDown(self, key)
    if key == "C" and (IsControlKeyDown() or IsMetaKeyDown()) then
        local link = self:GetText();
        C_Timer.After(0, function()
            ATLFrame:Hide();
            print("|cff33ff99" .. addonName .. "|r " .. L["LINKCOPIED"] .. link);
        end);
    end
end

local function updateField()
    local state = ATLField:HasFocus() and "focus" or (ATLField:IsMouseOver() and "hover" or "idle");
    local fill = state == "focus" and COLORS.fieldFocus or COLORS.field;
    ATLField.fill:SetColorTexture(fill[1], fill[2], fill[3], fill[4]);
    setEdgesAlpha(ATLField.edges, FIELD_EDGE_ALPHA[state]);
end

local function createLinkFrame()
    local titleFont = createFont("ATLFontTitle", GameFontNormal, 16, COLORS.title, true);
    local textFont = createFont("ATLFontText", GameFontNormal, 12, COLORS.text, false);
    local mutedFont = createFont("ATLFontMuted", GameFontNormal, 12, COLORS.muted, false);
    local smallFont = createFont("ATLFontSmall", GameFontNormal, 11, COLORS.muted, false);

    ATLFrame = CreateFrame("Frame", "ATLLinkFrame", UIParent);
    ATLFrame:SetFrameStrata("DIALOG");
    ATLFrame:SetToplevel(true);
    ATLFrame:SetClampedToScreen(true);
    ATLFrame:SetWidth(WIDTH);
    ATLFrame:SetPoint("CENTER", 0, 120);
    ATLFrame:EnableMouse(true);
    ATLFrame:SetMovable(true);
    ATLFrame:RegisterForDrag("LeftButton");
    ATLFrame:SetScript("OnDragStart", ATLFrame.StartMoving);
    ATLFrame:SetScript("OnDragStop", ATLFrame.StopMovingOrSizing);
    ATLFrame:Hide();

    local body = ATLFrame:CreateTexture(nil, "BACKGROUND");
    body:SetAllPoints();
    body:SetColorTexture(unpack(COLORS.body));

    -- The glow along the top, fading out downwards
    local glow = ATLFrame:CreateTexture(nil, "BACKGROUND", nil, 1);
    glow:SetPoint("TOPLEFT");
    glow:SetPoint("TOPRIGHT");
    glow:SetHeight(80);
    glow:SetColorTexture(1, 1, 1, 1);
    glow:SetBlendMode("ADD");
    local g = COLORS.glow;
    glow:SetGradient("VERTICAL", CreateColor(g[1], g[2], g[3], 0), CreateColor(g[1], g[2], g[3], g[4]));

    local e = COLORS.edge;
    createEdges(ATLFrame, e[1], e[2], e[3], e[4]);

    -- Header: the site's icon and the title, the close button on the right
    ATLIcon = ATLFrame:CreateTexture(nil, "ARTWORK");
    ATLIcon:SetSize(HEADER, HEADER);
    ATLIcon:SetPoint("TOPLEFT", PADDING, -PADDING);

    -- The close button: an X drawn with two lines, lighter under the pointer
    local close = CreateFrame("Button", nil, ATLFrame);
    close:SetSize(20, 20);
    close:SetPoint("TOPRIGHT", -12, -12);
    local cross = {};
    for i, corners in ipairs({ { "TOPLEFT", "BOTTOMRIGHT" }, { "BOTTOMLEFT", "TOPRIGHT" } }) do
        local line = close:CreateLine(nil, "ARTWORK");
        line:SetThickness(1.5);
        line:SetStartPoint(corners[1], close, 5, corners[1] == "TOPLEFT" and -5 or 5);
        line:SetEndPoint(corners[2], close, -5, corners[2] == "BOTTOMRIGHT" and 5 or -5);
        cross[i] = line;
    end
    local function colorCross(color)
        for _, line in ipairs(cross) do
            line:SetColorTexture(color[1], color[2], color[3], 1);
        end
    end
    colorCross(COLORS.close);
    close:SetScript("OnEnter", function() colorCross(COLORS.title) end);
    close:SetScript("OnLeave", function() colorCross(COLORS.close) end);
    close:SetScript("OnClick", function() ATLFrame:Hide() end);

    ATLTitle = ATLFrame:CreateFontString(nil, "ARTWORK");
    ATLTitle:SetFontObject(titleFont);
    ATLTitle:SetPoint("LEFT", ATLIcon, "RIGHT", 8, 0);
    ATLTitle:SetPoint("RIGHT", close, "LEFT", -8, 0);
    ATLTitle:SetJustifyH("LEFT");
    ATLTitle:SetWordWrap(false);

    ATLDescription = ATLFrame:CreateFontString(nil, "ARTWORK");
    ATLDescription:SetFontObject(mutedFont);
    ATLDescription:SetPoint("TOPLEFT", ATLIcon, "BOTTOMLEFT", 0, -12);
    ATLDescription:SetWidth(WIDTH - PADDING * 2);
    ATLDescription:SetJustifyH("LEFT");
    ATLDescription:SetSpacing(2);
    ATLDescription:SetText(L["LINKDESC"]);

    -- The link, in a flat field: lighter than the panel, its edge brighter under the pointer and
    -- while focused
    ATLField = CreateFrame("EditBox", "ATLLinkFrameField", ATLFrame);
    ATLField:SetHeight(FIELD_HEIGHT);
    ATLField:SetPoint("TOPLEFT", ATLDescription, "BOTTOMLEFT", 0, -14);
    ATLField:SetPoint("RIGHT", -PADDING, 0);
    ATLField:SetFontObject(textFont);
    ATLField:SetTextInsets(8, 8, 0, 0);
    ATLField:SetAutoFocus(true);
    ATLField.fill = ATLField:CreateTexture(nil, "BACKGROUND");
    ATLField.fill:SetAllPoints();
    local fe = COLORS.fieldEdge;
    ATLField.edges = createEdges(ATLField, fe[1], fe[2], fe[3], FIELD_EDGE_ALPHA.idle);
    ATLField:SetScript("OnEscapePressed", function() ATLFrame:Hide() end);
    ATLField:SetScript("OnKeyDown", onFieldKeyDown);
    ATLField:SetScript("OnEnter", updateField);
    ATLField:SetScript("OnLeave", updateField);
    ATLField:SetScript("OnEditFocusGained", function(self)
        self:HighlightText();
        updateField();
    end);
    ATLField:SetScript("OnEditFocusLost", updateField);
    updateField();

    ATLHint = ATLFrame:CreateFontString(nil, "ARTWORK");
    ATLHint:SetFontObject(smallFont);
    ATLHint:SetPoint("TOPLEFT", ATLField, "BOTTOMLEFT", 0, -8);
    ATLHint:SetText(L["COPYHINT"]);

    -- A short fade in when it opens
    local fadeIn = ATLFrame:CreateAnimationGroup();
    local alpha = fadeIn:CreateAnimation("Alpha");
    alpha:SetFromAlpha(0);
    alpha:SetToAlpha(1);
    alpha:SetDuration(0.15);
    alpha:SetSmoothing("OUT");
    ATLFrame:SetScript("OnShow", function() fadeIn:Play() end);

    tinsert(UISpecialFrames, ATLFrame:GetName());
end

local function showLinkFrame(site, link)
    if ATLFrame == nil then
        createLinkFrame();
    end

    ATLIcon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\images\\" .. ICONS[site] .. ".png");
    ATLTitle:SetText(L["LINKTO"] .. L[site]);
    ATLField:SetText(link);
    ATLField:SetCursorPosition(0);

    -- As tall as what it holds: header, description, field and hint, with the padding around them
    ATLFrame:SetHeight(PADDING + HEADER + 12 + ATLDescription:GetStringHeight() + 14 + FIELD_HEIGHT + 8
        + ATLHint:GetStringHeight() + PADDING);
    ATLFrame:Show();
    ATLField:SetFocus();
    ATLField:HighlightText();
end

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

    showLinkFrame(site, link);
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
        local label = "|TInterface\\AddOns\\" .. addonName .. "\\images\\" .. ICONS[value] .. ".png:16:16|t " .. L[value];
        submenu:CreateButton(label, openLinkFrame, {name = name, realm = server, site = value})
    end
end

for _, menu in ipairs(MENUS) do
    Menu.ModifyMenu("MENU_UNIT_" .. menu, AddATLMenu)
end
