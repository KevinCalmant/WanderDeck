local _, ns = ...

-- Westfall. uiMapID 1436 confirmed by /wd probe on Forever. Names are English
-- localization keys; flavor text is original.
-- Rarity: 1 Common, 2 Uncommon, 3 Rare, 4 Epic, 5 Legendary.
ns.Cards.registerZone({
  zoneMapID = 1436,
  continentMapID = 1415,
  cards = {
    { id = "1436:harvest_watcher", kind = "creature", rarity = 1, name = "Harvest Watcher",
      flavor = "The scarecrow now guards the fields for someone else." },
    { id = "1436:fleshripper", kind = "creature", rarity = 1, name = "Fleshripper",
      flavor = "Circles patiently above the dry plains." },
    { id = "1436:riverpaw_gnoll", kind = "creature", rarity = 1, name = "Riverpaw Gnoll",
      flavor = "The Riverpaw roam far beyond their river." },
    { id = "1436:defias_trapper", kind = "creature", rarity = 1, name = "Defias Trapper",
      flavor = "Sets snares along the roads at dusk." },
    { id = "1436:dust_devil", kind = "creature", rarity = 1, name = "Dust Devil",
      flavor = "A whirl of sand that remembers being wind." },
    { id = "1436:sentinel_hill", kind = "place", rarity = 2, name = "Sentinel Hill",
      flavor = "The People's Militia holds the line from this hill." },
    { id = "1436:moonbrook", kind = "place", rarity = 2, name = "Moonbrook",
      flavor = "A town left to the Defias." },
    { id = "1436:saldeans_farm", kind = "place", rarity = 2, name = "Saldean's Farm",
      flavor = "Still standing, still farming, still hoping." },
    { id = "1436:jangolode_mine", kind = "place", rarity = 2, name = "Jangolode Mine",
      flavor = "A quiet entrance, busy shadows." },
    { id = "1436:gryan_stoutmantle", kind = "npc", rarity = 3, name = "Gryan Stoutmantle",
      flavor = "Founder of the People's Militia, stubborn as stone." },
    { id = "1436:foe_reaper_4000", kind = "rare", rarity = 3, name = "Foe Reaper 4000",
      flavor = "A harvest golem that reaps more than wheat." },
    { id = "1436:leprithus", kind = "rare", rarity = 3, name = "Leprithus",
      flavor = "Rises from the soil when night falls on Westfall." },
    { id = "1436:old_murk_eye", kind = "elite", rarity = 4, name = "Old Murk-Eye",
      flavor = "The oldest murloc on the coast, and the grumpiest." },
    { id = "1436:the_deadmines", kind = "place", rarity = 4, name = "The Deadmines",
      flavor = "Beneath Moonbrook, a ship waits in the dark." },
    { id = "1436:edwin_vancleef", kind = "boss", rarity = 5, name = "Edwin VanCleef",
      flavor = "The stonemason who became the Defias kingpin." },
  },
})
