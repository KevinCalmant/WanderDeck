#!/usr/bin/env python3
"""Generate WanderDeck card files from the AzerothCore world database.

Writes one Data/Generated/<ZoneName>.lua per shipped zone (the 40 vanilla
outdoor zones, ZONES). Each file calls
    ns.Cards.addCards(<zoneMapID>, { ... }, "generated")
after the zone's hand-written Data/<continent>/<ZoneName>.lua (Data/load_data.xml
sets the order). A missing hand-written file only prints a warning: the zone
then gets the full TARGET_TOTAL generated cards.
Dev tool only: scripts/ is excluded from releases by .pkgmeta.

Source
  AzerothCore world database, https://github.com/azerothcore/azerothcore-wotlk,
  folder data/sql/base/db_world/. Read as plain text, never executed:
  creature.sql, creature_template.sql, creature_queststarter.sql,
  quest_template.sql, quest_template_addon.sql, item_template.sql,
  creature_loot_template.sql, game_event_creature.sql, instance_encounters.sql.
  Only facts are kept (English names, IDs, levels, types, ranks, quality);
  descriptions and quest text are never read into the output.

  creature.sql leaves zoneId/areaId at 0 for almost every spawn, so a spawn's
  zone comes from its map and position: ZONE_RECTS below are the world-space
  rectangles of the Classic client's UiMapAssignment table (wago.tools, product
  wow_classic_era, rounded to 0.1 yd). Rectangles of neighbouring zones
  overlap; a spawn goes to the containing zone whose centre is nearest in
  distance normalized by the rectangle's half sizes (checked against quest
  sort IDs: the best of max-norm, plain distance and smallest rectangle), and
  a creature template goes to the zone holding most of its spawns. Folded
  cities (CITY_PARENT) count for their zone; dungeons are matched by map ID
  (DUNGEON_MAPS, entrance zone; raids are not listed and count for no zone).
  For the 33 newer zones a plain hostile creature's spawn goes to the best
  containing zone whose level window (LEVEL_FLOOR to LEVEL_CAP) holds its
  level, so Un'Goro gorillas inside the Thousand Needles rectangle count for
  Un'Goro. FROZEN_ZONES (the first 7 zones) keep the placement above unchanged
  and only skip names hand-written in frozen zones, so their files stay as
  they were; a card one of them already shows is not generated again for a
  newer zone. The script refuses to drop a card ID from an existing generated
  file (players would lose the card) unless --allow-removed-ids is given.

Filters (an entity failing one is skipped)
  Creatures: spawns that are event-only (game_event_creature with a positive
  event) or out of phase 1; type not 1-9 (totems, pets, gas clouds, none);
  names or subnames with trigger/bunny/[DND]/invisible/dummy/totem/... words;
  flags_extra TRIGGER (0x80), GHOST_VISIBILITY (0x400) or WORLDEVENT (0x4000);
  unit_flags NOT_SELECTABLE (0x02000000), on the template or the spawn;
  min/max level outside 1-63 (no "??" bosses, no level 80 WotLK NPCs); entry
  >= 16000 (TBC/WotLK additions; vanilla faction leaders at 61-63 stay);
  non-NPC creatures above the zone's level cap (LEVEL_CAP, catches
  neighbour-zone mobs at rectangle borders; dungeons and folded cities have
  no cap) or, in a newer zone, non-critter ones below its floor
  (LEVEL_FLOOR); world bosses (WORLD_BOSSES, and any outdoor rank 3 creature
  that is neither quest giver nor service NPC); border strays: outdoor
  creatures whose kept quests (started by them, or asking to kill them) are
  mostly sorted to another outdoor zone and none to theirs. One card per
  name: boss > elite > rare > npc > creature, then most spawns, then lowest
  entry.
  Quests: started (creature_queststarter) by a creature of the zone, ID < 9300,
  QuestLevel and MinLevel <= 60, not repeatable (SpecialFlags & 1), not daily
  or weekly, not a world-event or PvP quest, not a holiday sort, not sorted to
  a raid or battleground (SKIPPED_QUEST_AREAS), one per name.
  Items: green or better (quality 2-4) rewards of those quests, and direct
  (non-reference) loot of the zone's creatures; no random enchantment
  (RandomProperty/RandomSuffix), weapons and armor only (no recipes, gems,
  trade goods or quest items), required level <= 60, entry < 24000.
  Names: 1-64 bytes of printable ASCII without "|" (anything else is skipped,
  which also satisfies ns.Utils.isCleanText). Entities whose English name
  matches a hand-written card (of any zone: it already exists as a card),
  case-insensitive, are skipped, and so is a card whose ID a hand-written
  card already uses. A newer zone also skips any name or npc/quest/item ID
  already generated for another zone (frozen zones first, then ZONE_ORDER).
  Spawns in EXCLUDED_BOXES (Stormwind Harbor, a WotLK addition) and mount
  vendor display models ("Riding" names) too.

Heuristics
  kind/rarity (creature_kind): boss (rank 3, flags_extra DUNGEON_BOSS
  0x10000000, or the kill credit of an instance_encounters row: vanilla
  dungeon bosses are rank 1) 4,
  elite (rank 1-2) 3, rare (rank 4) 3, npc (quest giver, vendor, trainer,
  flight master, innkeeper, banker, ...; never a critter) 2 when it starts a
  kept quest or is a flight master or innkeeper, else 1, creature 1. Quests 2
  (3 for group, dungeon or raid quests). Items: quality 2/3/4 -> rarity
  2/3/4. Never 5 (each zone has one hand-written Legendary). A frozen zone
  only counts the frozen zones' dungeons as group quest sorts.
  Card count: TARGET_TOTAL cards per zone with the hand-written ones; the
  generated part follows RARITY_SHARE (60/25/10/5 %), a short rarity passing
  its gap down to the next lower one. Inside a rarity, kinds are taken in
  turn (ROUND_ROBIN), each sorted by value: spawn count; for NPCs quests
  started, auctioneers and bankers last; quests sorted to the zone first;
  items from quests and bosses first, then item level. Critters only fill
  Commons once no other Common is left. The lowest-value cards are left out.
  level: rounded mean of min/max level (quest cards: quest level).
  icon: picked from icon names already used in Data/ by name keyword,
  beast family, creature type, trainer/vendor subname, item class, kind.

Re-run (from the repo root; Python 3.8+, standard library only):
  git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/azerothcore/azerothcore-wotlk.git /tmp/acore
  git -C /tmp/acore sparse-checkout set data/sql/base/db_world
  python3 -I scripts/generate-cards.py /tmp/acore/data/sql/base/db_world
Options: --repo <repo root> (default: this script's parent folder),
  --report (print per-zone counts to stderr). Output is deterministic.
  Every new generated file needs its Data/load_data.xml line and its
  "<zoneMapID>:generated" entry in Data/Loaded.lua.
"""

import argparse
import math
import os
import re
import sys
from collections import Counter, defaultdict

# --- Zones -----------------------------------------------------------------

