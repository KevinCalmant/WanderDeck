local _, ns = ...

-- Duskwood signature cards. uiMapID 1431 from the Classic UiMapID table
-- (warcraft.wiki.gg), as listed in the "## uiMapIDs" table of the research note;
-- not yet probed on Forever. Candidates and sources: docs/research/01-elwynn-to-stranglethorn.md.
-- Icons are from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1431,
  continentMapID = 1415,
  cards = {
    { id = "1431:stitches", kind = "elite", rarity = 5, name = "Stitches", icon = "Spell_Shadow_RaiseDead",
      flavor = "A patchwork horror that lumbers out of the dark to find you." },
    { id = "1431:morladim", kind = "elite", rarity = 4, name = "Mor'Ladim", icon = "Spell_Shadow_AnimateDead",
      flavor = "A skeletal terror that never stays buried." },
    { id = "1431:eliza", kind = "elite", rarity = 4, name = "Eliza", icon = "Spell_Shadow_DeathCoil",
      flavor = "The embalmer's bride, and she does not forgive." },
    { id = "1431:lord_malathrom", kind = "rare", rarity = 3, name = "Lord Malathrom", icon = "Spell_Shadow_Curse",
      flavor = "An undead noble who still rules a graveyard." },
    { id = "1431:commander_althea_ebonlocke", kind = "npc", rarity = 4, name = "Commander Althea Ebonlocke", icon = "INV_Shield_06",
      flavor = "The noble who keeps Darkshire's defenders in line." },
    { id = "1431:darkshire", kind = "place", rarity = 2, name = "Darkshire", icon = "INV_Drink_05",
      flavor = "A gloomy town where the lamps burn all day." },
    { id = "1431:raven_hill", kind = "place", rarity = 2, name = "Raven Hill", icon = "Spell_Shadow_GatherShadows",
      flavor = "A hilltop village with a cemetery you will not forget." },
    { id = "1431:worgen", kind = "creature", rarity = 1, name = "Worgen", icon = "Ability_Hunter_Pet_Wolf",
      flavor = "Cursed wolf-men that own the night in these woods." },
    { id = "1431:skeleton", kind = "creature", rarity = 1, name = "Skeleton", icon = "INV_Misc_Bone_HumanSkull_01",
      flavor = "Bones that rise again around every cemetery." },
  },
})
