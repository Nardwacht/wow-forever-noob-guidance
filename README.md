# Impuls Noob Guidance

> **Made for World of Warcraft: Forever only.** This addon is built for the WoW Forever client (the `_forever_` folder, interface version 16001). It does **not** work on Retail (The War Within / Midnight), Classic Era, Season of Discovery or other Classic versions. The zones, dungeons, level ranges and quest data are all specific to Forever.

A World of Warcraft addon for **WoW Forever** that answers the question every new player has: *"What should I do next?"*

It looks at your character and shows:

- **Which quests you can pick up right now:** quests at your level or up to 5 levels below, that you have not done yet and that your race, class, professions and earlier quests allow.
- **Where to find them**, grouped by zone: your current zone first, with the closest quest givers on top. When your zone has nothing left, it shows the nearest neighbouring zones that still have quests, and how to get there (walk, boat, airship).
- **Where to level next:** the zones a leveling guide suggests for your level and faction, the dungeons that fit your level, and a beginner tip.
- **A coach** that watches how you play and points out what to fix or try: weak or broken gear, full bags, unspent talent points, spells missing from your action bars, class quests you skipped, and game features you have not used yet (flight paths, dungeons, the auction house...).
- **Talent advice:** how your points are spread over your three trees, whether your main tree suits solo leveling, which key talents you have taken or skipped, what to take next, and when a talent reset would help.
- **Profession advice:** skills stuck at their cap, professions you learned but never raised, gathering skill too low for your zones, herb/ore tracking switched off, First Aid without bandages, and ore you could smelt.

Everything is colour-coded by urgency:

| Colour | Meaning | Examples |
| --- | --- | --- |
| 🔴 Red | Act now | Upgrade advised, broken gear, no ammo, dying a lot |
| 🟠 Orange | Soon | Upgrade soon, worn gear, bags full, visit your trainer |
| 🟡 Yellow | Tip | Things you have not tried yet |
| 🟢 Green | Fine | Gear that fits your level |

## Requirements: Questie

