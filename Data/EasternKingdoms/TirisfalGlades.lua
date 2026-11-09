local _, ns = ...

-- Tirisfal Glades, with Undercity and the Scarlet Monastery folded in.
-- uiMapID 1420 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Sources in docs/research/03-tirisfal-to-plaguelands.md.
-- Icons unverified: /wd art.
ns.Cards.registerZone({
  zoneMapID = 1420,
  continentMapID = 1415,
  cards = {
    { id = "1420:decrepit_darkhound", kind = "creature", rarity = 1, name = "Decrepit Darkhound", icon = "Ability_Hunter_Pet_Wolf",
      flavor = "Death did not make it any friendlier." },
    { id = "1420:rattlecage_skeleton", kind = "creature", rarity = 1, name = "Rattlecage Skeleton", icon = "Spell_Shadow_RaiseDead",
      flavor = "Loud bones in a quiet graveyard." },
    { id = "1420:rotting_dead", kind = "creature", rarity = 1, name = "Rotting Dead", icon = "Spell_Shadow_AnimateDead",
      flavor = "They shamble on, long after the plague." },
    { id = "1420:vile_fin_puddlejumper", kind = "creature", rarity = 1, name = "Vile Fin Puddlejumper", icon = "INV_Misc_Head_Murloc_01",
      flavor = "The lake has guests, and they bite." },
    { id = "1420:vicious_night_web_spider", kind = "creature", rarity = 1, name = "Vicious Night Web Spider", icon = "Ability_Hunter_Pet_Spider",
      flavor = "Its webs catch more than flies in the dark." },
    { id = "1420:scarlet_warrior", kind = "creature", rarity = 1, name = "Scarlet Warrior", icon = "INV_Shield_06",
      flavor = "Zeal in red, and no doubt at all." },
    { id = "1420:deathknell", kind = "place", rarity = 2, name = "Deathknell", icon = "Spell_Shadow_DeathScream", areaID = 154,
      flavor = "Where the Forsaken rise from their graves." },
    { id = "1420:brill", kind = "place", rarity = 2, name = "Brill", icon = "INV_Drink_05", areaID = 159,
      flavor = "An inn for the dead, and the living who dare." },
    { id = "1420:ruins_of_lordaeron", kind = "place", rarity = 2, name = "Ruins of Lordaeron", icon = "Spell_Shadow_Twilight", areaID = 153,
      flavor = "A fallen capital above a hidden one." },
    { id = "1420:undercity", kind = "place", rarity = 3, name = "Undercity", icon = "Spell_Shadow_GatherShadows", areaID = 1497,
      flavor = "The Forsaken built their home in the old crypts." },
    { id = "1420:fellicents_shade", kind = "rare", rarity = 3, name = "Fellicent's Shade", icon = "Spell_Shadow_ShadowWordPain",
      flavor = "A ghost that never left its sorrow." },
    { id = "1420:ressan_the_needler", kind = "rare", rarity = 3, name = "Ressan the Needler", icon = "INV_Misc_Bone_HumanSkull_01",
      flavor = "Patient, sharp, and always nearby." },
    { id = "1420:scarlet_monastery", kind = "place", rarity = 4, name = "Scarlet Monastery", icon = "Spell_Holy_HolySmite", areaID = 796,
      flavor = "The Crusade's fortress, full of burning faith." },
    { id = "1420:scarlet_commander_mograine", kind = "boss", rarity = 4, name = "Scarlet Commander Mograine", icon = "Spell_Holy_SealOfWrath",
      flavor = "He leads the cathedral guard with a heavy hand." },
    { id = "1420:high_inquisitor_whitemane", kind = "boss", rarity = 5, name = "High Inquisitor Whitemane", icon = "Spell_Holy_Resurrection",
      flavor = "She raises the fallen to fight again." },
    { id = "1420:sylvanas_windrunner", kind = "lore", rarity = 5, name = "Sylvanas Windrunner", icon = "INV_Weapon_Bow_02",
      flavor = "The Banshee Queen rules those who refused to stay dead." },
    { id = "1420:varimathras", kind = "npc", rarity = 4, name = "Varimathras", icon = "Spell_Shadow_SummonImp",
      flavor = "The dreadlord who sits at the Banshee Queen's right hand, and keeps his own counsel." },
    { id = "1420:master_apothecary_faranell", kind = "npc", rarity = 4, name = "Master Apothecary Faranell", icon = "Spell_Nature_Regenerate",
      flavor = "Head of the Royal Apothecary Society, brewing the plague's cure and its worse cousins." },
  },
})
