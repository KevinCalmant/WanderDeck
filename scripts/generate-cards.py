#!/usr/bin/env python3
"""Generate WanderDeck card files from the AzerothCore world database.

Writes one Data/Generated/<ZoneName>.lua per shipped zone. Each file calls
    ns.Cards.addCards(<zoneMapID>, { ... }, "generated")
after the zone's hand-written Data file (Data/load_data.xml sets the order).
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
  (DUNGEON_MAPS).

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
  no cap); border strays: outdoor creatures whose kept quests (started by
  them, or asking to kill them) are mostly sorted to another outdoor zone and
  none to theirs. One card per name: boss > elite > rare > npc > creature,
  then most spawns, then lowest entry.
  Quests: started (creature_queststarter) by a creature of the zone, ID < 9300,
  QuestLevel and MinLevel <= 60, not repeatable (SpecialFlags & 1), not daily
  or weekly, not a world-event or PvP quest, not a holiday sort, one per name.
  Items: green or better (quality 2-4) rewards of those quests, and direct
  (non-reference) loot of the zone's creatures; no random enchantment
  (RandomProperty/RandomSuffix), weapons and armor only (no recipes, gems,
  trade goods or quest items), required level <= 60, entry < 24000.
  Names: 1-64 bytes of printable ASCII without "|" (anything else is skipped,
  which also satisfies ns.Utils.isCleanText). Entities whose English name
  matches a hand-written card (of any zone: it already exists as a card),
  case-insensitive, are skipped. Spawns in EXCLUDED_BOXES (Stormwind Harbor,
  a WotLK addition) and mount vendor display models ("Riding" names) too.

Heuristics
  kind/rarity: boss (rank 3, flags_extra DUNGEON_BOSS 0x10000000, or the kill
  credit of an instance_encounters row: vanilla dungeon bosses are rank 1) 4,
  elite (rank 1-2) 3, rare (rank 4) 3, npc (quest giver, vendor, trainer,
  flight master, innkeeper, banker, ...; never a critter) 2 when it starts a
  kept quest or is a flight master or innkeeper, else 1, creature 1. Quests 2
  (3 for group, dungeon or raid quests). Items: quality 2/3/4 -> rarity
  2/3/4. Never 5 (each zone has one hand-written Legendary).
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
"""

import argparse
import math
import os
import re
import sys
from collections import Counter, defaultdict

# --- Zones -----------------------------------------------------------------

# uiMapID -> (file name, Data folder, display name)
ZONES = {
    1429: ("ElwynnForest", "EasternKingdoms", "Elwynn Forest"),
    1436: ("Westfall", "EasternKingdoms", "Westfall"),
    1426: ("DunMorogh", "EasternKingdoms", "Dun Morogh"),
    1420: ("TirisfalGlades", "EasternKingdoms", "Tirisfal Glades"),
    1438: ("Teldrassil", "Kalimdor", "Teldrassil"),
    1411: ("Durotar", "Kalimdor", "Durotar"),
    1412: ("Mulgore", "Kalimdor", "Mulgore"),
}
ZONE_ORDER = [1429, 1436, 1426, 1420, 1438, 1411, 1412]

# Cities fold into the outdoor zone around them (Data/ZoneGroups.lua).
CITY_PARENT = {1453: 1429, 1455: 1426, 1457: 1438, 1454: 1411, 1458: 1420, 1456: 1412}

# Dungeon map ID -> zone holding its entrance.
DUNGEON_MAPS = {
    34: 1429,   # The Stockade
    36: 1436,   # The Deadmines
    90: 1426,   # Gnomeregan
    189: 1420,  # Scarlet Monastery
    389: 1411,  # Ragefire Chasm
}

# Quest sort (AreaTable) IDs of each zone, its cities and its dungeons: quests
# sorted there rank first among a zone's quests.
ZONE_AREAS = {
    1429: {12, 1519, 717},
    1436: {40, 1581},
    1426: {1, 1537, 721},
    1420: {85, 1497, 796},
    1438: {141, 1657},
    1411: {14, 1637, 2437},
    1412: {215, 1638},
}
DUNGEON_AREAS = {717, 1581, 721, 796, 2437}

# Highest level a hostile creature outside cities and dungeons may have to
# count for the zone (neighbour-zone mobs near a border are higher).
LEVEL_CAP = {1429: 12, 1436: 20, 1426: 13, 1420: 13, 1438: 12, 1411: 12, 1412: 12}

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


def hand_written_names(repo, zone_map_id):
    file_name, folder, _ = ZONES[zone_map_id]
    path = os.path.join(repo, "Data", folder, file_name + ".lua")
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    return {n.lower() for n in re.findall(r'\bname = "((?:[^"\\]|\\.)*)"', text)}, \
        len(re.findall(r'\bid = "', text))


# --- Build -----------------------------------------------------------------

