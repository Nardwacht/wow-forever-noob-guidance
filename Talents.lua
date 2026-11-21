local _, ING = ...

-- Reads your talent trees and compares them with the leveling advice in
-- Data/Talents.lua: points spread over trees, a tree that is not great for
-- solo leveling, and important talents you skipped.
--
-- WoW Forever stores talents with the modern C_Traits API (one tree, with a
-- "group" per classic tab). Older clients' GetTalentTabInfo is a fallback.

local Talents = {}
ING.Talents = Talents

local cache, dirty = nil, true

local function Call(...) return ING.Coach.Call(...) end

-- ============================================================
-- Reading
-- ============================================================

local function ReadModern(classData)
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo) then
        return nil
    end
    local configID = Call(C_ClassTalents.GetActiveConfigID)
    if not configID then return nil end
    local info = Call(C_Traits.GetConfigInfo, configID)
    local treeID = info and info.treeIDs and info.treeIDs[1]
    if not treeID then return nil end

    local data = { trees = {}, talents = {}, total = 0 }
    for _, group in ipairs(Call(C_Traits.GetGroupDisplayInfoByTreeID, treeID) or {}) do
        local id = group.groupID
        if id then
            local spent = 0
            local currency = Call(C_Traits.GetGroupCurrencyInfo, configID, { id })
            local first = currency and currency[1] and currency[1].currencyInfos and currency[1].currencyInfos[1]
            if first and type(first.spent) == "number" then spent = first.spent end
            local name = classData and classData.trees[id] or group.name or ("Tree " .. id)
            data.trees[#data.trees + 1] = { id = id, name = name, spent = spent }
            data.total = data.total + spent
        end
    end

    if C_Traits.GetTreeCurrencyInfo then
        local currency = Call(C_Traits.GetTreeCurrencyInfo, configID, treeID, false)
        if currency and currency[1] and type(currency[1].quantity) == "number" then
            data.unspent = currency[1].quantity
        end
    end

    -- Talent names and ranks, from each node's spell.
    for _, nodeID in ipairs(Call(C_Traits.GetTreeNodes, treeID) or {}) do
        local node = Call(C_Traits.GetNodeInfo, configID, nodeID)
        if node and node.entryIDs then
            for _, entryID in ipairs(node.entryIDs) do
                local entry = Call(C_Traits.GetEntryInfo, configID, entryID)
                local def = entry and entry.definitionID and Call(C_Traits.GetDefinitionInfo, entry.definitionID)
                local spell = def and (def.spellID or def.overriddenSpellID)
                local name = spell and ING.Coach.SpellName(spell)
                if name then
                    data.talents[name] = {
                        rank = node.currentRank or node.activeRank or 0,
                        max = node.maxRanks,
                        group = node.groupIDs and node.groupIDs[1],
                    }
                end
            end
        end
    end
    return data
end

local function ReadClassic(classData)
    if type(GetNumTalentTabs) ~= "function" then return nil end
    local tabs = Call(GetNumTalentTabs)
    if not tabs or tabs == 0 then return nil end
    -- Without group IDs, trees are matched to the advice by English name.
    local idByName = {}
    for id, name in pairs(classData and classData.trees or {}) do idByName[name] = id end

    local data = { trees = {}, talents = {}, total = 0 }
    for tab = 1, tabs do
        local a, b, c, _, e = Call(GetTalentTabInfo, tab)
        local name, spent
        if type(a) == "number" then name, spent = b, e else name, spent = a, c end
        spent = tonumber(spent) or 0
        data.trees[#data.trees + 1] = { id = idByName[name] or ("tab" .. tab), name = name or ("Tree " .. tab), spent = spent }
        data.total = data.total + spent
        for i = 1, Call(GetNumTalents, tab) or 0 do
            local talentName, _, _, _, rank, maxRank = Call(GetTalentInfo, tab, i)
            if type(talentName) == "string" then
                data.talents[talentName] = { rank = rank or 0, max = maxRank, group = idByName[name] }
            end
        end
    end
    data.unspent = Call(_G.UnitCharacterPoints, "player")
    return data
end

function Talents.Get()
    if dirty or not cache then
        local _, classToken = UnitClass("player")
        local classData = ING.TalentTrees[classToken]
        cache = ReadModern(classData) or ReadClassic(classData)
        dirty = false
    end
    return cache
end

-- ============================================================
-- Analysis
-- ============================================================

-- Returns nil when the talents can't be read on this client, else:
-- trees (most points first), total, unspent, main, recommended,
-- issues = { {severity, text} }, keys = { {name, state, points} },
-- next (talent to take next), verdict (severity), classData.
function Talents.Analyze(level)
    local data = Talents.Get()
    if not data or #data.trees == 0 then return nil end
    local _, classToken = UnitClass("player")
    local classData = ING.TalentTrees[classToken]

    local trees = {}
    for i, t in ipairs(data.trees) do trees[i] = t end
    table.sort(trees, function(a, b) return a.spent > b.spent end)

    local result = { trees = trees, total = data.total, unspent = data.unspent, issues = {}, keys = {}, classData = classData }
    if data.total == 0 then
        result.verdict = "info"
        if level < 10 then
            result.issues[1] = { "info", "Talent points start at level 10." }
        end
        result.main = nil
    else
        result.main = trees[1]
    end
    if not classData then return result end

    local recommended
    for _, t in ipairs(trees) do
        if t.id == classData.leveling then recommended = t end
    end
    result.recommended = recommended
    local recommendedName = classData.trees[classData.leveling]

    local function issue(severity, text)
        result.issues[#result.issues + 1] = { severity, text }
    end

    if data.total > 0 then
        local main = trees[1]
        local share = main.spent / data.total

        -- 1. Points spread over trees.
        local splitOk = classData.splitOkBefore and level < classData.splitOkBefore
            and classData.splitTrees[trees[1].id] and trees[2] and classData.splitTrees[trees[2].id]
            and (not trees[3] or trees[3].spent == 0)
        if data.total >= 8 and share < 0.7 and not splitOk then
            local parts = {}
            for _, t in ipairs(trees) do
                if t.spent > 0 then parts[#parts + 1] = ("%s %d"):format(t.name, t.spent) end
            end
            issue((share < 0.55 and data.total >= 15) and "urgent" or "warn",
                ("Your points are spread over trees (%s). Talents deep in one tree are much stronger: the best ones need 11, 16, 21 or 31 points in the same tree."):format(table.concat(parts, ", ")))
        end

        -- 2. Main tree is not a leveling tree.
        if main.id ~= classData.leveling then
            local why = classData.alsoFine and classData.alsoFine[main.id]
            if why then
                issue("good", ("%s is a fine choice for %s. For fast solo leveling guides prefer %s."):format(main.name, why, recommendedName))
            else
                issue(data.total >= 10 and "warn" or "tip",
                    ("Most of your points are in %s. For solo leveling, guides recommend %s."):format(main.name, recommendedName))
            end
        end
    end

    -- 3. Key talents in the leveling tree.
    local inLeveling = recommended and recommended.spent or 0
    for _, key in ipairs(classData.key) do
        local talent = data.talents[key.name]
        if talent then -- only talents this client knows under that name
            local state
            if talent.rank and talent.rank > 0 then
                state = "taken"
            elseif inLeveling >= key.points then
                state = "open"
            else
                state = "locked"
            end
            result.keys[#result.keys + 1] = { name = key.name, state = state, points = key.points, rank = talent.rank, max = talent.max }
            if state == "open" and not result.next then
                result.next = key.name
            end
            -- Skipped: the tree went well past this talent without taking it.
            if state == "open" and inLeveling >= key.points + 5 then
                issue("warn", ("You skipped %s, a key %s talent (opens at %d points in the tree)."):format(key.name, recommendedName, key.points))
            end
        end
    end

    -- Verdict: the worst issue.
    local order = { urgent = 4, warn = 3, tip = 2, good = 1, info = 0 }
    local worst = data.total > 0 and "good" or "info"
    for _, i in ipairs(result.issues) do
        if (order[i[1]] or 0) > (order[worst] or 0) then worst = i[1] end
    end
    result.verdict = worst
    result.needsReset = data.total >= 10 and (worst == "urgent"
        or (result.main and result.main.id ~= classData.leveling and not (classData.alsoFine and classData.alsoFine[result.main.id])))
    return result
end

Talents.RESET_TEXT = "To start over: talk to your class trainer and choose to unlearn your talents. It costs a little gold, then you get every point back."

-- ============================================================
-- Coach tip
-- ============================================================

ING.Coach.AddDetector(function(ctx)
    if ctx.level < 10 then return nil end
    local analysis = Talents.Analyze(ctx.level)
    if not analysis or analysis.total == 0 then return nil end
    if analysis.verdict ~= "urgent" and analysis.verdict ~= "warn" then return nil end

    local first
    local help = {}
    for _, i in ipairs(analysis.issues) do
        if i[1] == "urgent" or i[1] == "warn" then
            first = first or i[2]
        end
        help[#help + 1] = i[2]
    end
    if analysis.next then
        help[#help + 1] = "Next talent to take: " .. analysis.next
    end
    if analysis.needsReset then
        help[#help + 1] = Talents.RESET_TEXT
    end
    if analysis.classData and analysis.classData.note then
        help[#help + 1] = analysis.classData.note
    end
    help[#help + 1] = "Open the window (/ing) for your full talent overview."
    return {
        id = "talentplan", kind = analysis.verdict, priority = analysis.verdict == "urgent" and 87 or 62, snooze = "level",
        title = analysis.needsReset and "Your talents could use a reset" or "Your talents need attention",
        detail = first, help = help,
    }
end)

local events = CreateFrame("Frame")
for _, event in ipairs({ "TRAIT_CONFIG_UPDATED", "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED", "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function()
    dirty = true
    ING.RequestRefresh(1)
end)