# uiMapID -> (file name, Data folder, display name). The file name is shared
# by the hand-written Data/<folder>/<file>.lua and Data/Generated/<file>.lua.
ZONES = {
    1429: ("ElwynnForest", "EasternKingdoms", "Elwynn Forest"),
    1436: ("Westfall", "EasternKingdoms", "Westfall"),
    1426: ("DunMorogh", "EasternKingdoms", "Dun Morogh"),
    1420: ("TirisfalGlades", "EasternKingdoms", "Tirisfal Glades"),
    1438: ("Teldrassil", "Kalimdor", "Teldrassil"),
    1411: ("Durotar", "Kalimdor", "Durotar"),
    1412: ("Mulgore", "Kalimdor", "Mulgore"),
    # Eastern Kingdoms
    1433: ("RedridgeMountains", "EasternKingdoms", "Redridge Mountains"),
    1431: ("Duskwood", "EasternKingdoms", "Duskwood"),
    1434: ("StranglethornVale", "EasternKingdoms", "Stranglethorn Vale"),
    1432: ("LochModan", "EasternKingdoms", "Loch Modan"),
    1437: ("Wetlands", "EasternKingdoms", "Wetlands"),
    1418: ("Badlands", "EasternKingdoms", "Badlands"),
    1427: ("SearingGorge", "EasternKingdoms", "Searing Gorge"),
    1428: ("BurningSteppes", "EasternKingdoms", "Burning Steppes"),
    1421: ("SilverpineForest", "EasternKingdoms", "Silverpine Forest"),
    1424: ("HillsbradFoothills", "EasternKingdoms", "Hillsbrad Foothills"),
    1416: ("AlteracMountains", "EasternKingdoms", "Alterac Mountains"),
    1417: ("ArathiHighlands", "EasternKingdoms", "Arathi Highlands"),
    1425: ("TheHinterlands", "EasternKingdoms", "The Hinterlands"),
    1422: ("WesternPlaguelands", "EasternKingdoms", "Western Plaguelands"),
    1423: ("EasternPlaguelands", "EasternKingdoms", "Eastern Plaguelands"),
    1435: ("SwampOfSorrows", "EasternKingdoms", "Swamp of Sorrows"),
    1419: ("BlastedLands", "EasternKingdoms", "Blasted Lands"),
    1430: ("DeadwindPass", "EasternKingdoms", "Deadwind Pass"),
    # Kalimdor
    1439: ("Darkshore", "Kalimdor", "Darkshore"),
    1440: ("Ashenvale", "Kalimdor", "Ashenvale"),
    1442: ("StonetalonMountains", "Kalimdor", "Stonetalon Mountains"),
    1447: ("Azshara", "Kalimdor", "Azshara"),
    1448: ("Felwood", "Kalimdor", "Felwood"),
    1452: ("Winterspring", "Kalimdor", "Winterspring"),
    1450: ("Moonglade", "Kalimdor", "Moonglade"),
    1413: ("TheBarrens", "Kalimdor", "The Barrens"),
    1441: ("ThousandNeedles", "Kalimdor", "Thousand Needles"),
    1443: ("Desolace", "Kalimdor", "Desolace"),
    1445: ("DustwallowMarsh", "Kalimdor", "Dustwallow Marsh"),
    1444: ("Feralas", "Kalimdor", "Feralas"),
    1446: ("Tanaris", "Kalimdor", "Tanaris"),
    1449: ("UngoroCrater", "Kalimdor", "Un'Goro Crater"),
    1451: ("Silithus", "Kalimdor", "Silithus"),
}
ZONE_ORDER = [1429, 1436, 1426, 1420, 1438, 1411, 1412,
              1433, 1431, 1434, 1432, 1437, 1418, 1427, 1428, 1421, 1424, 1416, 1417,
              1425, 1422, 1423, 1435, 1419, 1430,
              1439, 1440, 1442, 1447, 1448, 1452, 1450, 1413, 1441, 1443, 1445, 1444,
              1446, 1449, 1451]
# Zones whose generated files predate the 33 others and stay as they were:
# their creatures are homed as if only these zones existed, so a template with
# more spawns in a newer neighbour (Lord Malathrom, a Duskwood rare inside the
# Westfall rectangle) keeps its card here, and that card (npc, quest or item
# ID) is not generated again for the newer zone. Empty the set to rehome
# them: their card IDs then change.
FROZEN_ZONES = frozenset({1429, 1436, 1426, 1420, 1438, 1411, 1412})
# Data folder -> continent uiMapID (report only: addCards takes no continent).
CONTINENTS = {"EasternKingdoms": 1415, "Kalimdor": 1414}

# Cities fold into the outdoor zone around them (Data/ZoneGroups.lua).
CITY_PARENT = {1453: 1429, 1455: 1426, 1457: 1438, 1454: 1411, 1458: 1420, 1456: 1412}

# Dungeon map ID -> zone holding its entrance. Raids (Molten Core, Onyxia's
# Lair, Blackwing Lair, Zul'Gurub, Ahn'Qiraj, Naxxramas) are left out: their
# map IDs are not listed, so their spawns count for no zone.
DUNGEON_MAPS = {
    34: 1429,   # The Stockade
    36: 1436,   # The Deadmines
    90: 1426,   # Gnomeregan
    189: 1420,  # Scarlet Monastery
    389: 1411,  # Ragefire Chasm
    43: 1413,   # Wailing Caverns
    47: 1413,   # Razorfen Kraul
    129: 1413,  # Razorfen Downs
    33: 1421,   # Shadowfang Keep
    48: 1440,   # Blackfathom Deeps
    70: 1418,   # Uldaman
    209: 1446,  # Zul'Farrak
    349: 1443,  # Maraudon
    109: 1435,  # Sunken Temple (Temple of Atal'Hakkar)
    230: 1428,  # Blackrock Depths
    229: 1428,  # Blackrock Spire
    429: 1444,  # Dire Maul
    289: 1422,  # Scholomance
    329: 1423,  # Stratholme
}

# Quest sort (AreaTable) IDs of each zone, its cities, its dungeons and its
# quest hubs sorted apart (Booty Bay, Feathermoon Stronghold, Alcaz Island,
# Timbermaw Hold, Blackrock Mountain): quests sorted there rank first among a
# zone's quests. Dungeon area IDs checked against quest titles in the dump.
ZONE_AREAS = {
    1429: {12, 1519, 717},
    1436: {40, 1581},
    1426: {1, 1537, 721},
    1420: {85, 1497, 796},
    1438: {141, 1657},
    1411: {14, 1637, 2437},
    1412: {215, 1638},
    1433: {44},
    1431: {10},
    1434: {33, 35},
    1432: {38},
    1437: {11},
    1418: {3, 1517},
    1427: {51},
    1428: {46, 25, 1583, 1584},
    1421: {130, 209},
    1424: {267},
    1416: {36},
    1417: {45},
    1425: {47},
    1422: {28, 2057},
    1423: {139, 2017},
    1435: {8, 1417},
    1419: {4},
    1430: {41},
    1439: {148},
    1440: {331, 719},
    1442: {406},
    1447: {16},
    1448: {361, 1769},
    1452: {618},
    1450: {493},
    1413: {17, 718, 1717, 722},
    1441: {400},
    1443: {405, 2100},
    1445: {15, 2079},
    1444: {357, 1116, 2557},
    1446: {440, 978},
    1449: {490},
    1451: {1377},
}
DUNGEON_AREAS = {717, 1581, 721, 796, 2437,
                 718, 1717, 722, 209, 719, 1517, 978, 2100, 1417, 1584, 1583, 2557, 2057, 2017}
# Quests sorted to a raid or a battleground are skipped (Zul'Gurub 19/1977,
# Molten Core 2717, Blackwing Lair 2677, Onyxia's Lair 2159, Ahn'Qiraj
# 3428/3429, Naxxramas 3456; Alterac Valley 2597/2839, Arathi Basin 3358,
# Warsong Gulch 3277), even when an outdoor NPC starts them.
SKIPPED_QUEST_AREAS = {19, 1977, 2717, 2677, 2159, 3428, 3429, 3456, 2597, 2839, 3358, 3277}

# Highest level a hostile creature outside cities and dungeons may have to
# count for the zone (neighbour-zone mobs near a border are higher): the
# zone's top level plus 2 for the new zones.
LEVEL_CAP = {1429: 12, 1436: 20, 1426: 13, 1420: 13, 1438: 12, 1411: 12, 1412: 12,
             1433: 27, 1431: 32, 1434: 47, 1432: 22, 1437: 32, 1418: 47, 1427: 52,
             1428: 60, 1421: 22, 1424: 32, 1416: 42, 1417: 42, 1425: 52, 1422: 60,
             1423: 62, 1435: 47, 1419: 57, 1430: 62,
             1439: 22, 1440: 32, 1442: 29, 1447: 57, 1448: 57, 1452: 62, 1450: 62,
             1413: 27, 1441: 37, 1443: 42, 1445: 47, 1444: 52, 1446: 52, 1449: 57, 1451: 62}

