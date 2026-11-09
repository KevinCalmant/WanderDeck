local _, ns = ...

-- Azshara: hand-written signature cards. uiMapID 1447 from the Classic table of
-- https://warcraft.wiki.gg/wiki/UiMapID; Kalimdor 1414. Not yet probed on Forever.
-- Sources in docs/research/05-northern-kalimdor.md. Icons from the validated list.
ns.Cards.registerZone({
  zoneMapID = 1447,
  continentMapID = 1414,
  cards = {
    { id = "1447:duke_hydraxis", kind = "npc", rarity = 5, name = "Duke Hydraxis", icon = "Spell_Frost_Frostbolt02",
      flavor = "A water lord who sends heroes against the elementals." },
    { id = "1447:lord_arkkoroc", kind = "npc", rarity = 4, name = "Lord Arkkoroc", icon = "Spell_Shadow_DeathScream",
      flavor = "A naga lord ruling from a watery temple." },
    { id = "1447:ruins_of_eldarath", kind = "place", rarity = 4, name = "Ruins of Eldarath", icon = "Spell_Shadow_GatherShadows", areaID = 1221,
      flavor = "The ruined site of a Highborne city." },
    { id = "1447:loramus_thalipedes", kind = "npc", rarity = 4, name = "Loramus Thalipedes", icon = "Spell_Shadow_SummonImp",
      flavor = "A demon hunter watching from his island refuge." },
    { id = "1447:general_fangferror", kind = "rare", rarity = 3, name = "General Fangferror", icon = "Ability_Hunter_Pet_Wolf",
      flavor = "A rare with a general's rank and a hunter's patience." },
    { id = "1447:scalebeard", kind = "rare", rarity = 3, name = "Scalebeard", icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "A rare of the Azshara coast, as scaly as its name." },
    { id = "1447:camp_valormok", kind = "place", rarity = 2, name = "Camp Valormok", icon = "INV_BannerPVP_01",
      flavor = "A Horde settlement on the north coast." },
    { id = "1447:talrendis_point", kind = "place", rarity = 2, name = "Talrendis Point", icon = "INV_Weapon_Bow_02", areaID = 3137,
      flavor = "An Alliance settlement on the coast." },
    { id = "1447:spitelash_warrior", kind = "creature", rarity = 1, name = "Spitelash Warrior", icon = "Ability_Warrior_BattleShout",
      flavor = "A naga fighter who guards the shore." },
    { id = "1447:sea_giant", kind = "creature", rarity = 1, name = "Sea Giant", icon = "Spell_Nature_Earthquake",
      flavor = "A towering coast-dweller with a heavy tread." },
  },
})
