Impuls Noob Guidance 1.2.0
==========================

NEW IN 1.2.0
- Every gear slot gets a label: "Upgrade advised" (armour/weapon 7+ levels
  below you, or an empty slot), "Upgrade soon" (3-6 levels below), "OK",
  plus "Repair" / "Broken - repair" when worn. Rings, trinkets, off-hand and
  ranged are optional and never "advised".
- One colour code everywhere (gear section, coach tips, panel, chat):
    red    = act now (upgrade advised, broken gear, no ammo, dying a lot)
    orange = soon (upgrade soon, worn gear, bags full, trainer, talents...)
    yellow = tip (things you have not tried yet)
    green  = fine
- Gear rows have a coloured bar on the left; the folded gear list shows
  every red and orange slot.

NEW IN 1.1.1
- "Your gear" section in the window, always shown (under the Coach tips):
  your average item level against your level (good / a little behind /
  far behind), empty slots, the most worn item, and your weakest slots with
  their item level. "[ show every slot ]" lists all 17 slots; hover one for
  the item tooltip.
- /ing gear lists your gear with item levels in chat.
- /ing tips checks everything again right now (gear, bags, spells) and lists
  the coach tips in chat. /ing refresh now re-checks the coach too.
- Fix: the gear check read your items once at login, often before the game
  had loaded their details, and then never looked again. It now keeps
  checking until every item is loaded. The "equipment is weak" warning now
  starts at level 10 instead of 12.

NEW IN 1.1.0: the Coach
- Looks at your character and how you play, and shows tips at the top of the
  window (and the most important one in the panel):
  * Warnings: broken or worn gear, gear far below your level (with your
    weakest slots and where to upgrade), empty equipment slots, bags almost
    full, unspent talent points, class trainer not visited since new spells,
    quest log almost full, low hunter ammo, dying a lot in a short time.
  * Things you have not used yet: spells that are not on your action bars,
    class quests for key abilities (hunter pet, warrior stances, shaman
    totems...), professions, flight paths, dungeons, playing in a group,
    the auction house, riding at 40, rested experience.
- "Not used yet" tips only appear after the addon has watched you for a few
  levels, so a character that installed it later is not told about things
  it already knows.
- Hover a tip for how to do it. Right-click a tip to hide it (until your next
  level, until you log out, or for good, depending on the tip).
- "Coach" tick in the window hides the tips. /ing coach hides the panel line,
  /ing coach reset brings every hidden tip back.
- Checks the game can't answer on this client are skipped, never guessed.

Shows every quest you can pick up right now: quests of your level and up to
5 levels below, that you have not done yet and that your race, class,
professions and earlier quests allow. They are grouped by zone:

1. Your current zone first, sorted easy-to-find first (closest quest giver).
2. When your zone has nothing left, the closest neighbouring zones that still
   have quests, with how to get there (walk, boat, airship).
3. Always: the guide's zones and dungeons for your level, and a beginner tip.

Needs Questie and QuestieDB (they supply the quest database).

How to use
----------
- Minimap button: left-click opens the list, right-click shows/hides the panel.
- The small panel shows the next few quests. Left-click its title for the
  full list, right-click it to lock/unlock, drag to move.
- Hover a quest to read its objective. Click it to open the world map on the
  quest giver's zone (and set a TomTom arrow if you have TomTom).
- Ticks at the top of the window hide dungeon, elite or class/profession
  quests.

Commands: /ing (or /noob)
  /ing            open or close the list
  /ing panel      show or hide the panel
  /ing lock       lock or unlock the panel
  /ing below 5    how many levels below you to include (0-20)
  /ing above 0    how many levels above you to include (0-5)
  /ing lines 5    quests shown in the panel
  /ing tips       check everything again and list the coach tips in chat
  /ing gear       list your gear with item levels in chat
  /ing coach      show or hide the coach tip in the panel
  /ing coach reset  show every hidden coach tip again
  /ing minimap    show or hide the minimap button
  /ing refresh    search again

Guide data sources (November 2026)
----------------------------------
Zone level ranges, the per-faction route, neighbouring zones, dungeon level
ranges and tips are summarised in Data\Zones.lua and Data\Tips.lua from:
- https://warcraft.wiki.gg/wiki/World_of_Warcraft:_Forever (and its pages for
  Zephras Isle, Riverglades, Shen'dralas and Mount Hyjal)
- https://wowforeverleveling.com/guides/forever-leveling-zones
- https://forg.gg/en/forever/leveling
Those guides say ranges above level 30 were still a plan when written, so
they are only a direction. The quest list itself always comes from QuestieDB.
