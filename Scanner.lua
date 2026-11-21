local _, ING = ...

-- Builds the list of quests the player can pick up now.
--
-- Step 1 (once per session, spread over several frames): read every quest
-- from QuestieDB and remember where its quest giver stands, per zone.
-- Step 2 (on every refresh): keep the quests in the level window that
-- Questie says the player can still do, group them by zone and pick the
-- sections to show (current zone first, neighbours when it is empty).

local Scanner = {}
ING.Scanner = Scanner

local index          -- array of { id, level, req, zones = { [zoneAreaId] = starter } }
local buildRoutine
local normalizeCache = {}
local uiMapCache = {}

local QuestieDB, ZoneDB

local function DB()
    return _G.LibQuestieDB
end

local function ImportQuestieModules()
    if QuestieDB then return end
    local loader = _G.QuestieLoader
    if loader and loader.ImportModule then
        QuestieDB = loader:ImportModule("QuestieDB")
        ZoneDB = loader:ImportModule("ZoneDB")
    end
end

function Scanner.IsQuestieReady()
    local questie = _G.Questie
    return DB() ~= nil and questie ~= nil and questie.started == true
end

-- ============================================================
-- Zones
-- ============================================================

-- Sub-areas (a village, a cave, a dungeon) are folded into their zone so the
-- list groups by the zone name a beginner sees on the map.
local function NormalizeArea(areaId)
    if not areaId then return nil end
    local cached = normalizeCache[areaId]
    if cached then return cached end
    local result = areaId
    if ZoneDB and ZoneDB.GetParentZoneId then
        for _ = 1, 5 do
            local ok, parent = pcall(ZoneDB.GetParentZoneId, ZoneDB, result)
            if ok and parent and parent ~= result and parent > 0 then
                result = parent
            else
                break
            end
        end
    end
    normalizeCache[areaId] = result
    return result
end

local function UiMapForArea(areaId)
    local cached = uiMapCache[areaId]
    if cached ~= nil then return cached or nil end
    local uiMap
    if ZoneDB and ZoneDB.GetUiMapIdByAreaId then
        local ok, value = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, areaId)
        if ok and value and value > 0 then uiMap = value end
    end
    uiMapCache[areaId] = uiMap or false
    return uiMap
end
Scanner.UiMapForArea = UiMapForArea

function ING.ZoneName(areaId)
    if not areaId then return "Unknown zone" end
    local name = C_Map and C_Map.GetAreaInfo and C_Map.GetAreaInfo(areaId)
    if name and name ~= "" then return name end
    local guide = ING.Zones[areaId]
    return guide and guide.name or ("Zone " .. areaId)
end

-- The zone-level map the player is on (walks up from caves and dungeon floors).
local function PlayerZoneMap()
    local uiMap = C_Map.GetBestMapForUnit("player")
    for _ = 1, 5 do
        if not uiMap then return nil end
        local info = C_Map.GetMapInfo(uiMap)
        if not info then return uiMap end
        -- 3 = Zone; 4 Dungeon, 5 Micro and 6 Orphan sit below a zone.
        if info.mapType and info.mapType > 3 and info.parentMapID and info.parentMapID > 0 then
            uiMap = info.parentMapID
        else
            return uiMap
        end
    end
    return uiMap
end

local function PlayerArea()
    local uiMap = PlayerZoneMap()
    if not uiMap then return nil end
    local areaId
    if ZoneDB and ZoneDB.GetAreaIdByUiMapId then
        local ok, value = pcall(ZoneDB.GetAreaIdByUiMapId, ZoneDB, uiMap)
        if ok then areaId = value end
    end
    local x, y
    local pos = C_Map.GetPlayerMapPosition(uiMap, "player")
    if pos then
        x, y = pos:GetXY()
        if x then x, y = x * 100, y * 100 end
    end
    return NormalizeArea(areaId), uiMap, x, y
end

-- ============================================================
-- Step 1: index
-- ============================================================

local function AddSpawns(zones, spawns, name, kind)
    if type(spawns) ~= "table" then return end
    for areaId, coords in pairs(spawns) do
        local zoneId = NormalizeArea(areaId)
        if zoneId and zoneId > 0 and not zones[zoneId] then
            zones[zoneId] = { name = name, kind = kind, areaId = areaId, coords = coords }
        end
    end