# Lowest level a hostile non-critter creature outside cities and dungeons
# may have to count for a newer zone: its bottom level minus 3. Rectangles of
# the newer zones overlap a lot (the Un'Goro rectangle reaches into Tanaris,
# Thousand Needles' into Un'Goro), so a spawn inside several rectangles goes to
# the best one whose window (floor to LEVEL_CAP) holds the creature's level
# (zones_of_spawn, place_spawn). Frozen zones have no floor and keep the old
# placement.
LEVEL_FLOOR = {1433: 12, 1431: 15, 1434: 27, 1432: 7, 1437: 17, 1418: 32, 1427: 40,
               1428: 47, 1421: 7, 1424: 17, 1416: 27, 1417: 27, 1425: 37, 1422: 48,
               1423: 50, 1435: 32, 1419: 42, 1430: 52,
               1439: 7, 1440: 15, 1442: 12, 1447: 42, 1448: 45, 1452: 50, 1450: 50,
               1413: 7, 1441: 22, 1443: 27, 1445: 32, 1444: 37, 1446: 37, 1449: 45, 1451: 52}

# World bosses (and Azuregos' ghost) are left out: Azuregos, Lord Kazzak and
# the four Dragons of Nightmare. Any other outdoor rank 3 creature that is not
# a quest giver or service NPC is treated the same way.
WORLD_BOSSES = {6109, 15481, 12397, 14887, 14888, 14889, 14890, 15302}

# Spawn areas left out: (map, minX, maxX, minY, maxY). Stormwind Harbor was
# added in WotLK; vanilla-era entries placed there (Auberdine Sentinel) are not
# vanilla content.
EXCLUDED_BOXES = [
    (0, -8650.0, -8250.0, 1150.0, 1400.0),  # Stormwind Harbor
    (0, -8480.0, -8250.0, 1000.0, 1150.0),  # Stormwind Harbor, east docks
]

# UiMapAssignment rectangles: (uiMapID, map, areaID, minX, maxX, minY, maxY).
ZONE_RECTS = [
    (1411, 1, 14, -1716.7, 1808.3, -7250.0, -1962.5),
    (1412, 1, 215, -3697.9, -272.9, -3089.6, 2047.9),
    (1413, 1, 17, -5143.8, 1612.5, -7510.4, 2622.9),
    (1416, 0, 36, -366.7, 1500.0, -2016.7, 783.3),
    (1417, 0, 45, -2533.3, -133.3, -4466.7, -866.7),
    (1418, 0, 3, -7547.9, -5889.6, -4566.7, -2079.2),
    (1419, 0, 4, -12800.0, -10566.7, -4591.7, -1241.7),
    (1420, 0, 85, 825.0, 3837.5, -1485.4, 3033.3),
    (1421, 0, 130, -1133.3, 1666.7, -750.0, 3450.0),
    (1422, 0, 28, 500.0, 3366.7, -3883.3, 416.7),
    (1423, 0, 139, 1218.8, 3800.0, -6056.2, -2185.4),
    (1424, 0, 267, -1733.3, 400.0, -2133.3, 1066.7),
    (1425, 0, 47, -1100.0, 1466.7, -5425.0, -1575.0),
    (1426, 0, 1, -7160.4, -3877.1, -3122.9, 1802.1),
    (1427, 0, 51, -7587.5, -6100.0, -2554.2, -322.9),
    (1428, 0, 46, -8983.3, -7031.2, -3195.8, -266.7),
    (1429, 0, 12, -10254.2, -7939.6, -1935.4, 1535.4),
    (1430, 0, 41, -11533.3, -9866.7, -3333.3, -833.3),
    (1431, 0, 10, -11516.7, -9716.7, -1866.7, 833.3),
    (1432, 0, 38, -6327.1, -4487.5, -4752.1, -1993.7),
    (1433, 0, 44, -10022.9, -8575.0, -3741.7, -1570.8),
    (1434, 0, 33, -15422.9, -11168.8, -4160.4, 2220.8),
    (1435, 0, 8, -11150.0, -9620.8, -4516.7, -2222.9),
    (1436, 0, 40, -11733.3, -9400.0, -483.3, 3016.7),
    (1437, 0, 11, -4904.2, -2147.9, -4525.0, -389.6),
    (1438, 1, 141, 8437.5, 11831.2, -1277.1, 3814.6),
    (1439, 1, 148, 3966.7, 8333.3, -3608.3, 2941.7),
    (1440, 1, 331, 829.2, 4672.9, -4066.7, 1700.0),
    (1441, 1, 400, -6900.0, -3966.7, -4833.3, -433.3),
    (1442, 1, 406, -339.6, 2916.7, -1637.5, 3245.8),
    (1443, 1, 405, -2545.8, 452.1, -262.5, 4233.3),
    (1444, 1, 357, -7000.0, -2366.7, -1508.3, 5441.7),
    (1445, 1, 15, -5533.3, -2033.3, -6225.0, -975.0),
    (1446, 1, 440, -10475.0, -5875.0, -7118.7, -218.7),
    (1447, 1, 16, 1960.4, 5341.7, -8347.9, -3277.1),
    (1448, 1, 361, 3300.0, 7133.3, -4108.3, 1641.7),
    (1449, 1, 490, -8433.3, -5966.7, -3166.7, 533.3),
    (1450, 1, 493, 6952.1, 8491.7, -3689.6, -1381.2),
    (1451, 1, 1377, -8281.2, -5958.3, -945.8, 2537.5),
    (1452, 1, 618, 3800.0, 8533.3, -7416.7, -316.7),
    (1453, 0, 1519, -9175.2, -8278.9, 36.7, 1381.0),
    (1454, 1, 1637, 1338.5, 2273.9, -5083.2, -3680.6),
    (1455, 0, 1537, -5096.8, -4569.2, -1504.2, -713.6),
    (1456, 1, 1638, -1545.8, -850.0, -527.1, 516.7),
    (1457, 1, 1657, 9532.6, 10238.3, 1880.0, 2938.4),
    (1458, 0, 1497, 1237.8, 1877.9, -86.2, 873.2),
]

# --- Card budget -----------------------------------------------------------

TARGET_TOTAL = 120
RARITY_SHARE = {4: 0.05, 3: 0.10, 2: 0.25}  # common takes the rest
# Kinds taken in turn inside each rarity (weight = cards per turn).
ROUND_ROBIN = {
    1: [("creature", 3), ("npc", 1), ("critter", 0)],
    2: [("npc", 1), ("quest", 1), ("item", 1)],
    3: [("rare", 1), ("elite", 1), ("quest", 1), ("item", 1)],
    4: [("boss", 2), ("item", 1)],
}

# --- Filters ---------------------------------------------------------------

CREATURE_TYPES = {1: "Beast", 2: "Dragonkin", 3: "Demon", 4: "Elemental", 5: "Giant",
                  6: "Undead", 7: "Humanoid", 8: "Critter", 9: "Mechanical"}
MAX_CREATURE_ENTRY = 16000
MAX_QUEST_ID = 9300
MAX_ITEM_ENTRY = 24000
ITEM_CLASSES = {2, 4}  # weapons and armor: no recipes, gems, trade goods, quest items
FLAG_EXTRA_TRIGGER = 0x80
FLAG_EXTRA_GHOST_VISIBILITY = 0x400
FLAG_EXTRA_WORLDEVENT = 0x4000
FLAG_EXTRA_DUNGEON_BOSS = 0x10000000
UNIT_FLAG_NOT_SELECTABLE = 0x02000000
NPC_FLAG_QUESTGIVER = 0x2
NPC_FLAG_SERVICES = (0x10 | 0x20 | 0x40 | 0x80 | 0x100 | 0x200 | 0x400 | 0x800 | 0x1000
                     | 0x2000 | 0x10000 | 0x20000 | 0x40000 | 0x80000 | 0x100000
                     | 0x200000 | 0x400000)
NPC_FLAG_NOTABLE = 0x2000 | 0x10000  # flight master, innkeeper
QUEST_FLAG_DAILY = 0x1000
QUEST_FLAG_WEEKLY = 0x8000
QUEST_INFO_GROUP = {1, 62, 81, 88, 89}
QUEST_INFO_SKIP = {41, 82}  # PvP, world event
# Class (-61..-263) and profession sorts are kept; other negative sorts are
# holidays and specials.
QUEST_SORTS_KEPT = {-61, -81, -82, -141, -161, -162, -261, -262, -263, -372,
                    -181, -182, -24, -101, -121, -264, -304, -201, -324, -182}
BAD_NAME = re.compile(
    r"trigger|bunny|\[dnd\]|\bdnd\b|invisible|dummy|totem|\bvisual\b|waypoint|\[ph\]|"
    r"\bplaceholder\b|\btest\b|\bunused\b|deprecated|\bdep\b|\(old\)|\[old\]|controller|"
    r"kill credit|\bcredit\b|\bqa\b|spirit healer|^monster - |\bnyi\b|\bzz|"
    r"\briding\b|^great \w+ kodo$",  # mount vendor display models
    re.I)