def build(sql, repo, report):
    event_guids = {r["guid"] for r in read_table(sql, "game_event_creature", ["eventEntry", "guid"])
                   if r["eventEntry"] > 0}
    encounter_bosses = {r["creditEntry"] for r in read_table(sql, "instance_encounters", [
        "creditType", "creditEntry"]) if r["creditType"] == 0}
    templates = {r["entry"]: r for r in read_table(sql, "creature_template", [
        "entry", "name", "subname", "minlevel", "maxlevel", "rank", "type", "family",
        "npcflag", "unit_flags", "flags_extra", "lootid"])}

    # Spawns per template and zone.
    spawns = defaultdict(Counter)        # entry -> Counter(zone)
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
        zone = zone_of_spawn(r["map"], r["position_x"], r["position_y"])
        if zone is None:
            continue
        sheltered = in_city_or_dungeon(r["map"], r["position_x"], r["position_y"])
        for entry in {r["id1"], r["id2"], r["id3"]} - {0}:
            spawns[entry][zone] += 1
            if sheltered:
                capped[(entry, zone)] = False

    starters = defaultdict(set)  # entry -> quest IDs
    for r in read_table(sql, "creature_queststarter", ["id", "quest"]):
        starters[r["id"]].add(r["quest"])

    # Each template's home zone: the shipped zone with most spawns. A template
    # with more spawns outside every shipped zone is left out.
    home = {}
    for entry, counts in spawns.items():
        zone, count = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[0]
        home[entry] = (zone, count)

    skipped = Counter()
    creatures = defaultdict(list)  # zone -> candidate cards
    for entry, (zone, count) in sorted(home.items()):
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
        level = int((t["minlevel"] + t["maxlevel"]) / 2 + 0.5)
        if not (1 <= t["minlevel"] and 1 <= level <= 63 and t["maxlevel"] <= 63):
            skipped["creature level"] += 1
            continue
        is_npc = bool(t["npcflag"] & (NPC_FLAG_QUESTGIVER | NPC_FLAG_SERVICES)) or entry in starters
        rank = t["rank"]
        if rank == 3 or t["flags_extra"] & FLAG_EXTRA_DUNGEON_BOSS or entry in encounter_bosses:
            kind, rarity = "boss", 4
        elif rank in (1, 2):
            kind, rarity = "elite", 3
        elif rank == 4:
            kind, rarity = "rare", 3
        elif is_npc and ctype != "Critter":  # a quest-giving chicken stays a critter
            kind, rarity = "npc", 1
        else:
            kind, rarity = "creature", 1
        if kind == "creature" and capped[(entry, zone)] and level > LEVEL_CAP[zone]:
            skipped["creature above zone level cap"] += 1
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
    strays = set()
    for entry, (zone, _) in home.items():
        if not capped[(entry, zone)]:
            continue
        sorts = Counter(quests_raw[q]["QuestSortID"] for q in related.get(entry, ()) if quest_ok(quests_raw.get(q)))
        if not sorts or any(area in ZONE_AREAS[zone] for area in sorts):
            continue
        area, count = sorted(sorts.items(), key=lambda kv: (-kv[1], kv[0]))[0]
        if area in outdoor_areas and 2 * count > sum(sorts.values()):
            strays.add(entry)
    skipped["border stray (quests of a neighbour zone)"] = len(strays)

    zone_quests = defaultdict(dict)  # zone -> questID -> quest
    for entry, (zone, _) in home.items():
        t = templates.get(entry)
        if not t or entry >= MAX_CREATURE_ENTRY or entry in strays:
            continue
        for qid in starters.get(entry, ()):
            q = quests_raw.get(qid)
            if quest_ok(q):
                zone_quests[zone][qid] = q

    # A name hand-written in any zone is already a card: no generated twin.
    all_hand = set()
    for zone in ZONE_ORDER:
        all_hand |= hand_written_names(repo, zone)[0]

    out = {}
    for zone in ZONE_ORDER:
        hand_count = hand_written_names(repo, zone)[1]
        used = set(all_hand)
        cands = []

        # Creatures: one per name, best kind first.
        priority = {"boss": 0, "elite": 1, "rare": 2, "npc": 3, "creature": 4}
        for c in sorted(creatures[zone], key=lambda c: (priority[c["kind"]], -c["spawns"], c["entry"])):
            if c["entry"] in strays:
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
        for qid in sorted(zone_quests[zone]):
            q = zone_quests[zone][qid]
            key = q["LogTitle"].lower()
            if key in used:
                skipped["duplicate or hand-written name"] += 1
                continue
            used.add(key)
            group = (q["QuestInfoID"] in QUEST_INFO_GROUP or q["SuggestedGroupNum"] >= 2
                     or q["QuestSortID"] in DUNGEON_AREAS)
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

        out[zone] = (select(cands, TARGET_TOTAL - hand_count), hand_count, len(cands))
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


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("sql_folder", help="AzerothCore data/sql/base/db_world folder")
    parser.add_argument("--repo", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    parser.add_argument("--report", action="store_true", help="print counts to stderr")
    args = parser.parse_args()

    result = build(args.sql_folder, args.repo, args.report)
    out_dir = os.path.join(args.repo, "Data", "Generated")
    os.makedirs(out_dir, exist_ok=True)
    for zone in ZONE_ORDER:
        cards, hand_count, available = result[zone]
        path = os.path.join(out_dir, ZONES[zone][0] + ".lua")
        with open(path, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(render(zone, cards))
        if args.report:
            by_rarity = Counter(c["rarity"] for c in cards)
            by_kind = Counter(c["kind"] for c in cards)
            print("%-16s hand %2d + generated %3d (of %4d candidates) rarity %s kind %s" % (
                ZONES[zone][2], hand_count, len(cards), available,
                dict(sorted(by_rarity.items())), dict(sorted(by_kind.items()))), file=sys.stderr)


if __name__ == "__main__":
    main()
