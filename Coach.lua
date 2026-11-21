local _, ING = ...

-- The coach looks at your character and how you play, and points out things
-- to fix (low gear, broken armour, full bags) and game features you have not
-- used yet (flight paths, dungeons, the auction house, class quests...).
--
-- The Forever client uses the modern API set and lacks some old functions
-- (GetSkillLineInfo, GetSpellInfo). Every check tries the modern function,
-- then the old one, and stays silent when neither is there: a missing tip is
-- better than a wrong one.

local Coach = {}
ING.Coach = Coach

-- ============================================================
-- Safe API helpers
-- ============================================================

local function IsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

local function Unwrap(ok, ...)
    if not ok then return nil end
    for i = 1, select("#", ...) do
        if IsSecret((select(i, ...))) then return nil end
    end
    return ...
end

-- Calls an API function that may be missing on this client; nil on any error
-- or when a value is secret (hidden during combat on modern clients).
local function Call(func, ...)
    if type(func) ~= "function" then return nil end
    return Unwrap(pcall(func, ...))
end

local function SpellName(spellId)
    if C_Spell and C_Spell.GetSpellName then
        local name = Call(C_Spell.GetSpellName, spellId)
        if name then return name end
    end
    return (Call(_G.GetSpellInfo, spellId))
end

local function IsSpellKnown(spellId)
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        return Call(C_SpellBook.IsSpellKnown, spellId)
    end
    if type(IsPlayerSpell) == "function" then
        return Call(IsPlayerSpell, spellId)
    end
    return Call(_G.IsSpellKnown, spellId)
end

local function ItemLevel(link)
    if not link then return nil end
    if C_Item and C_Item.GetDetailedItemLevelInfo then
        local level = Call(C_Item.GetDetailedItemLevelInfo, link)
        if level then return level end
    end
    local level = Call(_G.GetDetailedItemLevelInfo, link)
    if level then return level end
    local getInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    local _, _, _, itemLevel = Call(getInfo, link)
    return itemLevel
end

local function SellPrice(itemId)
    local getInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    return select(11, Call(getInfo, itemId))
end

local function IsAddOnLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return Call(C_AddOns.IsAddOnLoaded, name)
    end
    return Call(_G.IsAddOnLoaded, name)
end

-- Shared with Talents.lua and Professions.lua.
Coach.Call = Call
Coach.SpellName = SpellName
Coach.IsSpellKnown = IsSpellKnown

