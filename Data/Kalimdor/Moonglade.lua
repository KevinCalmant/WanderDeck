local _, ns = ...

-- Moonglade: hand-written signature cards. uiMapID 1450 from the Classic table of
-- https://warcraft.wiki.gg/wiki/UiMapID; Kalimdor 1414. Not yet probed on Forever.
-- Sources in docs/research/05-northern-kalimdor.md. Icons from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1450,
  continentMapID = 1414,
  cards = {
    { id = "1450:keeper_remulos", kind = "npc", rarity = 5, name = "Keeper Remulos", icon = "Spell_Nature_Tranquility",
      flavor = "The level 62 elite guardian of the sacred valley." },
    { id = "1450:the_nightmare_manifests", kind = "quest", rarity = 4, name = "The Nightmare Manifests", icon = "Spell_Shadow_Twilight",
      flavor = "Defend Nighthaven from Eranikus without killing him." },
    { id = "1450:omen", kind = "boss", rarity = 4, name = "Omen", icon = "Spell_Nature_StarFall",
      flavor = "A sleeping demigod in the central lake." },
    { id = "1450:elunes_blessing", kind = "quest", rarity = 3, name = "Elune's Blessing", icon = "Spell_Holy_ElunesGrace",
      flavor = "A festival quest: defeat Omen, then report to Valadar Starsong." },
    { id = "1450:moonglade_quest", kind = "quest", rarity = 3, name = "Moonglade", icon = "Ability_Druid_CatForm",
      flavor = "The druid class quest that sends you to the valley." },
    { id = "1450:nighthaven", kind = "place", rarity = 2, name = "Nighthaven", icon = "Spell_Nature_MoonGlow",
      flavor = "The druid settlement and capital of Moonglade." },
    { id = "1450:lake_eluneara", kind = "place", rarity = 2, name = "Lake Elune'ara", icon = "Spell_Nature_Rejuvenation",
      flavor = "The central lake of the valley." },
    { id = "1450:lunar_festival_reveler", kind = "npc", rarity = 1, name = "Lunar Festival Reveler", icon = "INV_Drink_05",
      flavor = "A level 55 festival-goer in the valley." },
    { id = "1450:wildkin", kind = "creature", rarity = 1, name = "Wildkin", icon = "Ability_Hunter_Pet_Owl",
      flavor = "An owl-like beast of the sacred valley." },
  },
})
