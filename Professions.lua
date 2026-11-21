local _, ING = ...

-- Looks at your professions and what they can do for you that you are not
-- using: a skill stuck at its cap, a profession you learned and never
-- raised, gathering skill too low for your zones, herb/ore tracking turned
-- off, First Aid without bandages, ore you could smelt.

local Professions = {}
ING.Professions = Professions

local function Call(...) return ING.Coach.Call(...) end

local GATHERING = { [182] = "herbs", [186] = "ore", [393] = "skins" }
local CRAFTING = { [171] = true, [164] = true, [333] = true, [202] = true, [165] = true, [197] = true }
local FIRST_AID, MINING, HERBALISM = 129, 186, 182

-- Tracking spells: Find Herbs, Find Minerals.
local TRACKING = { [HERBALISM] = 2383, [MINING] = 2580 }

local CLOTH = { 2589, 2592, 4306, 4338, 14047 }                    -- linen ... runecloth
local BANDAGES = { 1251, 2581, 3530, 3531, 6450, 6451, 8544, 8545, 14529, 14530 }
local ORE = { 2770, 2771, 2775, 2772, 2776, 3858, 7911, 10620 }    -- copper ... thorium

local function CountItems(ids)
    local getCount = (C_Item and C_Item.GetItemCount) or _G.GetItemCount
    local total = 0
    for _, id in ipairs(ids) do
        total = total + (Call(getCount, id) or 0)
    end
    return total
end

-- { [skillLine] = { name, rank, max, skillLine } }, or nil when this client
-- can't list professions.
local function ReadProfessions()
    if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then return nil end
    local indices = { Call(GetProfessions) }
    local list = {}
    for i = 1, 6 do
        local index = indices[i]
        if index then
            local name, _, rank, max, _, _, skillLine = Call(GetProfessionInfo, index)
            if name and skillLine then
                list[skillLine] = { name = name, rank = rank or 0, max = max or 0, skillLine = skillLine }
            end
        end
    end
    return list
end

-- Is a tracking type with this spell available, and is it switched on?
-- Returns nil when the client can't tell.
local function TrackingState(spellId)
    local numTypes = C_Minimap and C_Minimap.GetNumTrackingTypes
    local getInfo = C_Minimap and C_Minimap.GetTrackingInfo
    if not (numTypes and getInfo) then
        numTypes, getInfo = _G.GetNumTrackingTypes, _G.GetTrackingInfo
    end
    if type(numTypes) ~= "function" or type(getInfo) ~= "function" then return nil end
    for i = 1, Call(numTypes) or 0 do
        local a, _, active, _, _, id = Call(getInfo, i)
        if type(a) == "table" then
            active, id = a.active, a.spellID
        end
        if id == spellId then
            return true, active and true or false
        end
    end
    return nil
end

