local _, ns = ...

-- Arathi Highlands. uiMapID 1417 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/03-tirisfal-to-plaguelands.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1417,
  continentMapID = 1415,
  cards = {
    { id = "1417:stromgarde_keep", kind = "place", rarity = 4, name = "Stromgarde Keep", icon = "INV_Shield_06",
      flavor = "The ruined seat of a once-proud human kingdom." },
    { id = "1417:galen_trollbane", kind = "npc", rarity = 5, name = "Galen Trollbane", icon = "Ability_Warrior_BattleShout",
      flavor = "A noble of Stromgarde who still carries the old name." },
    { id = "1417:arathi_basin", kind = "place", rarity = 4, name = "Arathi Basin", icon = "INV_BannerPVP_01",
      flavor = "A battleground entrance where armies race for resources." },
    { id = "1417:thandol_span", kind = "place", rarity = 3, name = "Thandol Span", icon = "Trade_Mining",
      flavor = "A great bridge that links the highlands to the Wetlands." },
    { id = "1417:captain_steelgut", kind = "npc", rarity = 4, name = "Captain Steelgut", icon = "INV_Shield_06",
      flavor = "A captain with work for any traveler who stops." },
    { id = "1417:hammerfall", kind = "place", rarity = 2, name = "Hammerfall", icon = "INV_Misc_Horn_01",
      flavor = "A Horde outpost in hostile land." },
    { id = "1417:refuge_pointe", kind = "place", rarity = 2, name = "Refuge Pointe", icon = "INV_Shield_06",
      flavor = "An Alliance outpost where weary travelers rest." },
    { id = "1417:raptor", kind = "creature", rarity = 1, name = "Raptor", icon = "Ability_Hunter_Pet_TallStrider",
      flavor = "A fast hunting lizard, always on the move." },
    { id = "1417:ogre", kind = "creature", rarity = 1, name = "Ogre", icon = "INV_Misc_Head_Gnoll_01",
      flavor = "A Boulderfist brute with fists like boulders." },
    { id = "1417:forest_troll", kind = "creature", rarity = 1, name = "Forest Troll", icon = "INV_Misc_Head_Troll_01",
      flavor = "A Witherbark warrior who guards his tribe's land." },
  },
})