local function FormatMoney(copper)
    if not copper or copper <= 0 then return nil end
    if GetCoinTextureString then return GetCoinTextureString(copper) end
    return ("%dg %ds %dc"):format(math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
end

-- ============================================================
-- Per-character memory of what the player has done
-- ============================================================

local function Memory()
    local char = ING.char
    char.coach = char.coach or {}
    local m = char.coach
    m.dismissed = m.dismissed or {}
    m.dismissedSpells = m.dismissedSpells or {}
    -- The level the addon first saw this character. "Never used X" is only
    -- claimed after watching for a while, so a character that installed the
    -- addon at 30 is not told about flight paths it surely knows.
    m.since = m.since or UnitLevel("player")
    return m
end
Coach.Memory = Memory

-- True when we have watched long enough to say "you have not done this".
local function Watched(minLevel)
    local m = Memory()
    local level = ING.playerLevel or UnitLevel("player")
    return m.since <= minLevel or level - m.since >= 3
end

local sessionDeaths = {}
local sessionSnooze = {}

-- ============================================================
-- Scans (cached; marked dirty by events)
-- ============================================================

local dirty = { gear = true, bags = true, spells = true }
local cache = {}

function Coach.MarkDirty(what)
    if what then dirty[what] = true else dirty.gear, dirty.bags, dirty.spells = true, true, true end
end

-- core = counts toward the average and the "nothing equipped" warning.
-- Jewellery, trinkets and off-hand/ranged are shown but not required: low
-- level characters rarely have them.
local GEAR_SLOTS = {
    { id = 1, name = "Head", core = true }, { id = 2, name = "Neck" },
    { id = 3, name = "Shoulders", core = true }, { id = 15, name = "Back", core = true },
    { id = 5, name = "Chest", core = true }, { id = 9, name = "Wrists", core = true },
    { id = 10, name = "Hands", core = true }, { id = 6, name = "Waist", core = true },
    { id = 7, name = "Legs", core = true }, { id = 8, name = "Feet", core = true },
    { id = 11, name = "Ring 1" }, { id = 12, name = "Ring 2" },
    { id = 13, name = "Trinket 1" }, { id = 14, name = "Trinket 2" },
    { id = 16, name = "Main hand", core = true }, { id = 17, name = "Off hand" },
    { id = 18, name = "Ranged" },
}

-- Returns the gear report and whether every equipped item's data was loaded.
-- Right after login the client often has not loaded item data yet, so item
-- levels come back empty; the caller scans again until they are all known.
local function ScanGear()
    local gear = { all = {}, slots = {}, empty = {}, lowestDurability = nil, broken = 0, unknown = 0 }
    local total, count = 0, 0
    for _, slot in ipairs(GEAR_SLOTS) do
        local link = Call(GetInventoryItemLink, "player", slot.id)
        local entry = { id = slot.id, name = slot.name, core = slot.core, link = link }
        if link then
            entry.level = ItemLevel(link)
            entry.quality = Call(GetInventoryItemQuality, "player", slot.id)
            local current, maximum = Call(GetInventoryItemDurability, slot.id)
            if current and maximum and maximum > 0 then
                entry.durability = current / maximum * 100
                if not gear.lowestDurability or entry.durability < gear.lowestDurability then
                    gear.lowestDurability = entry.durability
                end
                if current == 0 then gear.broken = gear.broken + 1 end
            end
            if entry.level then
                if slot.core then
                    total, count = total + entry.level, count + 1
                    gear.slots[#gear.slots + 1] = entry
                end
            else
                gear.unknown = gear.unknown + 1
            end
        elseif slot.core then
            gear.empty[#gear.empty + 1] = slot.name
        end
        gear.all[#gear.all + 1] = entry
    end
    gear.average = count > 0 and (total / count) or nil
    table.sort(gear.slots, function(a, b) return a.level < b.level end)
    return gear, gear.unknown == 0
end

-- How the gear compares with the player's level: "good", "behind" or "far".
function Coach.GearVerdict(gear, level)
    if not gear or not gear.average then return nil end
    local behind = level - gear.average
    if behind >= 7 then return "far", behind end
    if behind >= 3 then return "behind", behind end
    return "good", behind
end

-- Status of one equipped slot: severity (colour) and a short label.
--   red    "Upgrade advised": armour/weapon 7+ levels behind you, or empty
--   orange "Upgrade soon":    3-6 levels behind
--   green  "OK"
-- Worn items (under 25%) get "Repair" added; broken ones are always red.
-- Rings, trinkets, off-hand and ranged are optional: never "advised".
function Coach.SlotStatus(entry, level)
    local severity, labels = "good", {}
    if not entry.link then
        if entry.core then
            return "urgent", "Empty - upgrade advised"
        end
        return "info", "Empty (optional)"
    end
    if entry.level and entry.core then
        local behind = level - entry.level
        if behind >= 7 then
            severity = "urgent"
            labels[#labels + 1] = "Upgrade advised"
        elseif behind >= 3 then
            severity = "warn"
            labels[#labels + 1] = "Upgrade soon"
        end
    elseif not entry.level then
        severity = "info"
        labels[#labels + 1] = "Loading..."
    end
    if entry.durability then
        if entry.durability == 0 then
            severity = "urgent"
            labels[#labels + 1] = "Broken - repair"
        elseif entry.durability < 25 then
            if severity == "good" or severity == "info" then severity = "warn" end
            labels[#labels + 1] = "Repair"
        end
    end
    if #labels == 0 then labels[1] = "OK" end
    return severity, table.concat(labels, ", ")
end

function Coach.GetGear()
    if dirty.gear or not cache.gear then
        local complete
        cache.gear, complete = ScanGear()
        dirty.gear = not complete
    end
    return cache.gear
end

local function ScanBags()
    local bags = { free = 0, total = 0, missingBags = 0, grey = 0, greyValue = 0 }
    local C = C_Container
    local numSlots = (C and C.GetContainerNumSlots) or _G.GetContainerNumSlots
    local numFree = (C and C.GetContainerNumFreeSlots) or _G.GetContainerNumFreeSlots
    if type(numSlots) ~= "function" then return nil end
    for bag = 0, 4 do
        local slots = Call(numSlots, bag) or 0
        bags.total = bags.total + slots
        if bag > 0 and slots == 0 then bags.missingBags = bags.missingBags + 1 end
        local free = Call(numFree, bag)
        if free then bags.free = bags.free + free end
        for slot = 1, slots do
            local quality, stack, itemId
            if C and C.GetContainerItemInfo then
                local info = Call(C.GetContainerItemInfo, bag, slot)
                if info then quality, stack, itemId = info.quality, info.stackCount, info.itemID end
            elseif _G.GetContainerItemInfo then
                local _, count, _, q, _, _, _, _, _, id = Call(_G.GetContainerItemInfo, bag, slot)
                quality, stack, itemId = q, count, id
            end
            if quality == 0 and itemId then
                bags.grey = bags.grey + 1
                local price = SellPrice(itemId)
                if price then bags.greyValue = bags.greyValue + price * (stack or 1) end
            end
        end
    end
    return bags
end

-- Spells in the spellbook that are on no action bar (macros and stance bar count).
local function ScanUnboundSpells()
    local onBars = {}
    local function mark(spellId)
        local name = spellId and SpellName(spellId)
        if name then onBars[name] = true end
    end
    for slot = 1, 180 do
        local kind, id = Call(GetActionInfo, slot)
        if kind == "spell" then
            mark(id)
        elseif kind == "macro" and id then
            mark((Call(_G.GetMacroSpell, id)))
        end
    end
    local forms = Call(_G.GetNumShapeshiftForms) or 0
    for i = 1, forms do
        mark(select(4, Call(GetShapeshiftFormInfo, i)))
    end

    local known = {}
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookItemInfo then
        local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
        local spellType = Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell or 1
        local lines = Call(C_SpellBook.GetNumSpellBookSkillLines) or 0
        -- Line 1 is "General" (auto attack, professions...): skipped.
        for line = 2, lines do
            local info = Call(C_SpellBook.GetSpellBookSkillLineInfo, line)
            if info and not info.isGuild and not (info.offSpecID and info.offSpecID > 0) then
                for i = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                    local item = Call(C_SpellBook.GetSpellBookItemInfo, i, bank)
                    if item and item.itemType == spellType and not item.isPassive and not item.isOffSpec and item.name then
                        known[#known + 1] = item.name
                    end
                end
            end
        end
    elseif type(GetNumSpellTabs) == "function" then
        local book = BOOKTYPE_SPELL or "spell"
        for tab = 2, Call(GetNumSpellTabs) or 0 do
            local _, _, offset, numSpells = Call(GetSpellTabInfo, tab)
            for i = (offset or 0) + 1, (offset or 0) + (numSpells or 0) do
                local kind = Call(GetSpellBookItemInfo, i, book)
                local name = Call(GetSpellBookItemName, i, book)
                if kind == "SPELL" and name and not Call(IsPassiveSpell, i, book) then
                    known[#known + 1] = name
                end
            end
        end
    else
        return nil
    end

    local seen, missing = {}, {}
    for _, name in ipairs(known) do
        if not onBars[name] and not seen[name] and not Memory().dismissedSpells[name] then
            seen[name] = true
            missing[#missing + 1] = name
        end
    end
    return missing
end

-- Number of primary professions, or nil when this client cannot tell.
local PRIMARY_SKILL_LINES = { [164] = true, [186] = true, [165] = true, [197] = true, [171] = true,
    [202] = true, [333] = true, [393] = true, [182] = true }

local function PrimaryProfessionCount()
    if type(GetProfessions) == "function" then
        local ok, p1, p2 = pcall(GetProfessions)
        if ok then return (p1 and 1 or 0) + (p2 and 1 or 0) end
    end
    local loader = _G.QuestieLoader
    local professions = loader and loader:ImportModule("QuestieProfessions")
    if professions and professions.GetPlayerProfessions then
        local ok, list = pcall(professions.GetPlayerProfessions, professions)
        if ok and type(list) == "table" then
            local count = 0
            for id in pairs(list) do
                if PRIMARY_SKILL_LINES[id] then count = count + 1 end
            end
            return count
        end
    end
    return nil
end

local function UnspentTalentPoints()
    local points = Call(_G.UnitCharacterPoints, "player")
    if points then return points end
    points = Call(_G.GetUnspentTalentPoints)
    if points then return points end
    -- WoW Forever: unspent points come from the talent tree's currency.
    local talents = ING.Talents and ING.Talents.Get()
    return talents and talents.unspent
end

local function QuestLogFill()
    local count, max
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
        count = select(2, Call(C_QuestLog.GetNumQuestLogEntries))
    end
    count = count or select(2, Call(_G.GetNumQuestLogEntries))
    if C_QuestLog and C_QuestLog.GetMaxNumQuestsCanAccept then
        max = Call(C_QuestLog.GetMaxNumQuestsCanAccept)
    end
    return count, max or (_G.MAX_QUESTS)
end

-- ============================================================
-- Detectors. Each returns nil or a tip:
--   id, kind ("warn" or "tip"), priority (higher first), title, detail,
--   help (tooltip lines), snooze ("level", "session" or "forever")
-- ============================================================

local function DungeonsForLevel(level)
    local names = {}
    local faction = ING.PlayerFactionLetter()
    for _, d in ipairs(ING.Dungeons) do
        if level >= d.min and level <= d.max and (d.faction == "B" or d.faction == faction) then
            names[#names + 1] = d.name .. " (" .. d.where .. ")"
        end
    end
    return names
end

local detectors = {}

-- Other modules (Talents.lua, Professions.lua) add their own checks here.
function Coach.AddDetector(detector)
    detectors[#detectors + 1] = detector
end

-- Broken or nearly broken armour.
detectors[#detectors + 1] = function(ctx)
    local gear = ctx.gear
    if not gear or not gear.lowestDurability or gear.lowestDurability >= 30 then return nil end
    local broken = gear.broken > 0
    return {
        id = "repair", kind = broken and "urgent" or "warn", priority = broken and 100 or 90, snooze = "session",
        title = broken and "Some of your gear is broken!" or ("Your gear is at %d%% durability"):format(gear.lowestDurability),
        detail = broken and "Broken items give no stats at all. Repair at a vendor with the anvil icon."
            or "Repair soon at a vendor with the anvil icon (blacksmiths and armour sellers).",
        help = { "Every death and every fight wears your gear down.", "Look for an anvil icon above a vendor's head, then click Repair All." },
    }
end

-- Gear far behind the player's level.
detectors[#detectors + 1] = function(ctx)
    local gear, level = ctx.gear, ctx.level
    if not gear or level < 10 then return nil end
    local behind = gear.average and (level - gear.average) or 0
    local emptyCount = #gear.empty
    if behind < 7 and emptyCount < 3 then return nil end

    local parts = {}
    if gear.average and behind >= 7 then
        parts[#parts + 1] = ("Your gear averages item level %d, about %d levels behind you."):format(gear.average, behind)
    end
    if emptyCount >= 3 or (emptyCount > 0 and behind >= 7) then
        parts[#parts + 1] = "Nothing equipped in: " .. table.concat(gear.empty, ", ") .. "."
    end
    local help = {}
    if gear.average and behind >= 7 then
        local worst = {}
        for i = 1, math.min(3, #gear.slots) do
            worst[#worst + 1] = ("%s (item level %d)"):format(gear.slots[i].name, gear.slots[i].level)
        end
        help[#help + 1] = "Weakest: " .. table.concat(worst, ", ")
    end
    help[#help + 1] = "Ways to upgrade:"
    help[#help + 1] = "- Quest rewards: always pick the item for your armour type."
    local dungeons = DungeonsForLevel(level)
    if #dungeons > 0 then
        help[#help + 1] = "- Dungeons for your level: " .. table.concat(dungeons, ", ", 1, math.min(3, #dungeons))
    end
    help[#help + 1] = "- The auction house in a capital city sells cheap gear made by players."
    if IsAddOnLoaded("Pawn") then
        help[#help + 1] = "- You have Pawn installed: it shows a green arrow on items that are upgrades for you."
    end
    return {
        id = "gear", kind = behind >= 7 and "urgent" or "warn", priority = 80, snooze = "level",
        title = "Your equipment is weak for your level",
        detail = table.concat(parts, " "), help = help,
    }
end

-- Bags almost full / grey junk.
detectors[#detectors + 1] = function(ctx)
    local bags = ctx.bags
    if not bags or bags.total == 0 then return nil end
    local value = FormatMoney(bags.greyValue)
    if bags.free <= 3 then
        local detail = ("Only %d free bag slots left."):format(bags.free)
        if bags.grey > 0 then
            detail = detail .. (" Sell your %d grey items at any vendor%s."):format(bags.grey, value and (" for " .. value) or "")
        end
        local help = { "Loot you can't pick up is lost.", "Grey items are junk: they are only worth money at a vendor." }
        if not Memory().usedBank and ctx.level >= 10 then
            help[#help + 1] = "You can store items in the bank in any capital city. You have not used it yet."
        end
        return { id = "bagsfull", kind = "warn", priority = 70, snooze = "session",
            title = "Your bags are almost full", detail = detail, help = help }
    end
    if bags.grey >= 6 then
        return { id = "greys", kind = "tip", priority = 30, snooze = "session",
            title = "Sell your junk",
            detail = ("You carry %d grey items%s. Sell them at any vendor."):format(bags.grey, value and (" worth " .. value) or ""),
            help = { "Grey items have no use except selling. Right-click them while a vendor window is open." } }
    end
    return nil
end

-- Empty bag slots (no bag bought yet).
detectors[#detectors + 1] = function(ctx)
    local bags = ctx.bags
    if not bags or ctx.level < 8 or bags.missingBags == 0 then return nil end
    return { id = "buybags", kind = "tip", priority = 45, snooze = "level",
        title = ("You have %d empty bag slot%s"):format(bags.missingBags, bags.missingBags > 1 and "s" or ""),
        detail = "Buy bags from a general goods vendor, the auction house or a tailor, and put them in the bag slots next to your backpack.",
        help = { "More bag space means fewer trips back to town." } }
end

-- Unspent talent points.
detectors[#detectors + 1] = function(ctx)
    local points = UnspentTalentPoints()
    if not points or points <= 0 or ctx.level < 10 then return nil end
    return { id = "talents", kind = "warn", priority = 85, snooze = "level",
        title = ("You have %d unspent talent point%s"):format(points, points > 1 and "s" or ""),
        detail = "Press N to open your talents and spend them. Each point makes you stronger.",
        help = { "You get a talent point every level from 10.", "Not sure what to pick? Search for a talent guide for your class and stick to one tree at first." } }
end

-- Class trainer not visited since new spells became available.
detectors[#detectors + 1] = function(ctx)
    local m = Memory()
    local level = ctx.level
    if level < 4 then return nil end
    local trained = m.trainerLevel or m.since
    if level - level % 2 <= trained then return nil end
    return { id = "trainer", kind = "warn", priority = 75, snooze = "level",
        title = "Visit your class trainer",
        detail = ("You have not trained since level %d. New spells and ranks wait for you every even level."):format(trained),
        help = { "Class trainers are in every capital city and in many starting towns.", "Ask any guard for directions: they mark it on your map." } }
end

-- New spells sitting in the spellbook.
detectors[#detectors + 1] = function(ctx)
    local missing = ctx.unboundSpells
    if not missing or #missing == 0 then return nil end
    local shown = {}
    for i = 1, math.min(4, #missing) do shown[i] = missing[i] end
    return { id = "spellbar", kind = "tip", priority = 60, snooze = "spells",
        title = "Spells that are not on your action bars",
        detail = table.concat(shown, ", ") .. (#missing > 4 and (" and %d more"):format(#missing - 4) or "") .. ".",
        help = { "Open your spellbook (P) and drag these to an action bar so you can use them.",
            "Right-click this tip to stop hearing about these spells." },
        spells = missing }
end

-- Class quests that give key abilities.
detectors[#detectors + 1] = function(ctx)
    local _, classToken = UnitClass("player")
    for _, milestone in ipairs(ING.ClassMilestones[classToken] or {}) do
        if ctx.level >= milestone.level + 1 and SpellName(milestone.spell) and IsSpellKnown(milestone.spell) == false then
            return { id = "classquest" .. milestone.spell, kind = "tip", priority = 65, snooze = "forever",
                title = ("Class quest: %s"):format(SpellName(milestone.spell)),
                detail = milestone.text,
                help = { "Talk to your class trainer: class quests start there.", "These quests also show up in the quest list (tick \"Class & profession\")." } }
        end
    end
    return nil
end

-- No professions.
detectors[#detectors + 1] = function(ctx)
    if ctx.level < 5 then return nil end
    local count = PrimaryProfessionCount()
    if count == nil or count >= 2 then return nil end
    if count == 0 then
        return { id = "profession0", kind = "tip", priority = 50, snooze = "level",
            title = "You have no profession yet",
            detail = "Learn two professions at a profession trainer. Herbalism, Mining and Skinning earn gold while you quest.",
            help = { "Gathering professions pair well: Herbalism + Alchemy, Mining + Blacksmithing or Engineering, Skinning + Leatherworking.",
                "Ask a city guard for profession trainers." } }
    end
    if ctx.level >= 10 then
        return { id = "profession1", kind = "tip", priority = 20, snooze = "forever",
            title = "You can learn a second profession",
            detail = "Everyone can have two main professions. A second gathering profession is an easy way to earn gold." }
    end
    return nil
end

-- Flight paths never used.
detectors[#detectors + 1] = function(ctx)
    local m = Memory()
    if m.usedFlight or ctx.level < 12 or not Watched(12) then return nil end
    return { id = "flight", kind = "tip", priority = 40, snooze = "forever",
        title = "You have not used a flight path yet",
        detail = "Talk to the flight master in every town you reach. Later you can fly between any two you have found.",
        help = { "Flight masters have a wing/boot icon over their head.", "Flying there costs a bit of money, but saves a lot of running." } }
end

-- Never grouped / never ran a dungeon.
detectors[#detectors + 1] = function(ctx)
    local m = Memory()
    if (m.dungeonRuns or 0) > 0 or ctx.level < 16 or not Watched(16) then return nil end
    local dungeons = DungeonsForLevel(ctx.level)
    if #dungeons == 0 then return nil end
    return { id = "dungeon", kind = "tip", priority = 35, snooze = "level",
        title = "Try a dungeon",
        detail = "You have not done a dungeon yet. For your level: " .. table.concat(dungeons, ", ", 1, math.min(3, #dungeons)) .. ".",
        help = { "Dungeons give good gear and lots of experience.", "Use the Looking For Group tool or ask in chat. Pick up the dungeon's quests first (tick \"Dungeon\" in the list)." } }
end

-- Elite quests but never in a group.
detectors[#detectors + 1] = function(ctx)
    local m = Memory()
    if m.everGrouped or ctx.level < 10 or not Watched(10) then return nil end
    local section = ctx.results and ctx.results.sections[1]
    local elite = 0
    for _, item in ipairs(section and section.items or {}) do
        if item.category == "elite" then elite = elite + 1 end
    end
    if elite == 0 then return nil end
    return { id = "group", kind = "tip", priority = 30, snooze = "level",
        title = "Elite quests are easier in a group",
        detail = ("There are %d elite quests near you. You have not played in a group yet: invite a player doing the same quest."):format(elite),
        help = { "Right-click a player's portrait and choose Invite.", "Everyone in the group gets credit for kills." } }
end

-- Auction house never used while gear is behind.
detectors[#detectors + 1] = function(ctx)
    local m = Memory()
    if m.usedAuction or ctx.level < 18 or not Watched(18) then return nil end
    return { id = "auction", kind = "tip", priority = 25, snooze = "forever",
        title = "Check out the auction house",
        detail = "Players sell gear, bags and materials there, often cheaply. You can also sell your own loot and herbs or ore.",
        help = { "Stormwind, Ironforge and Darnassus (Alliance), Orgrimmar, Thunder Bluff and Undercity (Horde).", "Gadgetzan, Booty Bay and Everlook have neutral ones." } }
end

-- Riding.
detectors[#detectors + 1] = function(ctx)
    local m = Memory()
    if m.everMounted or ctx.level < 40 or not Watched(40) then return nil end
    return { id = "mount", kind = "tip", priority = 55, snooze = "level",
        title = "Time for a mount",
        detail = "Riding becomes available around level 40. A mount makes travelling much faster.",
        help = { "Ask a guard in your capital for the riding trainer of your race.", "Riding is expensive: save gold from quests and selling loot." } }
end

-- Hunter ammo.
detectors[#detectors + 1] = function(ctx)
    local _, classToken = UnitClass("player")
    if classToken ~= "HUNTER" or ctx.level < 6 then return nil end
    local ammoSlot = Call(GetInventorySlotInfo, "AmmoSlot")
    if not ammoSlot then return nil end
    local count = Call(GetInventoryItemCount, "player", ammoSlot)
    if not count or count >= 200 then return nil end
    return { id = "ammo", kind = count == 0 and "urgent" or "warn", priority = 88, snooze = "session",
        title = count == 0 and "You have no ammo!" or ("Low on ammo (%d left)"):format(count),
        detail = "Buy arrows or bullets from a general goods vendor. Without ammo you can't shoot.",
        help = { "Always carry several stacks.", "A quiver or ammo pouch makes you shoot faster." } }
end

-- Dying a lot.
detectors[#detectors + 1] = function()
    local now = GetTime()
    local recent = 0
    for _, t in ipairs(sessionDeaths) do
        if now - t < 15 * 60 then recent = recent + 1 end
    end
    if recent < 3 then return nil end
    return { id = "deaths", kind = "urgent", priority = 95, snooze = "session",
        title = ("You died %d times in the last 15 minutes"):format(recent),
        detail = "Fight one enemy at a time, eat and drink to full between fights, and pick quests a level or two lower.",
        help = { "Pull enemies one by one: attack from range or wait until they walk apart.",
            "Red and orange quests are harder than they look. Green and yellow are comfortable.",
            "Check the gear and trainer tips too: being behind makes everything harder." } }
end

-- Quest log nearly full / grey quests in the log.
detectors[#detectors + 1] = function(ctx)
    local count, max = QuestLogFill()
    if not count or not max or count < max - 2 then return nil end
    return { id = "questlog", kind = "warn", priority = 65, snooze = "session",
        title = ("Your quest log is almost full (%d/%d)"):format(count, max),
        detail = "Finish or abandon old quests so you can take new ones. Grey quests give almost no experience.",
        help = { "Open the quest log (L), select a quest and click Abandon." } }
end

-- No rested experience.
detectors[#detectors + 1] = function(ctx)
    if ctx.level < 10 or ctx.level >= 60 then return nil end
    local exhaustion = Call(GetXPExhaustion)
    if exhaustion and exhaustion > 0 then return nil end
    if Call(IsResting) then return nil end
    return { id = "rested", kind = "tip", priority = 10, snooze = "level",
        title = "Log out at an inn",
        detail = "When you log out in an inn or a city, you build rested experience: double XP from monsters next time you play.",
        help = { "Your experience bar turns blue while you have rested XP." } }
end

-- ============================================================
-- Evaluate
-- ============================================================

local function IsDismissed(tip)
    local m = Memory()
    local mark = m.dismissed[tip.id]
    if tip.snooze == "session" then
        return sessionSnooze[tip.id] ~= nil
    end
    if mark == nil then return false end
    if tip.snooze == "level" then
        return mark >= (ING.playerLevel or UnitLevel("player"))
    end
    return true
end

function Coach.Evaluate(results)
    -- Some values are hidden in combat; keep the last list until it ends.
    if InCombatLockdown() and cache.tips then
        return cache.tips
    end
    Coach.GetGear()
    if dirty.bags then cache.bags = ScanBags(); dirty.bags = false end
    if dirty.spells then cache.unboundSpells = ScanUnboundSpells(); dirty.spells = false end

    local ctx = {
        level = ING.playerLevel or UnitLevel("player"),
        gear = cache.gear, bags = cache.bags, unboundSpells = cache.unboundSpells,
        results = results,
    }
    local tips = {}
    for _, detector in ipairs(detectors) do
        local ok, tip = pcall(detector, ctx)
        if ok and tip and not IsDismissed(tip) then
            tips[#tips + 1] = tip
        elseif not ok then
            geterrorhandler()(tip)
        end
    end
    table.sort(tips, function(a, b) return a.priority > b.priority end)
    cache.tips = tips
    return tips
end

function Coach.Dismiss(tip)
    local m = Memory()
    if tip.spells then
        for _, name in ipairs(tip.spells) do m.dismissedSpells[name] = true end
        Coach.MarkDirty("spells")
    elseif tip.snooze == "session" then
        sessionSnooze[tip.id] = true
    else
        m.dismissed[tip.id] = ING.playerLevel or UnitLevel("player")
    end
    ING.Refresh()
end

function Coach.Reset()
    local m = Memory()
    m.dismissed, m.dismissedSpells = {}, {}
    wipe(sessionSnooze)
    Coach.MarkDirty()
    ING.Refresh()
end

-- ============================================================
-- Tracking events
-- ============================================================

local inDungeon = false

local function CheckInstance()
    local inInstance, instanceType = Call(IsInInstance)
    local nowInDungeon = inInstance and (instanceType == "party" or instanceType == "raid")
    if nowInDungeon and not inDungeon then
        local m = Memory()
        m.dungeonRuns = (m.dungeonRuns or 0) + 1
    end
    inDungeon = nowInDungeon and true or false
end

local tracker = CreateFrame("Frame")
local EVENTS = {
    "TRAINER_SHOW", "TAXIMAP_OPENED", "BANKFRAME_OPENED", "AUCTION_HOUSE_SHOW", "PLAYER_DEAD",
    "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED",
    "UPDATE_INVENTORY_DURABILITY", "BAG_UPDATE_DELAYED", "SPELLS_CHANGED", "ACTIONBAR_SLOT_CHANGED",
    "UPDATE_SHAPESHIFT_FORMS", "PLAYER_REGEN_ENABLED", "CHARACTER_POINTS_CHANGED", "PLAYER_UPDATE_RESTING",
    "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT",
}

function Coach.Start()
    Memory()
    for _, event in ipairs(EVENTS) do
        pcall(tracker.RegisterEvent, tracker, event) -- not every client has every event
    end
    -- Mounting has no reliable event on every client; check now and then.
    C_Timer.NewTicker(10, function()
        if Call(IsMounted) then Memory().everMounted = true end
    end)
    CheckInstance()
end

tracker:SetScript("OnEvent", function(_, event)
    local m = Memory()
    if event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
        -- Item data arrived; only interesting while gear is waiting for it.
        if dirty.gear then ING.RequestRefresh(1) end
        return
    elseif event == "TRAINER_SHOW" then
        -- Profession trainers fire this too; only count class trainers.
        if not Call(_G.IsTradeskillTrainer) then
            m.trainerLevel = UnitLevel("player")
        end
    elseif event == "TAXIMAP_OPENED" then
        m.usedFlight = true
    elseif event == "BANKFRAME_OPENED" then
        m.usedBank = true
    elseif event == "AUCTION_HOUSE_SHOW" then
        m.usedAuction = true
    elseif event == "PLAYER_DEAD" then
        table.insert(sessionDeaths, GetTime())
    elseif event == "GROUP_ROSTER_UPDATE" then
        if Call(IsInGroup) then m.everGrouped = true end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CheckInstance()
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "UPDATE_INVENTORY_DURABILITY" then
        dirty.gear = true
    elseif event == "BAG_UPDATE_DELAYED" then
        dirty.bags = true
    elseif event == "SPELLS_CHANGED" or event == "ACTIONBAR_SLOT_CHANGED" or event == "UPDATE_SHAPESHIFT_FORMS" then
        dirty.spells = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        Coach.MarkDirty()
    end
    ING.RequestRefresh(1)
end)
