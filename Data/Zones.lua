local _, ING = ...

-- Guide data for every leveling zone, keyed by QuestieDB AreaID.
--
-- Level ranges are guide estimates, compiled in November 2026 from
-- warcraft.wiki.gg (World of Warcraft: Forever and its zone pages),
-- wowforeverleveling.com (Forever leveling zones) and forg.gg (Forever
-- leveling). Those sources say ranges above level 30 were still a plan when
-- they were written, so treat them as a rough direction, not a rule.
--
-- faction: "A" = Alliance zone, "H" = Horde zone, "B" = both factions quest here.
-- neighbours: { areaId, "how you get there" }. Used to look further when the
-- current zone has no quests left. Boats, zeppelins and airships count too.
-- city: the zone a capital city belongs to, so its neighbours are used.

local Z = {}
ING.Zones = Z

local function zone(id, data)
    data.id = id
    Z[id] = data
end

-- ============================================================
-- Starting zones (1-12)
-- ============================================================
zone(12, { name = "Elwynn Forest", min = 1, max = 12, faction = "A",
    neighbours = { {40, "walk west"}, {10, "walk south"}, {44, "walk east"}, {1519, "walk north-west"} },
    tip = "Human starting zone. Goldshire is the main town; Stormwind is just to the north-west." })
zone(1, { name = "Dun Morogh", min = 1, max = 12, faction = "A",
    neighbours = { {38, "walk east through the tunnel"}, {1537, "walk into Ironforge"} },
    tip = "Dwarf and gnome starting zone. Kharanos is the main town. Hall of Thanes (13-20) is in Ironforge." })
zone(141, { name = "Teldrassil", min = 1, max = 12, faction = "A",
    neighbours = { {148, "boat from Rut'theran Village to Auberdine"}, {1657, "Darnassus is in the west of the island"} },
    tip = "Night elf starting zone. Dolanaar is the main town. Take the boat to Darkshore around level 11-12." })
zone(14, { name = "Durotar", min = 1, max = 12, faction = "H",
    neighbours = { {17, "walk west over the bridge"}, {1637, "walk north into Orgrimmar"} },
    tip = "Orc and troll starting zone. Razor Hill is the main town. Ragefire Chasm (about 13) is inside Orgrimmar." })
zone(215, { name = "Mulgore", min = 1, max = 12, faction = "H",
    neighbours = { {17, "walk east"}, {1638, "Thunder Bluff is in the north"}, {16593, "airship from Skywatcher Plateau"}, {16651, "border to the west"} },
    tip = "Tauren starting zone. Bloodhoof Village is the main town. The airship to Zephras Isle leaves from Skywatcher Plateau." })
zone(85, { name = "Tirisfal Glades", min = 1, max = 12, faction = "H",
    neighbours = { {130, "walk south"}, {1497, "Undercity is in the east"}, {28, "walk east (high level!)"} },
    tip = "Undead starting zone. Brill is the main town. Ruins of Lordaeron (15-22) is reached from Undercity." })
zone(16593, { name = "Zephras Isle", min = 1, max = 12, faction = "B",
    neighbours = { {36, "Alliance airship from Valanaar to Dalaran"}, {215, "Horde airship from Valanaar to Mulgore"} },
    tip = "Skyborne starting zone, a flying island in Skywall. Valanaar is the big neutral town; the airships leave from the Valanaar Skydocks." })

-- ============================================================
-- 12-20
-- ============================================================
zone(40, { name = "Westfall", min = 12, max = 20, faction = "A",
    neighbours = { {12, "walk east"}, {10, "walk south-east"} },
    tip = "Sentinel Hill is the main town. The Deadmines dungeon (about 17-24) is in Moonbrook." })
zone(38, { name = "Loch Modan", min = 12, max = 20, faction = "A",
    neighbours = { {1, "walk west"}, {11, "walk north through Dun Algaz"}, {3, "walk south-east"} },
    tip = "Thelsamar is the main town. Go north to the Wetlands later on." })
