local _, ns = ...

-- Dun Morogh, with Ironforge, Gnomeregan and the Hall of Thanes (Forever
-- dungeon under Ironforge) folded in. uiMapID 1426 from the Classic UiMapID
-- table (warcraft.wiki.gg); not yet probed on Forever. Sources per card in
-- docs/research/02-dun-morogh-to-burning-steppes.md. Icons unverified: /wd art.
ns.Cards.registerZone({
  zoneMapID = 1426,
  continentMapID = 1415,
  cards = {
    { id = "1426:frostmane_troll_whelp", kind = "creature", rarity = 1, name = "Frostmane Troll Whelp", npcID = 706, icon = "INV_Misc_Head_Troll_01",
      flavor = "Young trolls who still think the valley is theirs." },
    { id = "1426:rockjaw_trogg", kind = "creature", rarity = 1, name = "Rockjaw Trogg", npcID = 707, icon = "Spell_Nature_Earthquake",
      flavor = "Dug up from below, and in a bad mood about it." },
    { id = "1426:leper_gnome", kind = "creature", rarity = 1, name = "Leper Gnome", npcID = 1211, icon = "INV_Misc_Head_Gnome_01",
      flavor = "What the fallout of Gnomeregan left behind." },
    { id = "1426:crag_boar", kind = "creature", rarity = 1, name = "Crag Boar", npcID = 1125, icon = "Ability_Hunter_Pet_Boar",
      flavor = "Thick bristles against the mountain cold." },
    { id = "1426:ice_claw_bear", kind = "creature", rarity = 1, name = "Ice Claw Bear", npcID = 1196, icon = "Ability_Hunter_Pet_Bear",
      flavor = "Hibernation is for bears with better manners." },
    { id = "1426:wendigo", kind = "creature", rarity = 1, name = "Wendigo", npcID = 1135, icon = "Spell_Frost_Frostbolt02",
      flavor = "A howl in the snow, then footprints too big to follow." },
    { id = "1426:coldridge_valley", kind = "place", rarity = 2, name = "Coldridge Valley", icon = "Spell_Frost_FrostArmor02", areaID = 132,
      flavor = "Where dwarves and gnomes learn the cold the hard way." },
    { id = "1426:kharanos", kind = "place", rarity = 2, name = "Kharanos", icon = "INV_Drink_05", areaID = 131,
      flavor = "A hearth, a brewery, and a song that never ends." },
    { id = "1426:ironforge", kind = "place", rarity = 2, name = "Ironforge", icon = "Trade_BlackSmithing", areaID = 1537,
      flavor = "A city carved into the mountain, ringing with anvils." },
    { id = "1426:high_tinker_mekkatorque", kind = "npc", rarity = 5, name = "High Tinker Mekkatorque", npcID = 7937, icon = "INV_Gizmo_02",
      flavor = "King of a people without a home, still drawing plans." },
    { id = "1426:edan_the_howler", kind = "rare", rarity = 3, name = "Edan the Howler", npcID = 1137, icon = "Ability_Warrior_BattleShout",
      flavor = "You hear him long before you see him." },
    { id = "1426:hammerspine", kind = "rare", rarity = 3, name = "Hammerspine", npcID = 1119, icon = "Spell_Nature_Earthquake",
      flavor = "A trogg with a spine as hard as his skull." },
    { id = "1426:great_father_arctikus", kind = "rare", rarity = 4, name = "Great Father Arctikus", npcID = 1260, icon = "Spell_Frost_Frostbolt02",
      flavor = "The eldest of the snow beasts, and the least patient." },
    { id = "1426:mekgineer_thermaplugg", kind = "boss", rarity = 4, name = "Mekgineer Thermaplugg", npcID = 7800, icon = "INV_Misc_Gear_01",
      flavor = "He flooded Gnomeregan and kept the keys." },
    { id = "1426:the_hall_of_thanes", kind = "place", rarity = 4, name = "The Hall of Thanes", icon = "Spell_Holy_SealOfMight",
      flavor = "Old Ironforge sleeps beneath the High Seat." },
    -- npcID from Wowhead's Forever database (a Forever-only NPC, not in AzerothCore).
    { id = "1426:durgen_dirgehammer", kind = "boss", rarity = 4, name = "Durgen Dirgehammer", npcID = 261319, icon = "Spell_Holy_SealOfMight",
      flavor = "The last thane standing in the old halls." },
    { id = "1426:king_magni_bronzebeard", kind = "lore", rarity = 5, name = "King Magni Bronzebeard", npcID = 2784, icon = "INV_Misc_Head_Dwarf_01",
      flavor = "Ironforge's king, as solid as his throne." },
  },
})
