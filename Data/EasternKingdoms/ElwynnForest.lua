local _, ns = ...

-- Elwynn Forest. uiMapID 1429 is the Classic-era ID (unverified on Forever:
-- run /wd probe in Elwynn). Names are English localization keys; flavor text
-- is original. Rarity: 1 Common, 2 Uncommon, 3 Rare, 4 Epic, 5 Legendary.
ns.Cards.registerZone({
  zoneMapID = 1429,
  continentMapID = 1415,
  cards = {
    { id = "1429:young_wolf", kind = "creature", rarity = 1, name = "Young Wolf",
      flavor = "Its howl is more of a squeak, but the pack still listens." },
    { id = "1429:stonetusk_boar", kind = "creature", rarity = 1, name = "Stonetusk Boar",
      flavor = "Tusks first, questions never." },
    { id = "1429:kobold_vermin", kind = "creature", rarity = 1, name = "Kobold Vermin",
      flavor = "Guards its candle like a crown." },
    { id = "1429:forest_spider", kind = "creature", rarity = 1, name = "Forest Spider",
      flavor = "Strings its webs between the oaks of Elwynn." },
    { id = "1429:riverpaw_runt", kind = "creature", rarity = 1, name = "Riverpaw Runt",
      flavor = "Smallest of the Riverpaw, and the loudest." },
    { id = "1429:defias_thug", kind = "creature", rarity = 1, name = "Defias Thug",
      flavor = "Red bandana, empty pockets, bad intentions." },
    { id = "1429:northshire_abbey", kind = "place", rarity = 2, name = "Northshire Abbey",
      flavor = "Where many heroes took their first steps." },
    { id = "1429:goldshire", kind = "place", rarity = 2, name = "Goldshire",
      flavor = "A warm inn, a busy crossroads, and rumors on every table." },
    { id = "1429:fargodeep_mine", kind = "place", rarity = 2, name = "Fargodeep Mine",
      flavor = "The kobolds dig a little deeper every year." },
    { id = "1429:jasperlode_mine", kind = "place", rarity = 2, name = "Jasperlode Mine",
      flavor = "Its tunnels hide more than ore." },
    { id = "1429:marshal_mcbride", kind = "npc", rarity = 2, name = "Marshal McBride",
      flavor = "Keeps Northshire's recruits busy and its valley safe." },
    { id = "1429:marshal_dughan", kind = "npc", rarity = 3, name = "Marshal Dughan",
      flavor = "Goldshire's marshal never runs short of tasks." },
    { id = "1429:gruff_swiftbite", kind = "rare", rarity = 3, name = "Gruff Swiftbite",
      flavor = "Strikes before the forest notices." },
    { id = "1429:mother_fang", kind = "rare", rarity = 3, name = "Mother Fang",
      flavor = "Queen of the spiders beneath Jasperlode." },
    { id = "1429:princess", kind = "elite", rarity = 4, name = "Princess",
      flavor = "The prize boar of the Brackwell farm, fiercely guarded." },
    { id = "1429:hogger", kind = "elite", rarity = 5, name = "Hogger",
      flavor = "The gnoll every adventurer remembers." },
  },
})
