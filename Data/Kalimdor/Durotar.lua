local _, ns = ...

-- Durotar, with Orgrimmar and Ragefire Chasm folded in. uiMapID 1411 from the
-- Classic UiMapID table (warcraft.wiki.gg); Kalimdor 1414 from memory. Not yet
-- probed on Forever. Sources in docs/research/06-central-southern-kalimdor.md.
-- Icons unverified: /wd art.
ns.Cards.registerZone({
  zoneMapID = 1411,
  continentMapID = 1414,
  cards = {
    { id = "1411:mottled_boar", kind = "creature", rarity = 1, name = "Mottled Boar", icon = "Ability_Hunter_Pet_Boar",
      flavor = "Red dust on its hide, red eyes on you." },
    { id = "1411:clattering_scorpid", kind = "creature", rarity = 1, name = "Clattering Scorpid", icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "You hear its plates long before its sting." },
    { id = "1411:razormane_quilboar", kind = "creature", rarity = 1, name = "Razormane Quilboar", icon = "INV_Misc_Head_Quillboar_01",
      flavor = "Spears, thorns, and a grudge against the Horde." },
    { id = "1411:durotar_tiger", kind = "creature", rarity = 1, name = "Durotar Tiger", icon = "Ability_Hunter_Pet_Cat",
      flavor = "Striped like the canyon at sunset." },
    { id = "1411:kul_tiras_marine", kind = "creature", rarity = 1, name = "Kul Tiras Marine", icon = "INV_Sword_04",
      flavor = "A long way from home, and not welcome here." },
    { id = "1411:valley_of_trials", kind = "place", rarity = 2, name = "Valley of Trials", icon = "Ability_Warrior_WarCry",
      flavor = "Every young orc's first test is here." },
    { id = "1411:razor_hill", kind = "place", rarity = 2, name = "Razor Hill", icon = "Ability_Warrior_DefensiveStance",
      flavor = "A spiked outpost on the road to the capital." },
    { id = "1411:senjin_village", kind = "place", rarity = 2, name = "Sen'jin Village", icon = "INV_Misc_Head_Troll_01",
      flavor = "Darkspear huts by the warm southern sea." },
    { id = "1411:orgrimmar", kind = "place", rarity = 2, name = "Orgrimmar", icon = "INV_BannerPVP_01",
      flavor = "The Horde's capital, carved from red stone." },
    { id = "1411:gazzuz", kind = "npc", rarity = 3, name = "Gazz'uz", icon = "Spell_Shadow_DeathCoil",
      flavor = "A Burning Blade warlock hiding in the caves." },
    { id = "1411:voljin", kind = "elite", rarity = 5, name = "Vol'jin", icon = "Spell_Shadow_ShadowWordPain",
      flavor = "The Darkspear leader keeps his trolls together." },
    { id = "1411:ragefire_chasm", kind = "place", rarity = 4, name = "Ragefire Chasm", icon = "Spell_Fire_Volcano",
      flavor = "Fire and cultists under the capital's feet." },
    { id = "1411:taragaman_the_hungerer", kind = "boss", rarity = 4, name = "Taragaman the Hungerer", icon = "Spell_Fire_Incinerate",
      flavor = "A demon whose hunger never cools." },
    { id = "1411:thrall", kind = "lore", rarity = 5, name = "Thrall", icon = "Spell_Nature_LightningShield",
      flavor = "The Warchief who led his people to a new land." },
    { id = "1411:eitrigg", kind = "npc", rarity = 4, name = "Eitrigg", icon = "Ability_Warrior_WarCry",
      flavor = "Grizzled orc veteran who counsels Thrall in the throne room of Orgrimmar." },
    { id = "1411:nazgrel", kind = "npc", rarity = 4, name = "Nazgrel", icon = "INV_Sword_04",
      flavor = "Thrall's trusted warrior, posted by the throne to keep watch over Orgrimmar." },
    { id = "1411:zalazane", kind = "npc", rarity = 4, name = "Zalazane", icon = "Spell_Shadow_Curse",
      flavor = "Echo Isles witch doctor who enslaved the Darkspear trolls until heroes ended his rule." },
  },
})
