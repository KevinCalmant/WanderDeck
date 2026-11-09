local _, ns = ...

-- The Barrens, with its dungeons folded in. uiMapID 1413 from the Classic UiMapID table
-- (warcraft.wiki.gg/wiki/UiMapID); Kalimdor 1414 from memory. Not yet probed on Forever.
-- Candidates and sources: docs/research/06-central-southern-kalimdor.md.
ns.Cards.registerZone({
  zoneMapID = 1413,
  continentMapID = 1414,
  cards = {
    { id = "1413:amnennar_the_coldbringer", kind = "boss", rarity = 4, name = "Amnennar the Coldbringer", icon = "Spell_Frost_Frostbolt02",
      flavor = "A frost-wreathed lich who turned a quilboar warren into a tomb." },
    { id = "1413:wailing_caverns", kind = "place", rarity = 4, name = "Wailing Caverns", icon = "Spell_Nature_Regenerate", areaID = 718,
      flavor = "Overgrown caves in Lushwater Oasis where the echoes never rest." },
    { id = "1413:razorfen_kraul", kind = "place", rarity = 4, name = "Razorfen Kraul", icon = "INV_Misc_Head_Quillboar_01", areaID = 1717,
      flavor = "A thorn-walled quilboar warren in the far south of the plains." },
    { id = "1413:razorfen_downs", kind = "place", rarity = 3, name = "Razorfen Downs", icon = "Spell_Shadow_AnimateDead", areaID = 1316,
      flavor = "Quilboar halls where the dead refuse to stay buried." },
    { id = "1413:kolkar_centaur", kind = "creature", rarity = 3, name = "Kolkar Centaur", icon = "Ability_Warrior_BattleShout",
      flavor = "A raider of a hostile clan that never stops harrying the plains." },
    { id = "1413:the_crossroads", kind = "place", rarity = 2, name = "The Crossroads", icon = "Ability_Warrior_WarCry", areaID = 380,
      flavor = "The Horde's central outpost, where every road in the savannah meets." },
    { id = "1413:ratchet", kind = "place", rarity = 2, name = "Ratchet", icon = "INV_Misc_Coin_01", areaID = 392,
      flavor = "A neutral goblin port on the east coast, open to all for a price." },
    { id = "1413:zhevra", kind = "creature", rarity = 1, name = "Zhevra", icon = "Ability_Hunter_Pet_TallStrider",
      flavor = "A striped grazer that bolts across the savannah at the first sign of danger." },
    { id = "1413:savannah_lion", kind = "creature", rarity = 1, name = "Savannah Lion", icon = "Ability_Hunter_Pet_Cat",
      flavor = "A big cat that stalks the tall grass of the plains." },
    { id = "1413:razormane_quilboar", kind = "creature", rarity = 1, name = "Razormane Quilboar", icon = "INV_Misc_Head_Quillboar_01",
      flavor = "Boar-folk who pitch their thorny camps across the savannah." },
    { id = "1413:mankrik", kind = "npc", rarity = 4, name = "Mankrik", icon = "INV_Sword_04",
      flavor = "Grieving orc blademaster who hunts quilboar across the Barrens after burying his wife Olgra." },
  },
})