GENERIC_NPC = re.compile(r"^(auctioneer|banker)\b", re.I)
# Used with fullmatch: Python's "$" also matches before a final "\n".
NAME_OK = re.compile(r"[\x20-\x7e]{1,64}")
INT32_MAX = 2147483647

# --- Icons (all already used in Data/ or a kind default) -------------------

FAMILY_ICONS = {1: "Ability_Hunter_Pet_Wolf", 2: "Ability_Hunter_Pet_Cat",
                3: "Ability_Hunter_Pet_Spider", 4: "Ability_Hunter_Pet_Bear",
                5: "Ability_Hunter_Pet_Boar", 7: "Ability_Hunter_Pet_Vulture",
                12: "Ability_Hunter_Pet_TallStrider", 20: "Ability_Hunter_Pet_Scorpid",
                25: "Ability_Hunter_Pet_Wolf", 26: "Ability_Hunter_Pet_Owl"}
# First match wins; checked against "name subname", lower case.
KEYWORD_ICONS = [
    (r"murloc|\bmurk|\bfin\b|-fin|tidehunter|oracle", "INV_Misc_Head_Murloc_01"),
    (r"kobold|tunnel rat|candle", "INV_Misc_Head_Kobold_01"),
    (r"gnoll|riverpaw|mosshide|hogger", "INV_Misc_Head_Gnoll_01"),
    (r"quilboar|razormane|bristleback|thornguard", "INV_Misc_Head_Quillboar_01"),
    (r"troll|frostmane|darkspear|voodoo|witch doctor|sen'jin|bloodscalp|skullsplitter",
     "INV_Misc_Head_Troll_01"),
    (r"tauren|bloodhoof|thunderhorn|runetotem|plainsrunner|brave\b|kodo", "INV_Misc_Head_Tauren_01"),
    (r"leper gnome|gnome|gnomeregan|tinker|mechano|cogspin", "INV_Misc_Head_Gnome_01"),
    (r"dwarf|ironforge|mountaineer|bronzebeard|thane|dark iron", "INV_Misc_Head_Dwarf_01"),
    (r"defias|bandit|thief|thug|rogue|pillager|smuggler|footpad", "INV_Misc_Bandana_03"),
    (r"scarlet|crusade", "Spell_Holy_SealOfMight"),
    (r"skeleton|skull|bone", "INV_Misc_Bone_HumanSkull_01"),
    (r"wolf|worg|hound|\bdog\b|coyote|jackal|mongrel", "Ability_Hunter_Pet_Wolf"),
    (r"boar|\bpig\b|swine", "Ability_Hunter_Pet_Boar"),
    (r"spider|webwood|tarantula|widow|creeper", "Ability_Hunter_Pet_Spider"),
    (r"\bbear\b|\bbears\b|grizzly|ursa", "Ability_Hunter_Pet_Bear"),
    (r"\bcat\b|lynx|tiger|panther|saber|cougar|lion|prowler|stalker|kitten", "Ability_Hunter_Pet_Cat"),
    (r"owl|\bhawk|eagle|raven|\bcrow|buzzard|vulture|fleshripper|condor|flight master|gryphon|wind rider|hippogryph",
     "Ability_Hunter_Pet_Vulture"),
    (r"strider", "Ability_Hunter_Pet_TallStrider"),
    (r"scorpid|scorpion", "Ability_Hunter_Pet_Scorpid"),
    (r"stag\b|deer|doe\b|fawn|gazelle|elk\b|antelope|horse|mare\b|stallion|pony|ram\b|goat", "Ability_Druid_TravelForm"),
    (r"timberling|treant|ancient|dryad|grell|sprite|nymph", "Spell_Nature_ProtectionformNature"),
    (r"fire|flame|ember|blaze|burning|magma|lava", "Spell_Fire_Incinerate"),
    (r"frost|\bice\b|snow|water|tide|wave", "Spell_Frost_FrostArmor02"),
    (r"dust\b|wind\b|air\b|cyclone|storm\b|breeze", "Spell_Nature_Cyclone"),
    (r"trogg|rock|stone|earth|golem|elemental", "Spell_Nature_Earthquake"),
    (r"mine|miner|mining|digger|excavat|prospector|geologist", "Trade_Mining"),
    (r"blacksmith|smith\b|weaponsmith|armorsmith", "Trade_BlackSmithing"),
    (r"engineer|gizmo|mechanic", "INV_Gizmo_02"),
    (r"innkeeper|cook|bartender|brew|food|drink|wine|tavern|baker|ale\b", "INV_Drink_05"),
    (r"banker|bank|auctioneer|treasur|merchant|trade supplies|general goods|coin|guild master|tabard",
     "INV_Misc_Coin_01"),
    (r"bow|gun|marksman|hunter|ranger|huntsman|sentinel|archer|rifle|ammunition", "INV_Weapon_Bow_02"),
    (r"armor|shield|plate|mail\b|guard|protector|defender|warden|watch", "INV_Shield_06"),
    (r"sword|blade|axe|mace|weapon|warrior|soldier|marine|grunt|footman|militia|knight", "INV_Sword_04"),
    (r"herbal|alchem|druid|nature|botan|farmer|harvest|peasant|wheat", "Spell_Nature_Rejuvenation"),
    (r"priest|cleric|light\b|monk|abbot|brother|sister|acolyte|paladin|healer|first aid|bandage",
     "Spell_Holy_HolySmite"),
    (r"mage|magus|arcan|wizard|sorcer|conjur|portal", "Spell_Frost_Frostbolt02"),
    (r"warlock|demon|imp\b|felhound|shadow|necro|cult|summoner|dark\b", "Spell_Shadow_SummonImp"),
    (r"shaman|spirit|earthmother|totemic", "Spell_Nature_LightningShield"),
    (r"skinn|leather|tann|pelt|fur\b|trapper", "INV_Misc_Pelt_Wolf_01"),
    (r"stable|kennel", "INV_Misc_Horn_01"),
    (r"night elf|darnassus|moon|elune|priestess", "Spell_Nature_MoonGlow"),
    (r"undead|forsaken|deathguard|zombie|ghoul|ghost|wraith|lich\b|plague|rotting|rot\b|corpse|dead\b",
     "Spell_Shadow_RaiseDead"),
]
# Each keyword must start a word ("ale" never matches "Eastvale").
KEYWORD_ICONS = [(re.compile(r"\b(?:%s)" % p), icon) for p, icon in KEYWORD_ICONS]
TYPE_ICONS = {"Beast": "INV_Misc_Pelt_Wolf_01", "Dragonkin": "Spell_Fire_Volcano",
              "Demon": "Spell_Shadow_SummonImp", "Elemental": "Spell_Nature_Earthquake",
              "Giant": "Ability_ThunderClap", "Undead": "Spell_Shadow_RaiseDead",
              "Humanoid": "Ability_Warrior_BattleShout", "Critter": "Spell_Nature_ProtectionformNature",
              "Mechanical": "INV_Misc_Gear_01"}
BOSS_HUMANOID_ICON = "Ability_Warrior_WarCry"
ITEM_ICON_QUEST = "INV_Misc_Note_01"
ITEM_ICON_DEFAULT = "INV_Misc_Bag_08"
# item_template class 2 (weapon) subclasses
WEAPON_RANGED = {2, 3, 18, 19, 16}  # bow, gun, crossbow, wand, thrown
ARMOR_SHIELD = 6

# --- SQL dump reader -------------------------------------------------------

TOKEN = re.compile(r"\s*(?:'((?:[^'\\]|\\.)*)'|(NULL)|([-+0-9.eE]+)|([(),;]))", re.S)
ESCAPES = {"0": "\0", "n": "\n", "r": "\r", "t": "\t", "Z": "\x1a"}


def unescape(text):
    return re.sub(r"\\(.)", lambda m: ESCAPES.get(m.group(1), m.group(1)), text, flags=re.S)


