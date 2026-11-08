local _, ns = ...

-- Searing Gorge signature cards. uiMapID 1427 from the Classic UiMapID table
-- (warcraft.wiki.gg), as listed in the "## uiMapIDs" table of the research note;
-- not yet probed on Forever. Candidates and sources: docs/research/02-dun-morogh-to-burning-steppes.md.
-- Icons are from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1427,
  continentMapID = 1415,
  cards = {
    { id = "1427:highlord_mastrogonde", kind = "elite", rarity = 5, name = "Highlord Mastrogonde", icon = "Spell_Fire_Incinerate",
      flavor = "A rare elite who rules the burning gorge from the shadows." },
    { id = "1427:obsidion", kind = "elite", rarity = 4, name = "Obsidion", icon = "Trade_Mining",
      flavor = "An elite construct of the gorge, hard as the rock it came from." },
    { id = "1427:the_cauldron", kind = "place", rarity = 4, name = "The Cauldron", icon = "Spell_Fire_Volcano",
      flavor = "A Dark Iron pit that hides the Slag Pit within." },
    { id = "1427:smoldar", kind = "rare", rarity = 3, name = "Smoldar", icon = "Spell_Fire_Incinerate",
      flavor = "A rare ember-born thing that smolders on the ground." },
    { id = "1427:slave_master_blackheart", kind = "rare", rarity = 3, name = "Slave Master Blackheart", icon = "Ability_Rogue_Ambush",
      flavor = "A Dark Iron rare who runs a cruel work crew." },
    { id = "1427:thorium_point", kind = "place", rarity = 2, name = "Thorium Point", icon = "INV_Shield_06",
      flavor = "A fortified brotherhood camp and the hub of the gorge." },
    { id = "1427:hansel_heavyhands", kind = "npc", rarity = 2, name = "Hansel Heavyhands", icon = "INV_Misc_Gear_01",
      flavor = "The Thorium Point quest giver tired of golems and spiders." },
    { id = "1427:incendosaur", kind = "creature", rarity = 1, name = "Incendosaur", icon = "Spell_Fire_Volcano",
      flavor = "A fiery lizard that plagues the gorge." },
    { id = "1427:fire_elemental", kind = "creature", rarity = 1, name = "Fire Elemental", icon = "Spell_Fire_Incinerate",
      flavor = "A flame spirit drifting over the scorched ground." },
  },
})
