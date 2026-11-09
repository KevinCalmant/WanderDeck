local _, ns = ...

-- Eastern Plaguelands. uiMapID 1423 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/03-tirisfal-to-plaguelands.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1423,
  continentMapID = 1415,
  cards = {
    { id = "1423:tirion_fordring", kind = "npc", rarity = 5, name = "Tirion Fordring", icon = "Spell_Holy_SealOfMight",
      flavor = "A fallen paladin who found his way back to the Light." },
    { id = "1423:stratholme", kind = "place", rarity = 4, name = "Stratholme", icon = "Spell_Fire_Incinerate", areaID = 2279,
      flavor = "A burned city where the dead keep their posts." },
    { id = "1423:baron_rivendare", kind = "boss", rarity = 4, name = "Baron Rivendare", icon = "Spell_Shadow_DeathCoil",
      flavor = "A death knight lord who waits at the end of the city." },
    { id = "1423:lights_hope_chapel", kind = "place", rarity = 3, name = "Light's Hope Chapel", icon = "Spell_Holy_ElunesGrace", areaID = 2268,
      flavor = "The Argent Dawn base and hub of the whole zone." },
    { id = "1423:lord_maxwell_tyrosus", kind = "npc", rarity = 4, name = "Lord Maxwell Tyrosus", icon = "Spell_Holy_SealOfWrath",
      flavor = "The Argent Dawn leader at Light's Hope." },
    { id = "1423:nathanos_blightcaller", kind = "npc", rarity = 4, name = "Nathanos Blightcaller", icon = "Ability_Rogue_Ambush",
      flavor = "A Forsaken ranger who walks these blighted lands." },
    { id = "1423:plaguewood", kind = "place", rarity = 2, name = "Plaguewood", icon = "Spell_Nature_ProtectionformNature", areaID = 2277,
      flavor = "A blighted forest where nothing grows right." },
    { id = "1423:darrowshire", kind = "place", rarity = 2, name = "Darrowshire", icon = "Spell_Shadow_GatherShadows", areaID = 2262,
      flavor = "A ghost-haunted village in ruins." },
    { id = "1423:ghoul", kind = "creature", rarity = 1, name = "Ghoul", icon = "Spell_Shadow_RaiseDead",
      flavor = "An undead scavenger with a poor sense of manners." },
    { id = "1423:gargoyle", kind = "creature", rarity = 1, name = "Gargoyle", icon = "Spell_Shadow_GatherShadows",
      flavor = "A stone-winged undead that strikes from above." },
  },
})