def read_table(folder, table, wanted):
    """Rows of one dump as dicts holding only the `wanted` columns.

    The file is parsed as data: CREATE TABLE gives the column order, each
    INSERT ... VALUES tuple gives a row. Nothing in it is executed."""
    path = os.path.join(folder, table + ".sql")
    with open(path, encoding="utf-8", errors="replace") as handle:
        text = handle.read()
    create = re.search(r"CREATE TABLE `%s` \((.*?)\n\)" % re.escape(table), text, re.S)
    if not create:
        sys.exit("no CREATE TABLE for %s in %s" % (table, path))
    columns = re.findall(r"^\s*`([^`]+)`\s+\w", create.group(1), re.M)
    index = {name: i for i, name in enumerate(columns)}
    missing = [w for w in wanted if w not in index]
    if missing:
        sys.exit("%s lacks columns %s" % (table, missing))
    keep = [(w, index[w]) for w in wanted]
    rows = []
    head = "INSERT INTO `%s` VALUES" % table
    pos = text.find(head)
    while pos != -1:
        pos += len(head)
        row, depth = [], 0
        while True:
            m = TOKEN.match(text, pos)
            if not m:
                sys.exit("cannot parse %s near byte %d" % (table, pos))
            pos = m.end()
            string, null, number, punct = m.groups()
            if punct == "(":
                depth, row = 1, []
            elif punct == ")":
                depth = 0
                if len(row) != len(columns):
                    sys.exit("%s: row with %d values, %d columns" % (table, len(row), len(columns)))
                rows.append({w: row[i] for w, i in keep})
            elif punct == ";":
                break
            elif punct == ",":
                continue
            elif depth:
                if string is not None:
                    row.append(unescape(string))
                elif null:
                    row.append(None)
                else:
                    row.append(float(number) if any(c in number for c in ".eE") else int(number))
        pos = text.find(head, pos)
    return rows


# --- Helpers ---------------------------------------------------------------

def zone_of_spawn(map_id, x, y):
    """Shipped zone uiMapID of a spawn, or None."""
    if map_id in DUNGEON_MAPS:
        return DUNGEON_MAPS[map_id]
    if map_id not in (0, 1):
        return None
    for ui_map, rect_map, _, x0, x1, y0, y1 in ZONE_RECTS:
        if ui_map in CITY_PARENT and rect_map == map_id and x0 <= x <= x1 and y0 <= y <= y1:
            return CITY_PARENT[ui_map]
    best, best_score = None, None
    for ui_map, rect_map, _, x0, x1, y0, y1 in ZONE_RECTS:
        if ui_map in CITY_PARENT or rect_map != map_id or not (x0 <= x <= x1 and y0 <= y <= y1):
            continue
        score = math.hypot((x - (x0 + x1) / 2) / ((x1 - x0) / 2), (y - (y0 + y1) / 2) / ((y1 - y0) / 2))
        if best_score is None or score < best_score:
            best, best_score = ui_map, score
    return best if best in ZONES else None


def zones_of_spawn(map_id, x, y):
    """Shipped zones whose rectangle holds a spawn, best first: a dungeon's or
    a city's zone alone, else the outdoor rectangles by normalized distance
    to their centre (the first one is zone_of_spawn's answer)."""
    if map_id in DUNGEON_MAPS:
        return [DUNGEON_MAPS[map_id]]
    if map_id not in (0, 1):
        return []
    for ui_map, rect_map, _, x0, x1, y0, y1 in ZONE_RECTS:
        if ui_map in CITY_PARENT and rect_map == map_id and x0 <= x <= x1 and y0 <= y <= y1:
            return [CITY_PARENT[ui_map]]
    scored = []
    for i, (ui_map, rect_map, _, x0, x1, y0, y1) in enumerate(ZONE_RECTS):
        if ui_map in CITY_PARENT or rect_map != map_id or not (x0 <= x <= x1 and y0 <= y <= y1):
            continue
        score = math.hypot((x - (x0 + x1) / 2) / ((x1 - x0) / 2), (y - (y0 + y1) / 2) / ((y1 - y0) / 2))
        scored.append((score, i, ui_map))
    return [ui_map for _, _, ui_map in sorted(scored) if ui_map in ZONES]


def place_spawn(candidates, level):
    """Zone of a spawn among `candidates` (best first) for a creature of
    `level` (None: no level rule): the first whose level window holds it,
    else the first. None without candidates."""
    if not candidates:
        return None
    if level is not None:
        for zone in candidates:
            if LEVEL_FLOOR.get(zone, 1) <= level <= LEVEL_CAP[zone]:
                return zone
    return candidates[0]


def creature_kind(t, is_npc, is_encounter_boss):
    """(kind, rarity) of a creature template row."""
    rank = t["rank"]
    if rank == 3 or t["flags_extra"] & FLAG_EXTRA_DUNGEON_BOSS or is_encounter_boss:
        return "boss", 4
    if rank in (1, 2):
        return "elite", 3
    if rank == 4:
        return "rare", 3
    if is_npc and CREATURE_TYPES.get(t["type"]) != "Critter":  # a quest-giving chicken stays a critter
        return "npc", 1
    return "creature", 1


def creature_level(t):
    """Rounded mean of a template's min and max level."""
    return int((t["minlevel"] + t["maxlevel"]) / 2 + 0.5)


def group_dungeon_areas(zone):
    """Dungeon quest sorts that make a quest of `zone` a group quest (rarity
    3). A frozen zone only knows the dungeons of frozen zones (a Thunder Bluff
    quest sorted to Wailing Caverns stays rarity 2 in Mulgore)."""
    if zone not in FROZEN_ZONES:
        return DUNGEON_AREAS
    frozen_areas = set().union(*(ZONE_AREAS[z] for z in FROZEN_ZONES))
    return DUNGEON_AREAS & frozen_areas


def best_zone(counts):
    """(zone, count) with most spawns; ties go to the lowest uiMapID."""
    return sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[0]


def assign_homes(legacy, current, frozen):
    """Sorted (entry, zone, count) homes of each template. `legacy` and
    `current` are {entry: Counter(zone)} from the old placement (zone_of_spawn)
    and the level-aware one (place_spawn). A frozen zone keeps the templates
    whose best frozen zone it is under the old placement (as if the other zones
    did not exist); another zone gets the templates whose best zone it is
    under the new placement. One template can have two homes."""
    homes = []
    for entry, counts in legacy.items():
        frozen_counts = {z: n for z, n in counts.items() if z in frozen and n > 0}
        if frozen_counts:
            homes.append((entry,) + best_zone(frozen_counts))
    for entry, counts in current.items():
        overall = {z: n for z, n in counts.items() if n > 0}
        if overall:
            zone, count = best_zone(overall)
            if zone not in frozen:
                homes.append((entry, zone, count))
    return sorted(homes)


def card_ref(c):
    """What a card shows ("npc", entry), ("quest", ID) or ("item", ID)."""
    for field, kind in (("entry", "npc"), ("questID", "quest"), ("itemID", "item")):
        if field in c:
            return (kind, c[field])
    raise ValueError("card %r has no npc, quest or item ID" % (c.get("id"),))


def taken_by_other_zone(c, taken_refs, taken_names):
    """True when a card's npc/quest/item ID or name (case-insensitive) is
    already a generated card of another zone."""
    return card_ref(c) in taken_refs or c["name"].lower() in taken_names


def in_city_or_dungeon(map_id, x, y):
    if map_id in DUNGEON_MAPS:
        return True
    for ui_map, rect_map, _, x0, x1, y0, y1 in ZONE_RECTS:
        if ui_map in CITY_PARENT and rect_map == map_id and x0 <= x <= x1 and y0 <= y <= y1:
            return True
    return False


def clean_name(name):
    return (isinstance(name, str) and NAME_OK.fullmatch(name) is not None
            and "|" not in name and name.strip() == name)


def is_id(value):
    """A positive int32 integer (the addon's isMapID rule); bools excluded."""
    return isinstance(value, int) and not isinstance(value, bool) and 0 < value <= INT32_MAX


def check_card(c):
    """Last guard before writing Lua: aborts the run on any value the addon
    would refuse, so a bad dump row can never ship a half-valid batch."""
    problems = []
    if not clean_name(c.get("name")):
        problems.append("name")
    for field in ("entry", "questID", "itemID"):
        if field in c and not is_id(c[field]):
            problems.append(field)
    if "entry" in c and not (is_id(c.get("level")) and c["level"] <= 63):
        problems.append("level")
    if not (isinstance(c.get("rarity"), int) and 1 <= c["rarity"] <= 4):
        problems.append("rarity")
    if problems:
        sys.exit("refusing card %r: bad %s" % (c.get("id"), ", ".join(problems)))