-- Returns { entries = { {name, rank, max, severity, label} }, advice = { {severity, text, id} } }
function Professions.Analyze(level)
    local list = ReadProfessions()
    if not list then return nil end
    local memory = ING.Coach.Memory()
    memory.professions = memory.professions or {}
    local result = { entries = {}, advice = {} }

    local function advise(severity, id, text, help)
        result.advice[#result.advice + 1] = { severity = severity, id = id, text = text, help = help }
    end

    for skillLine, prof in pairs(list) do
        local severity, label = "good", "OK"

        -- Remember when we first saw this skill value, to spot an unused profession.
        local seen = memory.professions[skillLine]
        if not seen or prof.rank > seen.rank then
            seen = { rank = prof.rank, level = level }
            memory.professions[skillLine] = seen
        end

        if prof.max > 0 and prof.rank >= prof.max and prof.max < 300 then
            severity, label = "warn", "Capped - train"
            advise("warn", "profcap" .. skillLine,
                ("%s is stuck at %d/%d. Visit a %s trainer to learn the next rank, or your skill stops growing."):format(prof.name, prof.rank, prof.max, prof.name),
                { "Trainers are in capital cities and many towns. Ask a guard." })
        elseif level - seen.level >= 3 and prof.rank < 50 then
            severity, label = "warn", "Not used"
            advise("warn", "profunused" .. skillLine,
                ("You learned %s but it has not gone up for %d levels."):format(prof.name, level - seen.level),
                { GATHERING[skillLine] and ("Gather " .. GATHERING[skillLine] .. " as you quest: every node or corpse raises the skill.")
                    or "Craft the cheapest recipes your trainer offers to raise it, or replace it with a gathering profession that earns gold." })
        elseif GATHERING[skillLine] and level >= 15 and prof.rank < level * 5 - 60 then
            severity, label = "warn", "Low for level"
            advise("warn", "proflow" .. skillLine,
                ("%s %d is low for level %d: many %s in your zones will be too hard to gather."):format(prof.name, prof.rank, level, GATHERING[skillLine]),
                { "Gather everything you see, also in easier zones, until it catches up." })
        end

        -- Gathering tracking switched off.
        local trackSpell = TRACKING[skillLine]
        if trackSpell then
            local available, active = TrackingState(trackSpell)
            if available and not active then
                -- Only one tracking type can be on; don't nag if the other gathering one is.
                local otherSpell = TRACKING[skillLine == HERBALISM and MINING or HERBALISM]
                local _, otherActive = TrackingState(otherSpell)
                if not otherActive then
                    advise("tip", "proftrack" .. skillLine,
                        ("Turn on %s tracking: %s show up on your minimap."):format(ING.Coach.SpellName(trackSpell) or prof.name, GATHERING[skillLine]),
                        { "Click the magnifying glass on your minimap and pick it." })
                end
            end
        end

        result.entries[#result.entries + 1] = { name = prof.name, rank = prof.rank, max = prof.max, severity = severity, label = label, skillLine = skillLine }
    end

    -- First Aid.
    if level >= 10 then
        if list[FIRST_AID] then
            if CountItems(BANDAGES) == 0 then
                local cloth = CountItems(CLOTH)
                advise("tip", "bandages",
                    cloth > 0 and ("You have First Aid but no bandages. Turn your %d cloth into bandages."):format(cloth)
                        or "You have First Aid but no bandages. Keep the cloth you loot and make bandages from it.",
                    { "Bandages heal you between or during fights without mana.", "Open First Aid from your spellbook (P)." })
            end
        else
            advise("tip", "firstaid", "Learn First Aid: bandages made from looted cloth heal you without mana.",
                { "First Aid does not count toward your two main professions.", "Ask a guard for the First Aid trainer." })
        end
    end

    -- Mining: smelting.
    if list[MINING] and CountItems(ORE) >= 10 then
        advise("tip", "smelt", "You carry ore. Smelting it into bars also raises Mining, and bars are what crafters buy.",
            { "Use Smelting (in your spellbook) near a forge, found in most towns." })
    end

    table.sort(result.entries, function(a, b) return a.rank > b.rank end)
    return result
end

-- One coach tip per piece of advice, so each can be hidden on its own.
ING.Coach.AddDetector(function(ctx)
    local analysis = Professions.Analyze(ctx.level)
    if not analysis or #analysis.advice == 0 then return nil end
    -- The coach takes one tip per detector; show the most urgent.
    table.sort(analysis.advice, function(a, b) return (a.severity == "warn" and 1 or 0) > (b.severity == "warn" and 1 or 0) end)
    for _, a in ipairs(analysis.advice) do
        local mark = ING.Coach.Memory().dismissed[a.id]
        if mark == nil or mark < ctx.level then
            return {
                id = a.id, kind = a.severity, priority = a.severity == "warn" and 58 or 28, snooze = "level",
                title = "Profession: " .. a.text:match("^[^.:]+"),
                detail = a.text, help = a.help,
            }
        end
    end
    return nil
end)

local events = CreateFrame("Frame")
for _, event in ipairs({ "SKILL_LINES_CHANGED", "TRADE_SKILL_LIST_UPDATE", "MINIMAP_UPDATE_TRACKING" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function() ING.RequestRefresh(1) end)
