local _, ns = ...

-- Stranglethorn Vale signature cards. uiMapID 1434 from the Classic UiMapID table
-- (warcraft.wiki.gg), as listed in the "## uiMapIDs" table of the research note;
-- not yet probed on Forever. Candidates and sources: docs/research/01-elwynn-to-stranglethorn.md.
-- Icons are from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1434,
  continentMapID = 1415,
  cards = {
    { id = "1434:king_bangalash", kind = "elite", rarity = 5, name = "King Bangalash", icon = "Ability_Hunter_Pet_Cat",
      flavor = "The white tiger every big-game hunter dreams of bagging." },
    { id = "1434:baron_revilgaz", kind = "npc", rarity = 5, name = "Baron Revilgaz", icon = "INV_Misc_Coin_01",
      flavor = "The goblin who runs Booty Bay and counts every coin." },
    { id = "1434:gurubashi_arena", kind = "place", rarity = 4, name = "Gurubashi Arena", icon = "Ability_Warrior_WarCry",
      flavor = "A troll arena on the southern cape where fights are public." },
    { id = "1434:roloch", kind = "rare", rarity = 3, name = "Roloch", icon = "Ability_Hunter_Pet_Cat",
      flavor = "A rare jungle prowler that avoids the main trails." },
    { id = "1434:rippa", kind = "rare", rarity = 3, name = "Rippa", icon = "Ability_Druid_CatForm",
      flavor = "A rare beast with a long memory for hunters." },
    { id = "1434:hemet_nesingwary_jr", kind = "npc", rarity = 4, name = "Hemet Nesingwary Jr.", icon = "Ability_Hunter_Pet_Boar",
      flavor = "The famous hunter who hands out beast-hunting contracts." },
    { id = "1434:booty_bay", kind = "place", rarity = 2, name = "Booty Bay", icon = "INV_Misc_Coin_01",
      flavor = "A goblin port where every deal has a price." },
    { id = "1434:gromgol_base_camp", kind = "place", rarity = 2, name = "Grom'gol Base Camp", icon = "INV_BannerPVP_01",
      flavor = "A Horde camp perched on the northwest coast." },
    { id = "1434:stranglethorn_raptor", kind = "creature", rarity = 1, name = "Stranglethorn Raptor", icon = "Ability_Hunter_Pet_TallStrider",
      flavor = "Quick, toothy and always hungry." },
    { id = "1434:panther", kind = "creature", rarity = 1, name = "Panther", icon = "Ability_Hunter_Pet_Cat",
      flavor = "A dark cat that stalks the jungle shade." },
  },
})
