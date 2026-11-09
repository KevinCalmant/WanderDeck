local _, ns = ...

-- Darkshore: hand-written signature cards. uiMapID 1439 from the Classic table of
-- https://warcraft.wiki.gg/wiki/UiMapID; Kalimdor 1414. Not yet probed on Forever.
-- Sources in docs/research/05-northern-kalimdor.md. Icons from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1439,
  continentMapID = 1414,
  cards = {
    { id = "1439:thundris_windweaver", kind = "npc", rarity = 5, name = "Thundris Windweaver", icon = "Ability_Druid_TravelForm",
      flavor = "Night elf lord who rules the long, misty coast." },
    { id = "1439:tower_of_althalaxx", kind = "place", rarity = 4, name = "Tower of Althalaxx", icon = "Spell_Shadow_Twilight",
      flavor = "A mage tower left in ruins, and not by accident." },
    { id = "1439:ruins_of_mathystra", kind = "place", rarity = 4, name = "Ruins of Mathystra", icon = "Spell_Nature_MoonGlow",
      flavor = "Night elf ruins where the shore keeps its old memories." },
    { id = "1439:prospector_remtravel", kind = "npc", rarity = 4, name = "Prospector Remtravel", icon = "Trade_Mining",
      flavor = "An Explorers' League dwarf who will not stop hunting his fossil." },
    { id = "1439:lord_sinslayer", kind = "rare", rarity = 3, name = "Lord Sinslayer", icon = "Spell_Shadow_DeathCoil",
      flavor = "The deadliest rare on the coast, and he knows it." },
    { id = "1439:lady_vespira", kind = "rare", rarity = 3, name = "Lady Vespira", icon = "Spell_Shadow_Curse",
      flavor = "A rare that lurks where few travelers wander." },
    { id = "1439:auberdine", kind = "place", rarity = 2, name = "Auberdine", icon = "INV_Misc_Gear_01",
      flavor = "The one town and travel hub of the whole coast." },
    { id = "1439:grove_of_the_ancients", kind = "place", rarity = 2, name = "Grove of the Ancients", icon = "Spell_Nature_Tranquility",
      flavor = "A druid grove keeping watch on the cultists nearby." },
    { id = "1439:moonkin", kind = "creature", rarity = 1, name = "Moonkin", icon = "Ability_Hunter_Pet_Owl",
      flavor = "An owl-like beast that hoots along the shore." },
    { id = "1439:moonstalker", kind = "creature", rarity = 1, name = "Moonstalker", icon = "Ability_Hunter_Pet_Cat",
      flavor = "A forest cat that stalks in the moonlight." },
  },
})