def creature_icon(name, subname, ctype, family, kind):
    if ctype == "Beast" and family in FAMILY_ICONS:
        return FAMILY_ICONS[family]
    if ctype == "Mechanical":
        return "INV_Misc_Gear_01"
    # The subname ("Weapon Merchant", "Mage Trainer") says more than a name.
    for text in ((subname or "").lower(), name.lower()):
        for pattern, icon in KEYWORD_ICONS:
            if pattern.search(text):
                return icon
    if kind == "boss" and ctype == "Humanoid":
        return BOSS_HUMANOID_ICON
    return TYPE_ICONS[ctype]


def item_icon(item):
    if item["class"] == 2:
        return "INV_Weapon_Bow_02" if item["subclass"] in WEAPON_RANGED else "INV_Sword_04"
    if item["class"] == 4 and item["subclass"] == ARMOR_SHIELD:
        return "INV_Shield_06"
    if item["class"] == 4:
        return "INV_Shield_06" if item["subclass"] in (3, 4) else ITEM_ICON_DEFAULT
    return ITEM_ICON_DEFAULT


def lua_string(text):
    # Only ever called on clean_name() text (printable ASCII, no newline); the
    # assert keeps a future caller from emitting an unterminated Lua string.
    # (A real exception, not assert, so it also holds under python -O.)
    if not (clean_name(text) or re.fullmatch(r"[0-9]+:[a-z]+_[0-9]+", text)):
        raise ValueError("refusing to emit %r as a Lua string" % (text,))
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def hand_written_path(repo, zone_map_id):
    """Path of the zone's hand-written Data file, or None when it is missing.
    The file name is matched without case (UngoroCrater.lua, UnGoroCrater.lua)."""
    file_name, folder, _ = ZONES[zone_map_id]
    directory = os.path.join(repo, "Data", folder)
    wanted = (file_name + ".lua").lower()
    try:
        entries = sorted(os.listdir(directory))
    except OSError:
        return None
    for entry in entries:
        path = os.path.join(directory, entry)
        if entry.lower() == wanted and os.path.isfile(path):
            return path
    return None


def parse_hand_written(text):
    """(lower-case card names, card IDs) of a hand-written Data file's text."""
    names = {n.lower() for n in re.findall(r'\bname = "((?:[^"\\]|\\.)*)"', text)}
    ids = re.findall(r'\bid = "((?:[^"\\]|\\.)*)"', text)
    return names, ids


def hand_written_names(repo, zone_map_id, warn=None):
    """(names, card count, card IDs) of the zone's hand-written cards. A
    missing file counts as no card (budget 120) and is reported once via
    `warn`: its zone is still being written."""
    path = hand_written_path(repo, zone_map_id)
    if path is None:
        if warn is not None:
            warn("warning: no hand-written Data/%s/%s.lua; generating the full %d cards for %s" % (
                ZONES[zone_map_id][1], ZONES[zone_map_id][0], TARGET_TOTAL, ZONES[zone_map_id][2]))
        return set(), 0, set()
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    names, ids = parse_hand_written(text)
    return names, len(ids), set(ids)


# --- Build -----------------------------------------------------------------

