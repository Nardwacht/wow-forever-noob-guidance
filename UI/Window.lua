local _, ING = ...

-- The full window: filters at the top, then the quest sections, then the
-- guide (zones and dungeons for your level) and a beginner tip.

local WIDTH, HEIGHT = 460, 560
local ROW_HEIGHT, HEADER_HEIGHT = 34, 26

local window, content, scroll
local rows, headers, texts = {}, {}, {}

local function ApplyBackdrop(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end
end
ING.ApplyBackdrop = ApplyBackdrop

-- ============================================================
-- Shared quest helpers (used by the panel too)
-- ============================================================

function ING.QuestLevelColor(level)
    if GetQuestDifficultyColor then
        local c = GetQuestDifficultyColor(level)
        if c then return ("|cff%02x%02x%02x"):format(c.r * 255, c.g * 255, c.b * 255) end
    end
    return "|cffffffff"
end

function ING.QuestLine(item)
    local cat = ING.CATEGORY[item.category]
    local tag = cat.label and (" " .. cat.color .. "[" .. cat.label .. "]|r") or ""
    return ("%s[%d]|r %s%s"):format(ING.QuestLevelColor(item.level), item.level, item.name, tag)
end

function ING.StarterLine(item)
    local who
    if item.starterKind == "item" then
        who = "Starts from an item you loot"
    elseif item.starterName then
        who = item.starterName
    else
        who = "Quest giver unknown"
    end
    local where = ""
    if item.coord then
        where = (" (%.0f, %.0f)"):format(item.coord[1], item.coord[2])
    end
    local distance = ""
    if item.distance then
        distance = item.distance < 3 and "  |cff33ff33nearby|r" or ("  |cffaaaaaa~%d%% of the map away|r"):format(item.distance)
    end
    return who .. where .. distance
end

function ING.ShowQuestTooltip(owner, item)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(item.name, 1, 0.82, 0)
    GameTooltip:AddLine(("Quest level %d, you can take it from level %d"):format(item.level, item.req or 1), 1, 1, 1)
    local cat = ING.CATEGORY[item.category]
    if cat.label then
        local hint = {
            Dungeon = "Done inside a dungeon. You need a group of five.",
            Raid = "Done inside a raid. You need a big group.",
            Elite = "Hard enemies. Bring a friend or two.",
            Class = "Only for your class. Often rewards a useful spell or item.",
            Profession = "Needs a profession.",
        }
        GameTooltip:AddLine(cat.label .. ": " .. (hint[cat.label] or ""), 0.6, 0.8, 1, true)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Quest giver: " .. ING.StarterLine(item), 0.9, 0.9, 0.9, true)
    GameTooltip:AddLine("Zone: " .. ING.ZoneName(item.zoneId), 0.9, 0.9, 0.9)
    local objectives = ING.Scanner.Objectives(item.id)
    if type(objectives) == "table" and #objectives > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Objective:", 1, 0.82, 0)
        for _, line in ipairs(objectives) do
            GameTooltip:AddLine(line, 1, 1, 1, true)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Click: show the quest giver on the world map", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

-- Opens the world map on the quest giver's zone and, when TomTom is
-- installed, also sets a waypoint arrow.
function ING.ShowOnMap(item)
    local uiMap = ING.Scanner.UiMapForArea(item.areaId) or ING.Scanner.UiMapForArea(item.zoneId)
    if item.coord and uiMap and _G.TomTom and _G.TomTom.AddWaypoint then
        _G.TomTom:AddWaypoint(uiMap, item.coord[1] / 100, item.coord[2] / 100, { title = item.name })
    end
    if uiMap then
        if not WorldMapFrame:IsShown() then
            ToggleWorldMap()
        end
        WorldMapFrame:SetMapID(uiMap)
    end
    if item.coord then
        ING.Print(("%s: %s in %s"):format(item.name, ING.StarterLine(item), ING.ZoneName(item.zoneId)))
    end
end

-- ============================================================
-- Coach tips (used by the panel too)
-- ============================================================

-- Coach tips use the shared severity colours: red = act now, orange = soon,
-- yellow = tip.
local SEVERITY_ICON = {
    urgent = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:14|t ",
    warn = "|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:14|t ",
    tip = "|TInterface\\Common\\help-i:16|t ",
}

function ING.CoachTitle(tip)
    local severity = ING.SEVERITY[tip.kind] and tip.kind or "tip"
    return (SEVERITY_ICON[severity] or "") .. ING.Colorize(severity, tip.title)
end

function ING.ShowCoachTooltip(owner, tip)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local severity = ING.SEVERITY[tip.kind] and tip.kind or "tip"
    GameTooltip:AddLine(ING.Colorize(severity, tip.title) .. "  " .. ING.Colorize("info", "(" .. ING.SEVERITY[severity].label .. ")"))
    GameTooltip:AddLine(tip.detail, 1, 1, 1, true)
    if tip.help then
        GameTooltip:AddLine(" ")
        for _, line in ipairs(tip.help) do
            GameTooltip:AddLine(line, 0.6, 0.8, 1, true)
        end
    end
    GameTooltip:AddLine(" ")
    local hide = {
        level = "Right-click: hide until your next level",
        session = "Right-click: hide until you log out",
        forever = "Right-click: hide for good",
        spells = "Right-click: stop mentioning these spells",
    }
    GameTooltip:AddLine(hide[tip.snooze] or hide.forever, 0.5, 0.5, 0.5)
    GameTooltip:Show()
end

-- ============================================================
-- Rows
-- ============================================================

local coachRows = {}
local gearRows = {}
local gearToggle

local function GetGearRow(i)
    local row = gearRows[i]
    if row then return row end
    row = CreateFrame("Button", nil, content)
    row:SetHeight(18)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    -- Coloured bar on the left: the slot's severity at a glance.
    row.bar = row:CreateTexture(nil, "ARTWORK")
    row.bar:SetPoint("TOPLEFT", 2, -2)
    row.bar:SetPoint("BOTTOMLEFT", 2, 2)
    row.bar:SetWidth(3)
    row.left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.left:SetPoint("LEFT", 10, 0)
    row.left:SetJustifyH("LEFT")
    row.left:SetWordWrap(false)
    row.right = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.right:SetPoint("RIGHT", -8, 0)
    row.right:SetJustifyH("RIGHT")
    row.left:SetPoint("RIGHT", row.right, "LEFT", -6, 0)
    row:SetScript("OnEnter", function(self)
        if self.entry and self.entry.link then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetInventoryItem("player", self.entry.id)
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    gearRows[i] = row
    return row
end

-- Which slots to list when the gear section is folded: empty core slots,
-- the three weakest items, and anything badly worn.
local function NotableGear(gear, level)
    local weakest = {}
    for i = 1, math.min(3, #gear.slots) do weakest[gear.slots[i]] = true end
    local list = {}
    for _, entry in ipairs(gear.all) do
        local severity = ING.Coach.SlotStatus(entry, level)
        if severity == "urgent" or severity == "warn" or weakest[entry] then
            list[#list + 1] = entry
        end
    end
    return list
end

-- RGB for the coloured bars, matching ING.SEVERITY.
local SEVERITY_RGB = {
    urgent = { 1, 0.25, 0.25 }, warn = { 1, 0.6, 0.2 }, tip = { 1, 0.82, 0 },
    good = { 0.2, 1, 0.2 }, info = { 0.5, 0.5, 0.5 },
}

local function GearSummary(gear, level)
    if not gear then return "Your gear could not be read on this client." end
    if not gear.average then
        if gear.unknown > 0 then return "Item details are still loading, one moment..." end
        return "You have no armour or weapon equipped."
    end
    local verdict, behind = ING.Coach.GearVerdict(gear, level)
    local lines = { ("Average item level |cffffffff%d|r (armour and main weapon), you are level |cffffffff%d|r."):format(gear.average, level) }
    if verdict == "good" then
        lines[#lines + 1] = ING.Colorize("good", "Good for your level.")
    elseif verdict == "behind" then
        lines[#lines + 1] = ING.Colorize("warn", ("A little behind (%d levels)."):format(behind)) .. " Take quest rewards for your weakest slots."
    else
        lines[#lines + 1] = ING.Colorize("urgent", ("Far behind (%d levels)."):format(behind)) .. " The Coach tip above says where to upgrade."
    end
    if #gear.empty > 0 then
        lines[#lines + 1] = ING.Colorize("urgent", "Nothing equipped in: ") .. table.concat(gear.empty, ", ")
    end
    if gear.lowestDurability then
        local worn = gear.lowestDurability == 0 and "urgent" or gear.lowestDurability < 25 and "warn" or "good"
        lines[#lines + 1] = "Most worn item: " .. ING.Colorize(worn, ("%d%% durability"):format(gear.lowestDurability)) .. "."
    end
    lines[#lines + 1] = ING.Colorize("urgent", "red") .. " = upgrade advised, " .. ING.Colorize("warn", "orange")
        .. " = upgrade soon, " .. ING.Colorize("good", "green") .. " = fine"
    if level < 10 then
        lines[#lines + 1] = "|cffaaaaaaAt low levels gear changes fast: quest rewards keep you up to date.|r"
    end
    if gear.unknown > 0 then
        lines[#lines + 1] = ("|cffaaaaaa%d item(s) still loading.|r"):format(gear.unknown)
    end
    return table.concat(lines, "\n")
end

local function GetCoachRow(i)
    local row = coachRows[i]
    if row then return row end
    row = CreateFrame("Button", nil, content)
    row:RegisterForClicks("RightButtonUp")
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 8, -3)
    row.title:SetPoint("RIGHT", -8, 0)
    row.title:SetJustifyH("LEFT")
    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.detail:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
    row.detail:SetPoint("RIGHT", -8, 0)
    row.detail:SetJustifyH("LEFT")
    row:SetScript("OnEnter", function(self) ING.ShowCoachTooltip(self, self.tip) end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self)
        GameTooltip:Hide()
        ING.Coach.Dismiss(self.tip)
    end)
    coachRows[i] = row
    return row
end

local function GetRow(i)
    local row = rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, content)
    row:SetHeight(ROW_HEIGHT)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", 8, -3)
    row.title:SetPoint("RIGHT", -8, 0)
    row.title:SetJustifyH("LEFT")
    row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.sub:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
    row.sub:SetPoint("RIGHT", -8, 0)
    row.sub:SetJustifyH("LEFT")
    row:SetScript("OnEnter", function(self) ING.ShowQuestTooltip(self, self.item) end)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self) ING.ShowOnMap(self.item) end)
    rows[i] = row
    return row
end

local function GetHeader(i)
    local header = headers[i]
    if header then return header end
    header = CreateFrame("Frame", nil, content)
    header:SetHeight(HEADER_HEIGHT)
    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetAllPoints()
    header.bg:SetColorTexture(0.2, 0.5, 0.8, 0.25)
    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header.text:SetPoint("LEFT", 8, 0)
    header.text:SetPoint("RIGHT", -8, 0)
    header.text:SetJustifyH("LEFT")
    headers[i] = header
    return header
end

local function GetText(i)
    local text = texts[i]
    if text then return text end
    text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetJustifyH("LEFT")
    text:SetSpacing(2)
    texts[i] = text
    return text
end

-- ============================================================
-- Layout
-- ============================================================

local function Render(results)
    if not window or not window:IsShown() then return end
    for _, f in ipairs(rows) do f:Hide() end
    for _, f in ipairs(headers) do f:Hide() end
    for _, f in ipairs(texts) do f:Hide() end
    for _, f in ipairs(coachRows) do f:Hide() end
    for _, f in ipairs(gearRows) do f:Hide() end
    if gearToggle then gearToggle:Hide() end

    local width = scroll:GetWidth() - 4
    content:SetWidth(width)
    local y = 0
    local nRow, nHeader, nText, nCoach = 0, 0, 0, 0

    local function addHeader(label)
        nHeader = nHeader + 1
        local h = GetHeader(nHeader)
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", 0, -y)
        h:SetWidth(width)
        h.text:SetText(label)
        h:Show()
        y = y + HEADER_HEIGHT + 2
    end
    local function addText(label, font)
        nText = nText + 1
        local t = GetText(nText)
        t:SetFontObject(font or "GameFontHighlight")
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", 8, -y)
        t:SetWidth(width - 16)
        t:SetText(label)
        t:Show()
        y = y + t:GetStringHeight() + 8
    end
    local function addQuest(item)
        nRow = nRow + 1
        local row = GetRow(nRow)
        row.item = item
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetWidth(width)
        row.title:SetText(ING.QuestLine(item))
        row.sub:SetText(ING.StarterLine(item))
        row:Show()
        y = y + ROW_HEIGHT
    end
    local function addCoach(tip)
        nCoach = nCoach + 1
        local row = GetCoachRow(nCoach)
        row.tip = tip
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetWidth(width)
        row.title:SetText(ING.CoachTitle(tip))
        row.detail:SetWidth(width - 16)
        row.detail:SetText(tip.detail)
        local height = 8 + row.title:GetStringHeight() + row.detail:GetStringHeight()
        row:SetHeight(height)
        row:Show()
        y = y + height + 4
    end

    if not results then
        addText(ING.Scanner.IsIndexed() and "Working..." or "Reading the Questie database. This takes a few seconds after logging in...")
    else
        window.subtitle:SetText(("Level %d  |  %s  |  quests level %d-%d"):format(results.level, results.zoneName, math.max(1, results.low), results.high))

        if results.advice then
            addText("|cffff8040" .. results.advice .. "|r")
        end

        if ING.db.showCoach and results.coach and #results.coach > 0 then
            addHeader(("Coach  |cffffffff%d|r  |cffaaaaaa(hover for help, right-click to hide)|r"):format(#results.coach))
            for _, tip in ipairs(results.coach) do
                addCoach(tip)
            end
        end

        if ING.db.showCoach then
            local gear = ING.Coach.GetGear()
            addHeader("Your gear")
            addText(GearSummary(gear, results.level), "GameFontHighlightSmall")
            if gear and gear.average then
                local list = ING.db.gearExpanded and gear.all or NotableGear(gear, results.level)
                local nGear = 0
                for _, entry in ipairs(list) do
                    nGear = nGear + 1
                    local row = GetGearRow(nGear)
                    row.entry = entry
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", 0, -y)
                    row:SetWidth(width)
                    local severity, label = ING.Coach.SlotStatus(entry, results.level)
                    local itemText = entry.link or "|cff808080nothing equipped|r"
                    row.left:SetText(ING.Colorize(severity, entry.name .. ":") .. " " .. itemText)
                    local right = {}
                    if entry.level then
                        right[#right + 1] = ("|cffffffffilvl %d|r"):format(entry.level)
                    end
                    if entry.durability and entry.durability < 50 then
                        right[#right + 1] = ("%d%%"):format(entry.durability)
                    end
                    right[#right + 1] = ING.Colorize(severity, label)
                    row.right:SetText(table.concat(right, "  "))
                    local rgb = SEVERITY_RGB[severity] or SEVERITY_RGB.info
                    row.bar:SetColorTexture(rgb[1], rgb[2], rgb[3], 0.9)
                    row:Show()
                    y = y + 18
                end
                if not gearToggle then
                    gearToggle = CreateFrame("Button", nil, content)
                    gearToggle:SetHeight(18)
                    gearToggle.text = gearToggle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    gearToggle.text:SetPoint("LEFT", 8, 0)
                    gearToggle:SetScript("OnClick", function()
                        ING.db.gearExpanded = not ING.db.gearExpanded
                        Render(ING.results)
                    end)
                end
                gearToggle.text:SetText(ING.db.gearExpanded and "[ show only the weak slots ]" or "[ show every slot ]")
                gearToggle:ClearAllPoints()
                gearToggle:SetPoint("TOPLEFT", 0, -y)
                gearToggle:SetWidth(width)
                gearToggle:Show()
                y = y + 24
            end
        end

        if results.currentEmpty then
            addHeader(results.zoneName .. "  |cffaaaaaa(no quests left here)|r")
            if #results.sections > 0 then
                addText("You have done everything that fits your level in this zone. These are the closest zones that still have quests for you:")
            else
                addText("No nearby zone has quests for your level. Try the zones the guide suggests below.")
            end
        end

        for _, section in ipairs(results.sections) do
            local g = ING.Zones[section.zoneId]
            local range = (g and g.min) and ("  |cffaaaaaa(zone %d-%d)|r"):format(g.min, g.max) or ""
            addHeader(("%s  |cffffffff%d|r%s"):format(section.title, #section.items, range))
            if section.via then
                addText("|cff99ccffHow to get there:|r " .. section.via, "GameFontHighlightSmall")
            end
            for _, item in ipairs(section.items) do
                addQuest(item)
            end
        end

        addHeader("Guide: where to level at " .. results.level)
        if #results.guideZones == 0 then
            addText("No guide zones for this level.")
        end
        for _, z in ipairs(results.guideZones) do
            local count = z.count > 0 and ("|cff33ff33%d quests for you|r"):format(z.count) or "|cffaaaaaano quests for you right now|r"
            addText(("|cffffd100%s|r (%d-%d): %s\n%s"):format(z.name, z.min or 0, z.max or 0, count, z.tip or ""), "GameFontHighlightSmall")
        end

        if #results.dungeons > 0 then
            addHeader("Dungeons for your level")
            local lines = {}
            for _, d in ipairs(results.dungeons) do
                lines[#lines + 1] = ("|cff4fb0ff%s|r (%d-%d) - %s"):format(d.name, d.min, d.max, d.where)
            end
            addText(table.concat(lines, "\n"), "GameFontHighlightSmall")
        end

        if results.tip then
            addHeader("Tip")
            addText(results.tip)
        end
    end

    content:SetHeight(math.max(y, 1))
end

-- ============================================================
-- Frame
-- ============================================================

local function CreateCheck(parent, label, key, anchor, xOffset)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(22, 22)
    check:SetPoint("LEFT", anchor, "RIGHT", xOffset or 4, 0)
    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    check.label:SetPoint("LEFT", check, "RIGHT", 0, 1)
    check.label:SetText(label)
    check:SetScript("OnShow", function(self) self:SetChecked(ING.db[key]) end)
    check:SetScript("OnClick", function(self)
        ING.db[key] = self:GetChecked() and true or false
        ING.Refresh()
    end)
    return check
end

local function CreateWindow()
    window = CreateFrame("Frame", "ImpulsNoobGuidanceWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    window:SetSize(WIDTH, HEIGHT)
    window:SetPoint("CENTER", -200, 40)
    window:SetFrameStrata("HIGH")
    window:SetToplevel(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:SetResizable(true)
    if window.SetResizeBounds then
        window:SetResizeBounds(380, 300, 900, 1200)
    elseif window.SetMinResize then
        window:SetMinResize(380, 300)
    end
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    ApplyBackdrop(window)
    window:Hide()
    tinsert(UISpecialFrames, "ImpulsNoobGuidanceWindow") -- Escape closes it

    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -18)
    title:SetText("Impuls Noob Guidance")

    window.subtitle = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.subtitle:SetPoint("TOP", title, "BOTTOM", 0, -4)

    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    -- Filter row
    local filterLabel = window:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", 20, -58)
    filterLabel:SetText("Show:")
    local c1 = CreateCheck(window, "Dungeon", "showDungeon", filterLabel, 4)
    local c2 = CreateCheck(window, "Elite", "showElite", c1.label, 8)
    local c3 = CreateCheck(window, "Class & prof.", "showClassProf", c2.label, 8)
    CreateCheck(window, "Coach", "showCoach", c3.label, 8)

    scroll = CreateFrame("ScrollFrame", "ImpulsNoobGuidanceScroll", window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -82)
    scroll:SetPoint("BOTTOMRIGHT", -36, 34)
    content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WIDTH - 60, 1)
    scroll:SetScrollChild(content)

    local hint = window:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 20, 16)
    hint:SetText("/ing help for commands")

    local resize = CreateFrame("Button", nil, window)
    resize:SetSize(16, 16)
    resize:SetPoint("BOTTOMRIGHT", -8, 8)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetScript("OnMouseDown", function() window:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp", function()
        window:StopMovingOrSizing()
        Render(ING.results)
    end)

    window:SetScript("OnShow", function() Render(ING.results) end)
end

function ING.ToggleWindow()
    if not window then CreateWindow() end
    if window:IsShown() then
        window:Hide()
    else
        window:Show()
        ING.Refresh()
    end
end

ING.OnResults(function(results)
    Render(results)
end)
