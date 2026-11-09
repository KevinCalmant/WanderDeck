local _, ns = ...

-- Zephras Isle, the Skyborne starting zone (Forever only, so no AzerothCore
-- data and no generated batch). uiMapID 2521 from the client's UiMap table
-- (wago.tools, build 1.60.1.70862): a Zone whose parent is Azeroth (947), not a
-- continent, so 947 stands in as its continent. Not yet probed in game.
-- Sources: warcraft.wiki.gg pages of each NPC, plus the Warcraft Tavern
-- walkthrough. npcIDs are the Forever ones listed there; Lorthuna, Rohash and
-- Ayessa have no confirmed Forever ID.
ns.Cards.registerZone({
  zoneMapID = 2521,
  continentMapID = 947,
  cards = {
    { id = "2521:high_priestess_lorthuna", kind = "boss", rarity = 5, name = "High Priestess Lorthuna", creatureType = "Humanoid", icon = "Spell_Shadow_Curse",
      flavor = "The cult leader who called a storm lord down on the isle." },
    { id = "2521:rohash", kind = "boss", rarity = 4, name = "Rohash", creatureType = "Elemental", icon = "Spell_Nature_Cyclone",
      flavor = "Lord of the east wind, summoned to the isle by the cult." },
    { id = "2521:ayessa_dawnsinger", kind = "npc", rarity = 4, name = "Ayessa Dawnsinger", creatureType = "Humanoid", icon = "Spell_Nature_Tranquility",
      flavor = "The Grand Skyseer who leads the Windshapers in Valanaar." },
    { id = "2521:commander_cyclas", kind = "elite", rarity = 4, name = "Commander Cyclas", npcID = 251966, level = 8, creatureType = "Humanoid", icon = "Ability_Warrior_BattleShout",
      flavor = "A cult officer holding Falaath Village with shock spells." },
    { id = "2521:vulgara_the_insatiable", kind = "elite", rarity = 4, name = "Vulgara the Insatiable", npcID = 254589, level = 8, creatureType = "Beast", icon = "Ability_Hunter_Pet_Wolf",
      flavor = "A hungry vuldren with a bounty on her head." },
    { id = "2521:badwind_bennic", kind = "rare", rarity = 3, name = "\"Badwind\" Bennic", npcID = 255534, level = 7, creatureType = "Humanoid", icon = "Ability_Rogue_Ambush",
      flavor = "The bandit boss lurking in his hideout." },
    { id = "2521:urs_anah", kind = "rare", rarity = 3, name = "Urs'anah", npcID = 251115, level = 5, creatureType = "Beast", icon = "Ability_Hunter_Pet_Bear",
      flavor = "The den mother of Thendal Cave, with a stunning slam." },
    { id = "2521:hippogryph_matriarch", kind = "rare", rarity = 3, name = "Hippogryph Matriarch", npcID = 251261, level = 7, creatureType = "Beast", icon = "Ability_Druid_TravelForm",
      flavor = "She guards the hippogryphs of the Shen'dar Highlands." },
    { id = "2521:shriekling_matriarch", kind = "rare", rarity = 3, name = "Shriekling Matriarch", npcID = 253283, level = 9, creatureType = "Beast", icon = "Ability_Hunter_Pet_Vulture",
      flavor = "A brood mother screeching deep in the Shriekling Den." },
    { id = "2521:cirrusfly_queen", kind = "rare", rarity = 3, name = "Cirrusfly Queen", npcID = 251404, level = 3, creatureType = "Beast", icon = "Spell_Nature_StarFall",
      flavor = "The queen of the glowing swarm in Thendal Grove." },
    { id = "2521:rorian_the_dayseeker", kind = "npc", rarity = 2, name = "Rorian the Dayseeker", npcID = 251361, creatureType = "Humanoid", icon = "Spell_Holy_HolySmite",
      flavor = "A Thendal Village elder who starts newcomers on their path." },
    { id = "2521:windshaper_boro", kind = "npc", rarity = 2, name = "Windshaper Boro", npcID = 251374, level = 5, creatureType = "Humanoid", icon = "Spell_Nature_LightningShield",
      flavor = "The Windshaper who trains shamans in Thendal Village." },
    { id = "2521:ursera_scavenger", kind = "creature", rarity = 1, name = "Ursera Scavenger", npcID = 250937, level = 4, creatureType = "Beast", icon = "Ability_Hunter_Pet_Bear",
      flavor = "A scavenging bear prowling the Thendal caves." },
    { id = "2521:pesky_cirrusfly", kind = "creature", rarity = 1, name = "Pesky Cirrusfly", npcID = 251169, level = 1, creatureType = "Beast", icon = "Spell_Nature_StarFall",
      flavor = "A glowing pest, and many a newcomer's first kill." },
    { id = "2521:valanaar", kind = "place", rarity = 2, name = "Valanaar", icon = "INV_BannerPVP_01",
      flavor = "The isle's main town, with skydocks to both mainlands." },
    { id = "2521:thendal_village", kind = "place", rarity = 2, name = "Thendal Village", icon = "INV_Misc_Horn_01",
      flavor = "The village where Skyborne newcomers take their first steps." },
    { id = "2521:shriekling_den", kind = "place", rarity = 2, name = "Shriekling Den", icon = "Ability_Hunter_Pet_Spider",
      flavor = "A noisy lair in the south of the isle." },
    { id = "2521:in_service_of_zephras", kind = "quest", rarity = 3, name = "In Service of Zephras", icon = "Spell_Holy_SealOfMight",
      flavor = "A climb to the top of a tower to answer the isle's call." },
    { id = "2521:foul_matriarch", kind = "quest", rarity = 3, name = "Foul Matriarch", icon = "Ability_Hunter_Pet_Bear",
      flavor = "Thin out the ursera in the cave and bring back their den mother's head." },
  },
})