def build(sql, repo, report):
    event_guids = {r["guid"] for r in read_table(sql, "game_event_creature", ["eventEntry", "guid"])
                   if r["eventEntry"] > 0}
    encounter_bosses = {r["creditEntry"] for r in read_table(sql, "instance_encounters", [
        "creditType", "creditEntry"]) if r["creditType"] == 0}
    templates = {r["entry"]: r for r in read_table(sql, "creature_template", [
        "entry", "name", "subname", "minlevel", "maxlevel", "rank", "type", "family",
        "npcflag", "unit_flags", "flags_extra", "lootid"])}

    starters = defaultdict(set)  # entry -> quest IDs
    for r in read_table(sql, "creature_queststarter", ["id", "quest"]):
        starters[r["id"]].add(r["quest"])

    def is_npc_of(entry, t):
        return bool(t["npcflag"] & (NPC_FLAG_QUESTGIVER | NPC_FLAG_SERVICES)) or entry in starters

    # Level used to place a template's spawns: only plain hostile creatures
    # (the ones LEVEL_CAP applies to) follow zone level windows.
    place_level = {}
    for entry, t in templates.items():
        kind = creature_kind(t, is_npc_of(entry, t), entry in encounter_bosses)[0]
        if kind == "creature" and CREATURE_TYPES.get(t["type"]) != "Critter":
            place_level[entry] = creature_level(t)

    # Spawns per template and zone, under the old placement (legacy, for the
    # frozen zones) and the level-aware one (current).
    spawns = defaultdict(Counter)        # entry -> Counter(zone), legacy
    current = defaultdict(Counter)       # entry -> Counter(zone), level-aware
    capped = defaultdict(lambda: True)   # (entry, zone) -> every spawn outdoors
    for r in read_table(sql, "creature", ["guid", "id1", "id2", "id3", "map", "phaseMask",
                                          "position_x", "position_y", "unit_flags"]):
        if r["guid"] in event_guids or not (r["phaseMask"] & 1):
            continue
        if r["unit_flags"] & UNIT_FLAG_NOT_SELECTABLE:
            continue
        if any(r["map"] == m and x0 <= r["position_x"] <= x1 and y0 <= r["position_y"] <= y1
               for m, x0, x1, y0, y1 in EXCLUDED_BOXES):
            continue
        candidates = zones_of_spawn(r["map"], r["position_x"], r["position_y"])
        if not candidates:
            continue
        zone = zone_of_spawn(r["map"], r["position_x"], r["position_y"])
        sheltered = in_city_or_dungeon(r["map"], r["position_x"], r["position_y"])
        for entry in {r["id1"], r["id2"], r["id3"]} - {0}:
            placed = place_spawn(candidates, place_level.get(entry))
            current[entry][placed] += 1
            if zone is not None:
                spawns[entry][zone] += 1
            if sheltered:
                capped[(entry, placed)] = False
                if zone is not None:
                    capped[(entry, zone)] = False

    # Each template's home zone: the zone with most spawns (see assign_homes
    # for FROZEN_ZONES).
    homes = assign_homes(spawns, current, FROZEN_ZONES)

    skipped = Counter()
    creatures = defaultdict(list)  # zone -> candidate cards
    for entry, zone, count in homes:
        t = templates.get(entry)
        if not t:
            continue
        ctype = CREATURE_TYPES.get(t["type"])
        name, subname = t["name"], t["subname"] or ""
        if ctype is None:
            skipped["creature type"] += 1
            continue
        if BAD_NAME.search(name) or BAD_NAME.search(subname):
            skipped["creature name"] += 1
            continue
        if t["flags_extra"] & (FLAG_EXTRA_TRIGGER | FLAG_EXTRA_GHOST_VISIBILITY | FLAG_EXTRA_WORLDEVENT) \
                or t["unit_flags"] & UNIT_FLAG_NOT_SELECTABLE:
            skipped["creature flags"] += 1
            continue
        if entry >= MAX_CREATURE_ENTRY:
            skipped["creature post-vanilla entry"] += 1
            continue
        if not clean_name(name):
            skipped["creature unclean name"] += 1
            continue
        level = creature_level(t)
        if not (1 <= t["minlevel"] and 1 <= level <= 63 and t["maxlevel"] <= 63):
            skipped["creature level"] += 1
            continue
        is_npc = is_npc_of(entry, t)
        kind, rarity = creature_kind(t, is_npc, entry in encounter_bosses)
        if kind == "creature" and capped[(entry, zone)] and level > LEVEL_CAP[zone]:
            skipped["creature above zone level cap"] += 1
            continue
        if kind == "creature" and ctype != "Critter" and capped[(entry, zone)] \
                and level < LEVEL_FLOOR.get(zone, 1):
            skipped["creature below zone level floor"] += 1
            continue
        if entry in WORLD_BOSSES or (kind == "boss" and t["rank"] == 3 and not is_npc
                                     and capped[(entry, zone)]):
            skipped["world boss"] += 1
            continue
        creatures[zone].append({
            "entry": entry, "kind": kind, "rarity": rarity, "name": name, "level": level,
            "creatureType": ctype, "spawns": count, "npcflag": t["npcflag"],
            "icon": creature_icon(name, subname, ctype, t["family"], kind),
            "group": "critter" if kind == "creature" and ctype == "Critter" else kind,
            "lootid": t["lootid"], "subname": subname,
        })

    # Quests started by each zone's creatures (whether or not they are cards).
    quests_raw = {r["ID"]: r for r in read_table(sql, "quest_template", [
        "ID", "QuestLevel", "MinLevel", "QuestSortID", "QuestInfoID", "SuggestedGroupNum", "Flags",
        "LogTitle", "RequiredNpcOrGo1", "RequiredNpcOrGo2", "RequiredNpcOrGo3", "RequiredNpcOrGo4",
        "RewardItem1", "RewardItem2", "RewardItem3", "RewardItem4",
        "RewardChoiceItemID1", "RewardChoiceItemID2", "RewardChoiceItemID3",
        "RewardChoiceItemID4", "RewardChoiceItemID5", "RewardChoiceItemID6"])}
    special = {r["ID"]: r["SpecialFlags"] for r in read_table(sql, "quest_template_addon", ["ID", "SpecialFlags"])}
    items_raw = {r["entry"]: r for r in read_table(sql, "item_template", [
        "entry", "class", "subclass", "name", "Quality", "RequiredLevel", "ItemLevel",
        "RandomProperty", "RandomSuffix"])}

    def quest_ok(q):
        if q is None or q["ID"] >= MAX_QUEST_ID:
            return False
        if not (1 <= q["QuestLevel"] <= 60 and q["MinLevel"] <= 60):
            return False
        if q["Flags"] & (QUEST_FLAG_DAILY | QUEST_FLAG_WEEKLY) or special.get(q["ID"], 0) & 1:
            return False
        if q["QuestInfoID"] in QUEST_INFO_SKIP:
            return False
        if q["QuestSortID"] < 0 and q["QuestSortID"] not in QUEST_SORTS_KEPT:
            return False
        if q["QuestSortID"] in SKIPPED_QUEST_AREAS:
            return False
        title = q["LogTitle"]
        return bool(clean_name(title) and not BAD_NAME.search(title))

    def item_ok(it):
        return (it is not None and it["class"] in ITEM_CLASSES and 2 <= it["Quality"] <= 4
                and it["entry"] < MAX_ITEM_ENTRY
                and it["RequiredLevel"] <= 60 and not it["RandomProperty"] and not it["RandomSuffix"]
                and clean_name(it["name"]) and not BAD_NAME.search(it["name"]))

    loot = defaultdict(set)  # lootid -> item entries (direct, non-reference rows)
    for r in read_table(sql, "creature_loot_template", ["Entry", "Item", "Reference"]):
        if r["Reference"] == 0:
            loot[r["Entry"]].add(r["Item"])

    # Rectangles overlap at zone borders: an outdoor creature whose quests
    # (started by it, or asking to kill it) are mostly sorted to another
    # outdoor zone, and none to this one, lives in that other zone (Raven Hill
    # in Duskwood falls inside the Westfall rectangle, the northern Barrens
    # inside Durotar's).
    related = defaultdict(set)  # entry -> quest IDs
    for entry, quest_ids in starters.items():
        related[entry] |= quest_ids
    for q in quests_raw.values():
        for field in ("RequiredNpcOrGo1", "RequiredNpcOrGo2", "RequiredNpcOrGo3", "RequiredNpcOrGo4"):
            if q[field] > 0:
                related[q[field]].add(q["ID"])
    outdoor_areas = {area for ui_map, _, area, *_ in ZONE_RECTS if ui_map not in CITY_PARENT}
    strays = set()  # (entry, zone)
    for entry, zone, _ in homes:
        if not capped[(entry, zone)]:
            continue
        sorts = Counter(quests_raw[q]["QuestSortID"] for q in related.get(entry, ()) if quest_ok(quests_raw.get(q)))
        if not sorts or any(area in ZONE_AREAS[zone] for area in sorts):
            continue
        area, count = sorted(sorts.items(), key=lambda kv: (-kv[1], kv[0]))[0]
        if area in outdoor_areas and 2 * count > sum(sorts.values()):
            strays.add((entry, zone))
    skipped["border stray (quests of a neighbour zone)"] = len(strays)

    zone_quests = defaultdict(dict)  # zone -> questID -> quest
    for entry, zone, _ in homes:
        t = templates.get(entry)
        if not t or entry >= MAX_CREATURE_ENTRY or (entry, zone) in strays:
            continue
        for qid in starters.get(entry, ()):
            q = quests_raw.get(qid)
            if quest_ok(q):
                zone_quests[zone][qid] = q

    # A name hand-written in any zone is already a card: no generated twin.
    hand = {zone: hand_written_names(repo, zone, warn=lambda m: print(m, file=sys.stderr))
            for zone in ZONE_ORDER}
    all_hand = set()
    for zone in ZONE_ORDER:
        all_hand |= hand[zone][0]
    # Frozen zones only skip names hand-written in frozen zones: a newer
    # zone's hand-written card must not remove a shipped card ID (players
    # would lose it). The name may then show in two zones.
    frozen_hand = set()
    for zone in FROZEN_ZONES:
        frozen_hand |= hand[zone][0]

    # Cards of the newer zones are unique across zones: a name or an npc,
    # quest or item ID already chosen by a frozen zone, or by a newer zone
    # earlier in ZONE_ORDER, is not generated again (frozen zones run first
    # and keep their old output, duplicates between them included).
    out = {}
    taken_refs, taken_names = set(), set()
    for zone in sorted(ZONE_ORDER, key=lambda z: z not in FROZEN_ZONES):
        hand_count, hand_ids = hand[zone][1], hand[zone][2]
        used = set(frozen_hand if zone in FROZEN_ZONES else all_hand)
        cands = []

        # Creatures: one per name, best kind first.
        priority = {"boss": 0, "elite": 1, "rare": 2, "npc": 3, "creature": 4}
        for c in sorted(creatures[zone], key=lambda c: (priority[c["kind"]], -c["spawns"], c["entry"])):
            if (c["entry"], zone) in strays:
                continue
            key = c["name"].lower()
            if key in used:
                skipped["duplicate or hand-written name"] += 1
                continue
            used.add(key)
            quests_started = len(starters.get(c["entry"], set()) & set(zone_quests[zone]))
            if c["kind"] == "npc" and (quests_started or c["npcflag"] & NPC_FLAG_NOTABLE):
                c["rarity"] = 2
            if c["kind"] == "npc":
                # Auctioneers and bankers come in sets of near-identical NPCs.
                generic = 1 if GENERIC_NPC.match(c["name"]) or GENERIC_NPC.match(c["subname"]) else 0
                c["value"] = (quests_started, -generic, c["spawns"])
            else:
                c["value"] = (c["spawns"],)
            c["id"] = "%d:npc_%d" % (zone, c["entry"])
            cands.append(c)

        # Quests.
        areas = ZONE_AREAS[zone]
        dungeon_areas = group_dungeon_areas(zone)
        for qid in sorted(zone_quests[zone]):
            q = zone_quests[zone][qid]
            key = q["LogTitle"].lower()
            if key in used:
                skipped["duplicate or hand-written name"] += 1
                continue
            used.add(key)
            group = (q["QuestInfoID"] in QUEST_INFO_GROUP or q["SuggestedGroupNum"] >= 2
                     or q["QuestSortID"] in dungeon_areas)
            cands.append({
                "id": "%d:quest_%d" % (zone, qid), "kind": "quest", "rarity": 3 if group else 2,
                "name": q["LogTitle"], "icon": ITEM_ICON_QUEST, "questID": qid,
                "level": q["QuestLevel"], "group": "quest",
                "value": (1 if q["QuestSortID"] in areas else 0, -qid),
            })

        # Items: quest rewards, then direct drops of the zone's creatures.
        item_source = {}
        for qid in sorted(zone_quests[zone]):
            q = zone_quests[zone][qid]
            in_zone = 1 if q["QuestSortID"] in areas else 0
            for field in ("RewardItem1", "RewardItem2", "RewardItem3", "RewardItem4",
                          "RewardChoiceItemID1", "RewardChoiceItemID2", "RewardChoiceItemID3",
                          "RewardChoiceItemID4", "RewardChoiceItemID5", "RewardChoiceItemID6"):
                iid = q[field]
                if iid and item_ok(items_raw.get(iid)):
                    item_source[iid] = max(item_source.get(iid, (0,)), (1 + in_zone,))
        for c in creatures[zone]:
            for iid in loot.get(c["lootid"], ()) if c["lootid"] else ():
                if item_ok(items_raw.get(iid)) and iid not in item_source:
                    item_source[iid] = (3 if c["kind"] == "boss" else 0,)
        for iid in sorted(item_source):
            it = items_raw[iid]
            key = it["name"].lower()
            if key in used:
                skipped["duplicate or hand-written name"] += 1
                continue
            used.add(key)
            cands.append({
                "id": "%d:item_%d" % (zone, iid), "kind": "item", "rarity": it["Quality"],
                "name": it["name"], "icon": item_icon(it), "itemID": iid, "group": "item",
                "value": item_source[iid] + (it["ItemLevel"], -iid),
            })

        # A hand-written card using a generated-style ID ("<zone>:npc_<entry>")
        # wins: the addon refuses duplicate IDs.
        clashes = [c for c in cands if c["id"] in hand_ids]
        skipped["ID taken by a hand-written card"] += len(clashes)
        cands = [c for c in cands if c["id"] not in hand_ids]
        if zone not in FROZEN_ZONES:
            fresh = [c for c in cands if not taken_by_other_zone(c, taken_refs, taken_names)]
            skipped["already a card of another zone"] += len(cands) - len(fresh)
            cands = fresh
        chosen = select(cands, TARGET_TOTAL - hand_count)
        taken_refs |= {card_ref(c) for c in chosen}
        taken_names |= {c["name"].lower() for c in chosen}
        out[zone] = (chosen, hand_count, len(cands))
    if report:
        print("skipped:", dict(sorted(skipped.items())), file=sys.stderr)
    return out