end

local function IsFriendly(friendlyToFaction, factionLetter)
    -- Same rule as Questie: no faction data, or both factions, counts as friendly.
    return friendlyToFaction == nil or friendlyToFaction == "AH" or friendlyToFaction == factionLetter
end

local function BuildIndex()
    local lib = DB()
    local Quest, Npc, Object = lib.Quest, lib.Npc, lib.Object
    local factionLetter = ING.PlayerFactionLetter()
    local result = {}

    local ids = Quest.GetAllIds()
    for i, id in ipairs(ids) do
        local level = Quest.questLevel(id)
        local req = Quest.requiredLevel(id)
        if not level or level <= 0 then level = req end

        if level and level > 0 then
            local zones = {}
            local startedBy = Quest.startedBy(id)
            if startedBy then
                for _, npcId in ipairs(startedBy[1] or {}) do
                    if IsFriendly(Npc.friendlyToFaction(npcId), factionLetter) then
                        AddSpawns(zones, Npc.spawns(npcId), Npc.name(npcId), "npc")
                    end
                end
                for _, objectId in ipairs(startedBy[2] or {}) do
                    AddSpawns(zones, Object.spawns(objectId), Object.name(objectId), "object")
                end
            end
            -- Started by an item (a drop) or without location data: file it
            -- under the quest's own zone so it is not lost.
            if next(zones) == nil then
                local zoneOrSort = Quest.zoneOrSort(id)
                if zoneOrSort and zoneOrSort > 0 then
                    local zoneId = NormalizeArea(zoneOrSort)
                    zones[zoneId] = { kind = (startedBy and startedBy[3] and #startedBy[3] > 0) and "item" or "unknown", areaId = zoneOrSort }
                end
            end
            if next(zones) ~= nil then
                result[#result + 1] = { id = id, level = level, req = req, zones = zones }
            end
        end

        if i % 150 == 0 then
            coroutine.yield()
        end
    end
    return result
end

local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function(self)
    local ok, value = coroutine.resume(buildRoutine)
    if not ok then
        self:Hide()
        buildRoutine = nil
        ING.Print("could not read the Questie database:", tostring(value))
        return
    end
    if coroutine.status(buildRoutine) == "dead" then
        self:Hide()
        buildRoutine = nil
        index = value
        ING.Refresh()
    end
end)

function Scanner.StartIndex()
    if index or buildRoutine then return end
    if not DB() then
        ING.Print("QuestieDB is not loaded. Enable Questie and QuestieDB in the AddOns list.")
        return
    end
    ImportQuestieModules()
    buildRoutine = coroutine.create(BuildIndex)
    driver:Show()
end

function Scanner.IsIndexed()
    return index ~= nil
end

-- ============================================================
-- Step 2: filter
-- ============================================================

local function ActiveQuests()
    local active = {}
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
        local count = C_QuestLog.GetNumQuestLogEntries()
        for i = 1, count or 0 do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.questID then
                active[info.questID] = true
            end
        end
    elseif GetNumQuestLogEntries and GetQuestLogTitle then
        local count = GetNumQuestLogEntries()
        for i = 1, count or 0 do
            local _, _, _, isHeader, _, _, _, questId = GetQuestLogTitle(i)
            if not isHeader and questId then
                active[questId] = true
            end
        end
    end
    return active
end

local function IsCompletedFallback(id)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(id)
    end
    if IsQuestFlaggedCompleted then
        return IsQuestFlaggedCompleted(id)
    end
    return false
end

-- Questie's own check covers completed quests, race, class, reputation,
-- professions, pre-quests and breadcrumbs. Without it, a simpler check.
local function IsEligible(id)
    if QuestieDB and QuestieDB.IsDoable and Scanner.IsQuestieReady() then
        local ok, doable = pcall(QuestieDB.IsDoable, id)
        if ok then return doable end
    end
    if IsCompletedFallback(id) then return false end
    local lib = DB()
    local races = lib.Quest.requiredRaces(id)
    if races and races ~= 0 then
        local _, _, raceId = UnitRace("player")
        local mask = lib.Enum.raceMaskById and lib.Enum.raceMaskById[raceId]
        if mask and bit.band(races, mask) == 0 then return false end
    end
    local classes = lib.Quest.requiredClasses(id)
    if classes and classes ~= 0 then
        local _, _, classId = UnitClass("player")
        if classId and bit.band(classes, bit.lshift(1, classId - 1)) == 0 then return false end
    end
    return true
end

ING.CATEGORY = {
    normal     = { rank = 0, label = nil },
    class      = { rank = 1, label = "Class",      color = "|cfff58cba" },
    profession = { rank = 1, label = "Profession", color = "|cff8fd16c" },
    elite      = { rank = 2, label = "Elite",      color = "|cffffd100" },
    dungeon    = { rank = 3, label = "Dungeon",    color = "|cff4fb0ff" },
    raid       = { rank = 4, label = "Raid",       color = "|cffff8040" },
}

local function Categorize(id)
    local lib = DB()
    local tagId
    if QuestieDB and QuestieDB.GetQuestTagInfo then
        local ok, value = pcall(QuestieDB.GetQuestTagInfo, id)
        if ok then tagId = value end
    end
    local tags = QuestieDB and QuestieDB.questTagIds or {}
    if tagId and (tagId == tags.RAID or tagId == tags.RAID_10 or tagId == tags.RAID_25) then
        return "raid"
    end
    if tagId and tagId == tags.DUNGEON then
        return "dungeon"
    end
    local zoneOrSort = lib.Quest.zoneOrSort(id)
    if zoneOrSort and zoneOrSort > 0 and ZoneDB and ZoneDB.IsDungeonZone and ZoneDB.IsDungeonZone(zoneOrSort) then
        return "dungeon"
    end
    if tagId and tagId == tags.ELITE then
        return "elite"
    end
    local skill = lib.Quest.requiredSkill(id)
    if skill and skill[1] and skill[1] > 0 then
        return "profession"
    end
    local classes = lib.Quest.requiredClasses(id)
    local all = lib.Enum.classKeys and lib.Enum.classKeys.ALL_CLASSES
    if classes and classes ~= 0 and classes ~= all then
        return "class"
    end
    return "normal"
end

local function CategoryAllowed(category)
    local db = ING.db
    if category == "dungeon" or category == "raid" then return db.showDungeon end
    if category == "elite" then return db.showElite end
    if category == "class" or category == "profession" then return db.showClassProf end
    return true
end

local function NearestCoord(starter, playerMap, px, py)
    local coords = starter.coords
    if type(coords) ~= "table" then return nil, nil end
    local best, bestDist
    local sameMap = px and playerMap and UiMapForArea(starter.areaId) == playerMap
    for _, c in ipairs(coords) do
        local x, y = c[1], c[2]
        if x and y and x >= 0 and y >= 0 then
            if not sameMap then
                return c, nil
            end
            local dist = (x - px) ^ 2 + (y - py) ^ 2
            if not bestDist or dist < bestDist then
                best, bestDist = c, dist
            end
        end
    end
    return best, bestDist and math.sqrt(bestDist) or nil
end

local function SortItems(items)
    table.sort(items, function(a, b)
        local ra, rb = ING.CATEGORY[a.category].rank, ING.CATEGORY[b.category].rank
        if ra ~= rb then return ra < rb end
        if a.distance and b.distance and a.distance ~= b.distance then return a.distance < b.distance end
        if a.distance and not b.distance then return true end
        if b.distance and not a.distance then return false end
        if a.level ~= b.level then return a.level < b.level end
        return a.name < b.name
    end)
end

-- Neighbour search: breadth first from the current zone; stops at the first
-- ring of zones that still has quests.
local function FindNeighbourSections(startZone, byZone)
    local guide = ING.Zones[startZone]
    if not guide then return {} end

    local visited = { [startZone] = true }
    local frontier = {}
    local function push(list, zoneId, via)
        if not visited[zoneId] then
            visited[zoneId] = true
            list[#list + 1] = { zoneId = zoneId, via = via }
        end
    end
    for _, n in ipairs(guide.neighbours or {}) do
        push(frontier, n[1], n[2])
    end
    -- A city falls back to the zone it sits in, and that zone's neighbours.
    if guide.city then
        push(frontier, guide.city, "leave the city")
    end

    for _ = 1, 4 do
        local found = {}
        for _, node in ipairs(frontier) do
            local items = byZone[node.zoneId]
            if items and #items > 0 then
                found[#found + 1] = { zoneId = node.zoneId, via = node.via, items = items }
            end
        end
        if #found > 0 then
            table.sort(found, function(a, b) return #a.items > #b.items end)
            return found
        end
        local nextFrontier = {}
        for _, node in ipairs(frontier) do
            local g = ING.Zones[node.zoneId]
            for _, n in ipairs(g and g.neighbours or {}) do
                push(nextFrontier, n[1], ING.ZoneName(node.zoneId) .. ", then " .. n[2])
            end
        end
        frontier = nextFrontier
        if #frontier == 0 then break end
    end
    return {}
end

local function GuideFor(level, byZone)
    local factionLetter = ING.PlayerFactionLetter()
    local route = ING.Route[factionLetter or "A"] or {}
    local zones, seen = {}, {}
    for _, step in ipairs(route) do
        if level >= step.min and level <= step.max then
            for _, zoneId in ipairs(step.zones) do
                local g = ING.Zones[zoneId]
                if g and not seen[zoneId] then
                    seen[zoneId] = true
                    zones[#zones + 1] = {
                        zoneId = zoneId, name = ING.ZoneName(zoneId), min = g.min, max = g.max,
                        tip = g.tip, count = byZone[zoneId] and #byZone[zoneId] or 0,
                    }
                end
            end
        end
    end
    table.sort(zones, function(a, b) return a.count > b.count end)

    local dungeons = {}
    for _, d in ipairs(ING.Dungeons) do
        if level >= d.min - 1 and level <= d.max and (d.faction == "B" or d.faction == factionLetter) then
            dungeons[#dungeons + 1] = d
        end
    end
    return zones, dungeons
end

function Scanner.Compute()
    if not index then return nil end
    local lib = DB()
    local db = ING.db
    local level = ING.playerLevel or UnitLevel("player")
    local low, high = level - db.levelsBelow, level + db.levelsAbove
    local active = ActiveQuests()
    local zoneId, playerMap, px, py = PlayerArea()

    local byZone = {}
    for _, entry in ipairs(index) do
        local id = entry.id
        if entry.level >= low and entry.level <= high and (entry.req or 1) <= level
            and not active[id] and IsEligible(id) then
            local category = Categorize(id)
            if CategoryAllowed(category) then
                local name = lib.Quest.name(id) or ("Quest " .. id)
                for zone, starter in pairs(entry.zones) do
                    local coord, distance
                    if zone == zoneId then
                        coord, distance = NearestCoord(starter, playerMap, px, py)
                    else
                        coord = NearestCoord(starter)
                    end
                    local list = byZone[zone]
                    if not list then list = {}; byZone[zone] = list end
                    list[#list + 1] = {
                        id = id, name = name, level = entry.level, req = entry.req,
                        category = category, starterName = starter.name, starterKind = starter.kind,
                        areaId = starter.areaId, zoneId = zone, coord = coord, distance = distance,
                    }
                end
            end
        end
    end
    for _, items in pairs(byZone) do
        SortItems(items)
    end

    local results = {
        level = level, low = low, high = high,
        zoneId = zoneId, zoneName = zoneId and ING.ZoneName(zoneId) or (GetRealZoneText and GetRealZoneText()) or "Unknown zone",
        sections = {}, byZone = byZone,
        tip = ING.PickTip(level),
    }

    local current = zoneId and byZone[zoneId] or {}
    if #current > 0 then
        results.sections[1] = { kind = "current", zoneId = zoneId, title = results.zoneName, items = current }
    else
        results.currentEmpty = true
        for _, found in ipairs(zoneId and FindNeighbourSections(zoneId, byZone) or {}) do
            results.sections[#results.sections + 1] = {
                kind = "neighbour", zoneId = found.zoneId, title = ING.ZoneName(found.zoneId),
                via = found.via, items = found.items,
            }
        end
    end

    -- Direction hint when the zone no longer fits the player's level.
    local guide = zoneId and ING.Zones[zoneId]
    if guide and guide.max and level > guide.max + 1 then
        results.advice = ("You are above %s's level range (%d-%d). Look at the guide zones below."):format(results.zoneName, guide.min, guide.max)
    end

    results.guideZones, results.dungeons = GuideFor(level, byZone)
    return results
end

function Scanner.Objectives(id)
    local lib = DB()
    return lib and lib.Quest.objectivesText(id)
end