zone(148, { name = "Darkshore", min = 12, max = 20, faction = "A",
    neighbours = { {331, "walk south"}, {141, "boat from Auberdine"}, {11, "boat from Auberdine to Menethil Harbor"}, {1519, "boat from Auberdine to Stormwind Harbor"} },
    tip = "Auberdine is the main town and harbour. Boats go to Teldrassil, Menethil Harbor and Stormwind." })
zone(130, { name = "Silverpine Forest", min = 12, max = 20, faction = "H",
    neighbours = { {85, "walk north"}, {267, "walk south-east"} },
    tip = "The Sepulcher is the main Horde town. Shadowfang Keep (about 22-30) is in the south." })
zone(17, { name = "The Barrens", min = 12, max = 25, faction = "H",
    neighbours = { {14, "walk east"}, {215, "walk west"}, {331, "walk north"}, {406, "walk north-west"}, {400, "walk south"}, {15, "walk east of the south road"}, {33, "boat from Ratchet to Booty Bay"} },
    tip = "The Crossroads is the main town. Wailing Caverns (about 18) is in the middle; Ratchet has a boat to Booty Bay." })
zone(44, { name = "Redridge Mountains", min = 15, max = 25, faction = "A",
    neighbours = { {12, "walk west"}, {10, "walk south-west"}, {46, "walk north (high level!)"}, {16591, "walk east through Redridge Pass"} },
    tip = "Lakeshire is the main town. Riverglades lies to the east through Redridge Pass." })

-- ============================================================
-- 20-30
-- ============================================================
zone(267, { name = "Hillsbrad Foothills", min = 20, max = 32, faction = "B",
    neighbours = { {130, "walk west"}, {36, "walk north"}, {45, "walk east"}, {47, "walk east past Durnholde"} },
    tip = "Southshore (Alliance) and Tarren Mill (Horde). Pick up the City of Dalaran attunement here in your 20s." })
zone(10, { name = "Duskwood", min = 20, max = 30, faction = "A",
    neighbours = { {12, "walk north"}, {40, "walk west"}, {44, "walk north-east"}, {33, "walk south"}, {41, "walk east"} },
    tip = "Darkshire is the main town. Many quests here are long story chains; worth finishing." })
zone(11, { name = "Wetlands", min = 20, max = 30, faction = "A",
    neighbours = { {38, "walk south"}, {45, "walk north over Thandol Span"}, {148, "boat from Menethil Harbor to Auberdine"}, {15, "boat from Menethil Harbor to Theramore"} },
    tip = "Menethil Harbor is the main town. Excavation Site: Wetlands (about 24-33) is a new dungeon here." })
zone(331, { name = "Ashenvale", min = 20, max = 30, faction = "B",
    neighbours = { {148, "walk north"}, {17, "walk south"}, {406, "walk south-west"}, {361, "walk north-east"}, {16, "walk east"} },
    tip = "Astranaar (Alliance) and Splintertree Post (Horde). Blackfathom Deeps (about 24-28) is on the west coast." })
zone(406, { name = "Stonetalon Mountains", min = 20, max = 30, faction = "B",
    neighbours = { {331, "walk east"}, {17, "walk south-east"}, {405, "walk south-west"} },
    tip = "Stonetalon Peak (Alliance) and Sun Rock Retreat (Horde)." })
zone(400, { name = "Thousand Needles", min = 25, max = 35, faction = "H",
    neighbours = { {17, "walk north"}, {357, "walk west"}, {440, "walk south-east"} },
    tip = "Freewind Post is the Horde town. Razorfen Kraul and Razorfen Downs are on the northern edge." })

-- ============================================================
-- 30-40
-- ============================================================
zone(36, { name = "Alterac Mountains", min = 30, max = 40, faction = "B",
    neighbours = { {267, "walk south"}, {130, "walk west"}, {28, "walk east"}, {16593, "Alliance airship from Dalaran"} },
    tip = "Home of the City of Dalaran dungeon (28-35). The Alliance airship to Zephras Isle leaves from Dalaran." })