def select(cands, budget):
    """Picks `budget` cards following RARITY_SHARE, kinds in turn by value."""
    quota = {r: int(round(share * budget)) for r, share in RARITY_SHARE.items()}
    quota[1] = budget - sum(quota.values())
    buckets = defaultdict(lambda: defaultdict(list))
    for c in cands:
        buckets[c["rarity"]][c["group"]].append(c)
    for groups in buckets.values():
        for lst in groups.values():
            lst.sort(key=lambda c: tuple(-v for v in c["value"]) + (c["id"],))
    chosen, carry = [], 0
    for rarity in (4, 3, 2, 1):
        want = quota[rarity] + carry
        picked = round_robin(buckets[rarity], ROUND_ROBIN[rarity], want)
        carry = want - len(picked)
        chosen.extend(picked)
    return chosen


def round_robin(groups, order, want):
    """Takes `weight` cards of each group in turn; weight 0 groups (critters)
    only once every other group is empty."""
    queues = {name: list(groups.get(name, [])) for name, _ in order}
    picked = []
    for active in ([n for n, w in order if w > 0], [n for n, w in order if w == 0]):
        while len(picked) < want and any(queues[n] for n in active):
            for name, weight in order:
                if name not in active:
                    continue
                for _ in range(max(weight, 1)):
                    if queues[name] and len(picked) < want:
                        picked.append(queues[name].pop(0))
    return picked


# --- Output ----------------------------------------------------------------

def render(zone, cards):
    file_name, _, display = ZONES[zone]
    kind_order = {"boss": 0, "elite": 1, "rare": 2, "npc": 3, "creature": 4, "quest": 5, "item": 6}

    def sort_key(c):
        prefix, number = c["id"].split(":")[1].rsplit("_", 1)
        return (-c["rarity"], kind_order[c["kind"]], prefix, int(number))

    lines = [
        "local _, ns = ...",
        "",
        "-- %s (%d): cards generated by scripts/generate-cards.py from the" % (display, zone),
        "-- AzerothCore world database. Do not edit by hand: change the script and",
        "-- re-run it. Names are English localization keys; flavor comes from level",
        "-- and creature type (CardText.flavor). Icons unverified on Forever (/wd art).",
        "ns.Cards.addCards(%d, {" % zone,
    ]
    for c in cards:
        check_card(c)
    for c in sorted(cards, key=sort_key):
        fields = ["id = %s" % lua_string(c["id"]), 'kind = "%s"' % c["kind"],
                  "rarity = %d" % c["rarity"], "name = %s" % lua_string(c["name"]),
                  'icon = "%s"' % c["icon"]]
        if "entry" in c:
            fields += ["npcID = %d" % c["entry"], "level = %d" % c["level"],
                       'creatureType = "%s"' % c["creatureType"]]
        if "questID" in c:
            fields.append("questID = %d" % c["questID"])
            if 1 <= c["level"] <= 63:
                fields.append("level = %d" % c["level"])
        if "itemID" in c:
            fields.append("itemID = %d" % c["itemID"])
        lines.append("  { " + ", ".join(fields) + " },")
    lines += ['}, "generated")', ""]
    return "\n".join(lines)


# Loose on purpose: a hand-reformatted file (tabs, {id="..."}) still counts.
GENERATED_ID = re.compile(r'''(?:\bid|\[\s*["']id["']\s*\])\s*=\s*(?:"([^"\n]*)"|'([^'\n]*)'|\[\[([^\]\n]*)\]\])''')
SHIPPED_BATCH = re.compile(r'"([0-9]+):generated"')


def removed_ids(old_text, new_cards):
    """Card IDs of an existing generated file that the new cards no longer have, sorted."""
    kept = {c["id"] for c in new_cards}
    old = {"".join(groups) for groups in GENERATED_ID.findall(old_text)}
    return sorted(old - kept)


def shipped_zones(loaded_text):
    """Zones whose generated batch Data/Loaded.lua expects."""
    return {int(z) for z in SHIPPED_BATCH.findall(loaded_text)}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("sql_folder", help="AzerothCore data/sql/base/db_world folder")
    parser.add_argument("--repo", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    parser.add_argument("--report", action="store_true", help="print counts to stderr")
    parser.add_argument("--allow-removed-ids", action="store_true",
                        help="write even when a card ID of an existing generated file disappears")
    args = parser.parse_args()

    result = build(args.sql_folder, args.repo, args.report)
    out_dir = os.path.join(args.repo, "Data", "Generated")
    os.makedirs(out_dir, exist_ok=True)
    lost = {}
    loaded_path = os.path.join(args.repo, "Data", "Loaded.lua")
    shipped = set()
    if os.path.isfile(loaded_path):
        with open(loaded_path, encoding="utf-8") as handle:
            shipped = shipped_zones(handle.read())
    for zone in ZONE_ORDER:
        path = os.path.join(out_dir, ZONES[zone][0] + ".lua")
        if os.path.isfile(path):
            with open(path, encoding="utf-8") as handle:
                gone = removed_ids(handle.read(), result[zone][0])
            if gone:
                lost[zone] = gone
        elif zone in shipped:
            # Listed in Loaded.lua but missing: nothing to compare against.
            lost[zone] = ["(generated file missing, cannot check)"]
    if lost and not args.allow_removed_ids:
        for zone in sorted(lost):
            print("%s would lose %s" % (ZONES[zone][0], ", ".join(lost[zone])), file=sys.stderr)
        sys.exit("Shipped card IDs would disappear and players would lose those cards. Add a "
                 "migration that rewrites them, then re-run with --allow-removed-ids.")
    for zone in ZONE_ORDER:
        cards, hand_count, available = result[zone]
        path = os.path.join(out_dir, ZONES[zone][0] + ".lua")
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(render(zone, cards))
        if args.report:
            by_rarity = Counter(c["rarity"] for c in cards)
            by_kind = Counter(c["kind"] for c in cards)
            print("%-20s %d hand %2d + generated %3d (of %4d candidates) rarity %s kind %s" % (
                ZONES[zone][2], CONTINENTS[ZONES[zone][1]], hand_count, len(cards), available,
                dict(sorted(by_rarity.items())), dict(sorted(by_kind.items()))), file=sys.stderr)


if __name__ == "__main__":
    main()
