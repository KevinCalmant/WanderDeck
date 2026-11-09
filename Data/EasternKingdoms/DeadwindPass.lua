local _, ns = ...

-- Deadwind Pass signature cards. uiMapID 1430 from the Classic UiMapID table
-- (warcraft.wiki.gg), as listed in the "## uiMapIDs" table of the research note;
-- not yet probed on Forever. Candidates and sources: docs/research/04-southern-eastern-kingdoms.md.
-- Icons are from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1430,
  continentMapID = 1415,
  cards = {
    { id = "1430:medivh", kind = "lore", rarity = 5, name = "Medivh", icon = "Spell_Shadow_Twilight",
      flavor = "The tower's old master, long gone but never forgotten." },
    { id = "1430:karazhan", kind = "place", rarity = 4, name = "Karazhan", icon = "Spell_Shadow_GatherShadows", areaID = 2562,
      flavor = "A tower looming over the pass, full of old secrets." },
    { id = "1430:forgotten_crypt", kind = "place", rarity = 4, name = "Forgotten Crypt", icon = "Spell_Shadow_DeathScream",
      flavor = "A haunted crypt with more rooms than visitors survive." },
    { id = "1430:deadwind_ogre", kind = "creature", rarity = 3, name = "Deadwind Ogre", icon = "Ability_ThunderClap",
      flavor = "One of the many ogres who claim the pass for themselves." },
    { id = "1430:wraith", kind = "creature", rarity = 3, name = "Wraith", icon = "Spell_Shadow_DeathCoil",
      flavor = "A spectral dead that drifts through the canyon." },
    { id = "1430:deadman_crossing", kind = "place", rarity = 2, name = "Deadman's Crossing", icon = "INV_Misc_Bone_HumanSkull_01", areaID = 2697,
      flavor = "A road crossing with a name that warns you." },
    { id = "1430:the_vice", kind = "place", rarity = 2, name = "The Vice", icon = "Ability_Warrior_BattleShout", areaID = 2561,
      flavor = "The ogre ground that holds the Grosh'gok Compound." },
    { id = "1430:vulture", kind = "creature", rarity = 1, name = "Vulture", icon = "Ability_Hunter_Pet_Vulture",
      flavor = "A scavenger bird circling over the canyon." },
    { id = "1430:shade", kind = "creature", rarity = 1, name = "Shade", icon = "Spell_Shadow_GatherShadows",
      flavor = "A dark spirit among the wild things of the pass." },
  },
})