zone(33, { name = "Stranglethorn Vale", min = 30, max = 45, faction = "B",
    neighbours = { {10, "walk north"}, {17, "boat from Booty Bay to Ratchet"} },
    tip = "Booty Bay (neutral) in the south. The Drowned City (35-42) is a new dungeon here." })
zone(405, { name = "Desolace", min = 30, max = 40, faction = "B",
    neighbours = { {406, "walk north-east"}, {357, "walk south"}, {16651, "walk south-east through the Valley of Bones"} },
    tip = "Nijel's Point (Alliance) and Shadowprey Village (Horde). Maraudon (about 46-55) is here." })
zone(45, { name = "Arathi Highlands", min = 30, max = 40, faction = "B",
    neighbours = { {11, "walk south over Thandol Span"}, {267, "walk west"}, {47, "walk north-east"} },
    tip = "Refuge Pointe (Alliance) and Hammerfall (Horde)." })
zone(15, { name = "Dustwallow Marsh", min = 35, max = 45, faction = "B",
    neighbours = { {17, "walk west"}, {11, "boat from Theramore to Menethil Harbor"} },
    tip = "Theramore (Alliance) and Brackenwall Village (Horde). Alcaz Prison (48-55) is a new dungeon on Alcaz Island." })
zone(16591, { name = "Riverglades", min = 35, max = 45, faction = "B",
    neighbours = { {44, "walk west through Redridge Pass"}, {3, "walk north-west"}, {8, "walk south"}, {46, "walk west (high level!)"}, {440, "boat from Powderfuse Port to Tanaris"} },
    tip = "New Forever zone. Farholde Keep (Alliance), Rog'mar (Horde), Powderfuse Port (neutral boats). Krol'dok Stronghold (40-47) is here." })
zone(16651, { name = "Shen'dralas", min = 35, max = 45, faction = "B",
    neighbours = { {405, "walk north-west through the Valley of Bones"}, {357, "border to the south-west"}, {215, "border to the east"} },
    tip = "New Forever zone between Desolace, Feralas and Mulgore. No big town; check what quests the guide shows." })
zone(8, { name = "Swamp of Sorrows", min = 35, max = 45, faction = "B",
    neighbours = { {41, "walk west"}, {4, "walk south"}, {16591, "walk north"} },
    tip = "Stonard is the Horde town. The Sunken Temple (about 50-60) is here." })

-- ============================================================
-- 40-50
-- ============================================================
zone(3, { name = "Badlands", min = 35, max = 45, faction = "B",
    neighbours = { {38, "walk north-west"}, {51, "walk west"}, {16591, "walk south-east"} },
    tip = "Kargath (Horde). Uldaman (about 41-51) is in the north." })
zone(440, { name = "Tanaris", min = 40, max = 50, faction = "B",
    neighbours = { {400, "walk north"}, {490, "walk west"}, {1377, "walk west past Un'Goro"}, {16591, "boat from Steamwheedle Port to Riverglades"} },
    tip = "Gadgetzan (neutral) is the main town. Zul'Farrak (about 44-54) is in the north-west." })
zone(357, { name = "Feralas", min = 40, max = 50, faction = "B",
    neighbours = { {405, "walk north"}, {400, "walk east"}, {16651, "border to the north-east"} },
    tip = "Feathermoon Stronghold (Alliance, island) and Camp Mojache (Horde). Dire Maul (about 54-60) is here." })
zone(47, { name = "The Hinterlands", min = 40, max = 50, faction = "B",
    neighbours = { {267, "walk west"}, {45, "walk south-west"} },
    tip = "Aerie Peak (Alliance) and Revantusk Village (Horde)." })
zone(51, { name = "Searing Gorge", min = 45, max = 50, faction = "B",
    neighbours = { {38, "gate from Loch Modan"}, {3, "walk east"}, {46, "walk south through Blackrock Mountain"} },
    tip = "Thorium Point (neutral). Blackrock Mountain sits between here and the Burning Steppes." })
