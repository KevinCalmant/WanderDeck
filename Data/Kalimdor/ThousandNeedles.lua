local _, ns = ...

-- Thousand Needles, with its dungeons folded in. uiMapID 1441 from the Classic UiMapID table
-- (warcraft.wiki.gg/wiki/UiMapID); Kalimdor 1414 from memory. Not yet probed on Forever.
-- Candidates and sources: docs/research/06-central-southern-kalimdor.md.
ns.Cards.registerZone({
  zoneMapID = 1441,
  continentMapID = 1414,
  cards = {
    { id = "1441:arnak_grimtotem", kind = "npc", rarity = 5, name = "Arnak Grimtotem", icon = "INV_Misc_Head_Tauren_01",
      flavor = "The Grimtotem chief who is listed as the ruler of these mesas." },
    { id = "1441:the_great_lift", kind = "place", rarity = 4, name = "The Great Lift", icon = "INV_Gizmo_02",
      flavor = "An elevator that carries travelers from the Barrens up to the mesas." },
    { id = "1441:mirage_raceway", kind = "place", rarity = 4, name = "Mirage Raceway", icon = "INV_Misc_Gear_01",
      flavor = "A goblin racetrack with bets, engines and plenty of dust." },
    { id = "1441:rau_cliffrunner", kind = "npc", rarity = 4, name = "Rau Cliffrunner", icon = "INV_Misc_Head_Tauren_01",
      flavor = "A Freewind Post contact who sends heroes after a fire phial." },
    { id = "1441:harb_foulmountain", kind = "rare", rarity = 3, name = "Harb Foulmountain", icon = "Spell_Nature_Earthquake",
      flavor = "A rare spawn that few travelers meet twice." },
    { id = "1441:gibblesnik", kind = "rare", rarity = 3, name = "Gibblesnik", icon = "Ability_Hunter_Pet_Spider",
      flavor = "Another rare of the needles, hard to spot and harder to forget." },
    { id = "1441:freewind_post", kind = "place", rarity = 2, name = "Freewind Post", icon = "Ability_Warrior_DefensiveStance",
      flavor = "A tauren outpost in the southeast, built on the edge of the mesas." },
    { id = "1441:shimmering_flats", kind = "place", rarity = 2, name = "Shimmering Flats", icon = "INV_Misc_Gear_01",
      flavor = "A wide basin that once served as a racing ground." },
    { id = "1441:wind_serpent", kind = "creature", rarity = 1, name = "Wind Serpent", icon = "Spell_Nature_Cyclone",
      flavor = "A flying serpent that coils through the air above the mesas." },
  },
})