**This addon needs [Questie](https://github.com/Questie/Questie) and [QuestieDB](https://github.com/Questie/QuestieDB) installed and enabled.** Without them there is no quest list: the panel and window then say in red which one is the problem and why (not installed, turned off, out of date...), and the same message appears in chat at login.

Why: Impuls Noob Guidance does not ship its own quest list. It reads every quest from Questie's database: quest levels, who gives the quest, where they stand, prerequisites and race/class restrictions. Questie also works out which quests your character has already completed. Using Questie keeps the quest list complete and up to date for WoW Forever without this addon having to maintain thousands of quests by hand.

Install Questie the way you normally install addons (CurseForge, WowUp, or by hand). QuestieDB is a separate addon folder: check that both `Questie` and `QuestieDB` are in your AddOns folder and ticked in the in-game AddOns list.

Optional: if you have [TomTom](https://www.curseforge.com/wow/addons/tomtom), clicking a quest also places a waypoint arrow. If you have Pawn, the coach mentions its upgrade arrows.

## Installation

1. Download this repository (green **Code** button, then **Download ZIP**) or clone it.
2. Put the folder in `World of Warcraft\_forever_\Interface\AddOns\`. Make sure it is the `_forever_` folder, not `_retail_` or `_classic_era_`.
3. **Rename the folder to `ImpulsNoobGuidance`.** WoW only loads an addon whose folder name matches its `.toc` file. A downloaded ZIP is called `wow-forever-noob-guidance`, which will not load.
4. Make sure Questie and QuestieDB are installed too, then restart WoW.

The panel shows "Loading quests..." for a few seconds after login while Questie starts up.

## How to use

- **Minimap button:** left-click opens the full list, right-click shows or hides the small panel. Drag it to move it around the minimap.
- **Small panel:** shows the most important coach tip and the next few quests. Left-click its title for the full list, right-click it to lock or unlock it, and drag it to move it.
- **Quests:** hover one to read its objective. Click it to open the world map on the quest giver's zone.
- **Coach tips:** hover a tip to see how to do it. Right-click it to hide it (until your next level, until you log out, or for good, depending on the tip).
- **Your character** (below the quest list):
  - **Your gear:** your average item level against your level, with each slot labelled **Upgrade advised**, **Upgrade soon**, **OK** or **Repair**. Hover a slot to see the item.
  - **Talents:** points per tree, the tree recommended for leveling, the key talents for it (taken, available now, or how many points until they open), the next talent to take, and whether a reset is worth it.
  - **Professions:** each profession's skill and status (OK, Capped - train, Not used, Low for level), plus what to do about it.
- **Tick boxes** at the top of the window hide dungeon, elite, class/profession quests, or the coach.

## Commands

Type `/ing` (or `/noob`):

| Command | What it does |
| --- | --- |
| `/ing` | Open or close the quest list |
| `/ing panel` | Show or hide the small panel |
| `/ing lock` | Lock or unlock the panel |
| `/ing tips` | Check everything again and list the coach tips in chat |
| `/ing gear` | List your gear with item levels and labels in chat |
| `/ing talents` | Check your talent trees in chat |
| `/ing prof` | Check your professions in chat |
| `/ing below 5` | How many levels below you to include (0-20) |
| `/ing above 0` | How many levels above you to include (0-5) |
| `/ing lines 5` | How many quests the panel shows |
| `/ing coach` | Show or hide the coach tip in the panel |
| `/ing coach reset` | Show every coach tip you hid again |
| `/ing minimap` | Show or hide the minimap button |
| `/ing refresh` | Search again |

## Changelog

### 1.3.1
- Fix: WoW could refuse to load the addon with only "Dependency missing", for example right after Questie or QuestieDB was updated. Questie and QuestieDB are now optional in the `.toc`, so the addon always loads and says exactly which one is missing and what to do.

### 1.3.0
- Talent advice: reads your Forever talent trees and warns when points are spread over trees, when your main tree is not a leveling tree, and when you skipped a key talent. Shows the next talent to take and explains how to reset at your class trainer. Specific talents are only checked when they exist under that name in your client, so renamed Forever talents are never misreported.
- Profession advice: capped skills, professions you learned but never raised, gathering skill too low for your level, herb/ore tracking off, First Aid without bandages, ore to smelt, and a nudge to learn First Aid.
- Gear, talents and professions now sit together below the quest list, so the quests stay at the top.
- New commands: `/ing talents` and `/ing prof`.

### 1.2.0
- Every gear slot gets a label: **Upgrade advised** (armour or weapon 7+ levels below you, or an empty slot), **Upgrade soon** (3-6 levels below), **OK**, plus **Repair** / **Broken - repair** when worn. Rings, trinkets, off-hand and ranged are optional and never "advised".
- One colour code everywhere: gear section, coach tips, panel and chat.
- Gear rows have a coloured bar; the folded gear list shows every red and orange slot.

### 1.1.1
- "Your gear" section in the window, always shown.
- `/ing gear` and `/ing tips` commands; `/ing refresh` also re-checks the coach.
- Fix: gear was read once at login, before item details had loaded, and never again. It now keeps checking until every item has loaded. The "equipment is weak" warning starts at level 10.

### 1.1.0
- The coach: warnings for gear, repairs, bags, talents, trainer visits, quest log, ammo and deaths; tips for features you have not used yet. "Not used yet" tips only appear after the addon has watched you for a few levels.
- Checks the Forever client cannot answer are skipped, never guessed.

### 1.0.0
- First release: quest list by zone, neighbouring-zone fallback, leveling guide, dungeons and tips, window, panel and minimap button.

## Guide data sources

The zone level ranges, the route per faction, neighbouring zones, dungeon level ranges and tips (in `Data\`) were summarised in November 2026 from:

- [warcraft.wiki.gg: World of Warcraft: Forever](https://warcraft.wiki.gg/wiki/World_of_Warcraft:_Forever), plus its pages for Zephras Isle, Riverglades, Shen'dralas and Mount Hyjal
- [wowforeverleveling.com: Forever leveling zones](https://wowforeverleveling.com/guides/forever-leveling-zones)
- [forg.gg: Forever leveling](https://forg.gg/en/forever/leveling)

Those guides say level ranges above 30 were still a plan when they were written, so treat them as a direction, not a rule. The quest list itself always comes from QuestieDB.

The leveling talent trees and key talents per class (`Data\Talents.lua`) were summarised on 21 November 2026 from:

- [allthings.how: WoW Forever best leveling spec](https://allthings.how/wow-forever-best-leveling-spec/)
- [wowforevertierlist.com: leveling builds](https://wowforevertierlist.com/builds/leveling) (which summarises Method, Warcraft Tavern, Mobalytics, Icy Veins and others)
- [Method: WoW Forever warlock leveling guide](https://www.method.gg/wow-forever/wow-forever-warlock-leveling-guide-and-talents)

Forever changed many talents compared with original Classic, and those guides only tested builds up to level 30. Talent advice is a starting point, not the only right way to play. The tree IDs come from LibSpecialization (bundled with DBM).