zone(16, { name = "Azshara", min = 45, max = 55, faction = "B",
    neighbours = { {331, "walk west"} },
    tip = "Few towns. Blackmaw Hold (55-60) is a new dungeon here." })
zone(4, { name = "Blasted Lands", min = 45, max = 55, faction = "B",
    neighbours = { {8, "walk north"} },
    tip = "Nethergarde Keep (Alliance). Mostly collection quests that give nice buffs." })

-- ============================================================
-- 50-60
-- ============================================================
zone(46, { name = "Burning Steppes", min = 50, max = 58, faction = "B",
    neighbours = { {51, "walk north through Blackrock Mountain"}, {44, "walk south"}, {16591, "walk east"} },
    tip = "Morgan's Vigil (Alliance) and Flame Crest (Horde). Blackrock Depths and Spire are here." })
zone(361, { name = "Felwood", min = 50, max = 55, faction = "B",
    neighbours = { {331, "walk south"}, {618, "walk north through Timbermaw Hold"}, {493, "walk north (Moonglade)"} },
    tip = "Talonbranch Glade (Alliance) and Bloodvenom Post (Horde)." })
zone(490, { name = "Un'Goro Crater", min = 50, max = 55, faction = "B",
    neighbours = { {440, "walk east"}, {1377, "walk west"} },
    tip = "Marshal's Refuge (neutral). Shaper's Terrace (58-60) is a new dungeon here." })
zone(28, { name = "Western Plaguelands", min = 50, max = 58, faction = "B",
    neighbours = { {85, "walk west"}, {36, "walk south-west"}, {139, "walk east"} },
    tip = "Chillwind Camp (Alliance) and The Bulwark (Horde). Scholomance is here." })
zone(139, { name = "Eastern Plaguelands", min = 53, max = 60, faction = "B",
    neighbours = { {28, "walk west"} },
    tip = "Light's Hope Chapel (neutral). Stratholme is here." })
zone(618, { name = "Winterspring", min = 55, max = 60, faction = "B",
    neighbours = { {361, "walk south through Timbermaw Hold"}, {616, "walk east through Darkwhisper Gorge"} },
    tip = "Everlook (neutral) is the main town." })
zone(1377, { name = "Silithus", min = 55, max = 60, faction = "B",
    neighbours = { {490, "walk east"}, {440, "walk east"} },
    tip = "Cenarion Hold (neutral)." })
zone(616, { name = "Mount Hyjal", min = 55, max = 60, faction = "B",
    neighbours = { {618, "walk west through Darkwhisper Gorge"} },
    tip = "New Forever end-game zone. Home of the Barrow Deeps and Hyjal Summit raids." })

-- ============================================================
-- Capital cities: quests in a city count for the city itself; when
-- they run out the city's own zone and its neighbours are used.
-- ============================================================
zone(1519, { name = "Stormwind City", city = 12, faction = "A", neighbours = { {12, "walk out the main gate"} } })
zone(1537, { name = "Ironforge", city = 1, faction = "A", neighbours = { {1, "walk out the main gate"} } })
zone(1657, { name = "Darnassus", city = 141, faction = "A", neighbours = { {141, "walk out of the city"} } })
zone(1637, { name = "Orgrimmar", city = 14, faction = "H", neighbours = { {14, "walk out the main gate"}, {17, "west gate"} } })
zone(1638, { name = "Thunder Bluff", city = 215, faction = "H", neighbours = { {215, "take the lift down"} } })
zone(1497, { name = "Undercity", city = 85, faction = "H", neighbours = { {85, "take the lift up"} } })

-- Smaller areas that are not leveling zones but can still hold quest givers.
zone(41, { name = "Deadwind Pass", min = 50, max = 60, faction = "B",
    neighbours = { {10, "walk west"}, {8, "walk east"} } })
zone(493, { name = "Moonglade", min = 1, max = 60, faction = "B",
    neighbours = { {361, "walk south"}, {618, "walk east"} } })

