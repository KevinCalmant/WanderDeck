local _, ns = ...

-- Swamp of Sorrows signature cards. uiMapID 1435 from the Classic UiMapID table
-- (warcraft.wiki.gg), as listed in the "## uiMapIDs" table of the research note;
-- not yet probed on Forever. Candidates and sources: docs/research/04-southern-eastern-kingdoms.md.
-- Icons are from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1435,
  continentMapID = 1415,
  cards = {
    { id = "1435:shade_of_eranikus", kind = "boss", rarity = 5, name = "Shade of Eranikus", icon = "Spell_Shadow_Twilight",
      flavor = "A fallen green dragon waiting at the bottom of the temple." },
    { id = "1435:jammalan_the_prophet", kind = "boss", rarity = 4, name = "Jammal'an the Prophet", icon = "Spell_Shadow_ShadowWordPain",
      flavor = "The Atal'ai leader who keeps the temple's faith alive." },
    { id = "1435:temple_of_atalhakkar", kind = "place", rarity = 4, name = "Temple of Atal'Hakkar", icon = "Spell_Nature_ProtectionformNature",
      flavor = "A sunken temple that the swamp never gave back." },
    { id = "1435:itharius", kind = "npc", rarity = 3, name = "Itharius", icon = "Spell_Nature_Regenerate",
      flavor = "A ranger tied to the green dragons, met in the swamp." },
    { id = "1435:fingat", kind = "rare", rarity = 3, name = "Fingat", icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "A rare lurker of the marsh, seldom seen twice." },
    { id = "1435:fallen_hero_of_the_horde", kind = "npc", rarity = 3, name = "Fallen Hero of the Horde", icon = "Spell_Holy_Resurrection",
      flavor = "A lone figure of a cleansing quest near the border." },
    { id = "1435:stonard", kind = "place", rarity = 2, name = "Stonard", icon = "INV_BannerPVP_01", areaID = 75,
      flavor = "The Horde outpost and travel hub of the marsh." },
    { id = "1435:sorrowmurk", kind = "place", rarity = 2, name = "Sorrowmurk", icon = "Spell_Nature_Rejuvenation", areaID = 1778,
      flavor = "A dreary patch where dragonspawn elites gather." },
    { id = "1435:swamp_jaguar", kind = "creature", rarity = 1, name = "Swamp Jaguar", icon = "Ability_Hunter_Pet_Cat",
      flavor = "A marsh cat that stalks along the water." },
    { id = "1435:green_dragonspawn", kind = "creature", rarity = 1, name = "Green Dragonspawn", icon = "Spell_Nature_Tranquility",
      flavor = "A dreaming dragonkin that patrols for Ysera." },
  },
})
