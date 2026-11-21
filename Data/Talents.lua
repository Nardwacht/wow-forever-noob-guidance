local _, ING = ...

-- Leveling talent advice per class for WoW Forever.
--
-- Forever keeps the three trees per class, but stores them as "groups" of
-- one talent tree; the group IDs below come from LibSpecialization (shipped
-- with DBM), which reads Forever's talents the same way.
--
-- Recommendations were compiled on 21 November 2026 from:
--   allthings.how/wow-forever-best-leveling-spec (8 Nov 2026)
--   wowforevertierlist.com/builds/leveling (18 Nov 2026, summarising Method,
--     Warcraft Tavern, Mobalytics, Icy Veins and others)
--   method.gg Forever warlock leveling guide (16 Nov 2026)
-- The guides only tested routes to level 30; later picks are their plans.
--
-- leveling:  the tree most guides recommend for solo leveling
-- alsoFine:  trees that are a reasonable choice too (with why)
-- key:       important talents in the leveling tree. `points` = points the
--            tree needs before the talent opens. Names are English and only
--            checked when the talent exists under that name in your client
--            (an English client), so a renamed talent is never reported.

ING.TalentTrees = {
    WARRIOR = {
        trees = { [11650] = "Arms", [11657] = "Fury", [11670] = "Protection" },
        leveling = 11650,
        alsoFine = { [11670] = "solo with a one-hander and shield (Method)" },
        key = {
            { name = "Improved Rend", points = 0 },
            { name = "Deep Wounds", points = 10 },
            { name = "Sweeping Strikes", points = 20 },
            { name = "Mortal Strike", points = 30 },
        },
        note = "Warriors start slow. Victory Rush (level 20) heals you after kills: use it.",
    },
    PALADIN = {
        trees = { [11486] = "Holy", [11541] = "Protection", [11559] = "Retribution" },
        leveling = 11559,
        alsoFine = { [11541] = "tanking dungeons", [11486] = "healing groups" },
        key = {
            { name = "Benediction", points = 0 },
            { name = "Pursuit of Justice", points = 10 },
            { name = "Sacred Arbiter", points = 15 },
            { name = "Vengeance", points = 20 },
        },
        note = "Retribution has no interrupt or slow: keep pulls to one or two enemies.",
    },
    HUNTER = {
        trees = { [11372] = "Beast Mastery", [11371] = "Marksmanship", [11370] = "Survival" },
        leveling = 11372,
        alsoFine = { [11371] = "groups (Warcraft Tavern)" },
        key = {
            { name = "Endurance Training", points = 0 },
            { name = "Focused Fire", points = 5 },
            { name = "Unleashed Fury", points = 10 },
            { name = "Ferocity", points = 15 },
            { name = "Bestial Wrath", points = 30 },
        },
        note = "Beast Mastery makes your pet tank while you shoot: pet health and damage talents first.",
    },
    ROGUE = {
        trees = { [11580] = "Assassination", [11573] = "Combat", [11572] = "Subtlety" },
        leveling = 11573,
        alsoFine = { [11580] = "also a good leveling tree" },
        key = {
            { name = "Precision", points = 5 },
            { name = "Flawless Execution", points = 15 },
            { name = "Blade Flurry", points = 20 },
            { name = "Adrenaline Rush", points = 30 },
        },
        note = "Rogues have no self-heal: eat between fights. Subtlety is the weakest leveling tree.",
    },
    PRIEST = {
        trees = { [11608] = "Discipline", [11615] = "Holy", [11622] = "Shadow" },
        leveling = 11622,
        alsoFine = { [11608] = "before level 40 (Method: Discipline first, Shadow at 40)" },
        -- Method's priest route mixes Discipline and Shadow before 40.
        splitOkBefore = 40, splitTrees = { [11608] = true, [11622] = true },
        key = {
            { name = "Spirit Tap", points = 0 },
            { name = "Mind Flay", points = 10 },
            { name = "Vampiric Embrace", points = 15 },
            { name = "Shadowform", points = 30 },
        },
        note = "Priests are fragile: keep pulls small and use Power Word: Shield before each fight.",
    },
    SHAMAN = {
        trees = { [11326] = "Elemental", [11363] = "Enhancement", [11362] = "Restoration" },
        leveling = 11363,
        alsoFine = { [11362] = "healing groups" },
        key = {
            { name = "Thundering Strikes", points = 0 },
            { name = "Shamanistic Focus", points = 10 },
            { name = "Elemental Weapons", points = 10 },
            { name = "Stormstrike", points = 15 },
            { name = "Flurry", points = 15 },
        },
        note = "Every guide picks Enhancement for leveling. Wear Strength/Attack Power gear.",
    },
    MAGE = {
        trees = { [11582] = "Arcane", [11594] = "Fire", [11601] = "Frost" },
        leveling = 11601,
        alsoFine = { [11582] = "more solo damage, less safe (Method)" },
        key = {
            { name = "Improved Frostbolt", points = 0 },
            { name = "Ice Shards", points = 5 },
            { name = "Frostbite", points = 5 },
            { name = "Shatter", points = 15 },
            { name = "Ice Block", points = 15 },
        },
        note = "Frost slows and freezes keep enemies away from you. Fire is weak before level 30.",
    },
    WARLOCK = {
        trees = { [11629] = "Affliction", [11636] = "Demonology", [11637] = "Destruction" },
        leveling = 11629,
        alsoFine = { [11636] = "comes online later (Method)", [11637] = "viable (Method)" },
        key = {
            { name = "Suppression", points = 0 },
            { name = "Improved Corruption", points = 0 },
            { name = "Fel Concentration", points = 10 },
            { name = "Nightfall", points = 15 },
            { name = "Shadow Mastery", points = 25 },
        },
        note = "Let your Voidwalker take the hits while your damage over time spells work.",
    },
    DRUID = {
        trees = { [11328] = "Balance", [11347] = "Feral Combat", [11340] = "Restoration" },
        leveling = 11347,
        alsoFine = { [11340] = "healing groups" },
        key = {
            { name = "Ferocity", points = 0 },
            { name = "Furor", points = 0 },
            { name = "Feral Swiftness", points = 5 },
            { name = "Sharpened Claws", points = 10 },
            { name = "Predatory Strikes", points = 15 },
            { name = "Leader of the Pack", points = 20 },
        },
        note = "Cat Form for questing, Bear Form when you pull too much. Balance is weak until Moonkin Form.",
    },
}