-- Suggested route per faction, in order, used for "where should I level?".
-- Each step lists the zones for that level bracket.
ING.Route = {
    A = {
        { min = 1,  max = 12, zones = { 12, 1, 141, 16593 } },
        { min = 12, max = 20, zones = { 40, 38, 148, 44 } },
        { min = 20, max = 30, zones = { 44, 10, 11, 331, 406 } },
        { min = 30, max = 40, zones = { 267, 33, 405, 45, 15, 16591 } },
        { min = 40, max = 50, zones = { 3, 440, 357, 47, 16591, 16651 } },
        { min = 50, max = 60, zones = { 51, 361, 490, 618, 28, 1377, 616 } },
    },
    H = {
        { min = 1,  max = 12, zones = { 14, 215, 85, 16593 } },
        { min = 12, max = 20, zones = { 130, 17 } },
        { min = 20, max = 30, zones = { 17, 267, 406, 331, 400 } },
        { min = 30, max = 40, zones = { 400, 33, 405, 45, 15, 16591 } },
        { min = 40, max = 50, zones = { 3, 440, 357, 47, 16591, 16651 } },
        { min = 50, max = 60, zones = { 361, 490, 16, 139, 1377, 616 } },
    },
}

-- Dungeons that fit a level, with the zone their entrance is in.
ING.Dungeons = {
    { name = "Ragefire Chasm",            min = 13, max = 18, faction = "H", where = "Orgrimmar" },
    { name = "Hall of Thanes",            min = 13, max = 20, faction = "A", where = "Ironforge" },
    { name = "Ruins of Lordaeron",        min = 15, max = 22, faction = "H", where = "Undercity" },
    { name = "The Deadmines",             min = 17, max = 24, faction = "A", where = "Westfall" },
    { name = "Wailing Caverns",           min = 17, max = 24, faction = "B", where = "The Barrens" },
    { name = "Shadowfang Keep",           min = 22, max = 30, faction = "B", where = "Silverpine Forest" },
    { name = "The Stockade",              min = 22, max = 30, faction = "A", where = "Stormwind City" },
    { name = "Blackfathom Deeps",         min = 24, max = 32, faction = "B", where = "Ashenvale" },
    { name = "Excavation Site: Wetlands", min = 26, max = 33, faction = "B", where = "Wetlands" },
    { name = "City of Dalaran",           min = 28, max = 35, faction = "B", where = "Alterac Mountains (attunement first)" },
    { name = "Gnomeregan",                min = 29, max = 38, faction = "B", where = "Dun Morogh" },
    { name = "Razorfen Kraul",            min = 29, max = 38, faction = "B", where = "The Barrens / Thousand Needles" },
    { name = "Scarlet Monastery",         min = 30, max = 45, faction = "B", where = "Tirisfal Glades" },
    { name = "The Drowned City",          min = 35, max = 42, faction = "B", where = "Stranglethorn Vale" },
    { name = "Razorfen Downs",            min = 37, max = 46, faction = "B", where = "Thousand Needles" },
    { name = "Krol'dok Stronghold",       min = 40, max = 47, faction = "B", where = "Riverglades" },
    { name = "Uldaman",                   min = 41, max = 51, faction = "B", where = "Badlands" },
    { name = "Zul'Farrak",                min = 44, max = 54, faction = "B", where = "Tanaris" },
    { name = "Maraudon",                  min = 46, max = 55, faction = "B", where = "Desolace" },
    { name = "Alcaz Prison",              min = 48, max = 55, faction = "B", where = "Dustwallow Marsh" },
    { name = "Sunken Temple",             min = 50, max = 60, faction = "B", where = "Swamp of Sorrows" },
    { name = "Blackrock Depths",          min = 52, max = 60, faction = "B", where = "Blackrock Mountain" },
    { name = "Dire Maul",                 min = 54, max = 60, faction = "B", where = "Feralas" },
    { name = "Blackmaw Hold",             min = 55, max = 60, faction = "B", where = "Azshara" },
    { name = "Shaper's Terrace",          min = 58, max = 60, faction = "B", where = "Un'Goro Crater" },
}
