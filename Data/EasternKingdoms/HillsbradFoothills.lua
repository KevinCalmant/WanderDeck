local _, ns = ...

-- Hillsbrad Foothills. uiMapID 1424 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/03-tirisfal-to-plaguelands.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1424,
  continentMapID = 1415,
  cards = {
    { id = "1424:durnholde_keep", kind = "place", rarity = 4, name = "Durnholde Keep", icon = "INV_BannerPVP_01", areaID = 275,
      flavor = "A fortress that once held a whole people captive." },
    { id = "1424:marshal_redpath", kind = "npc", rarity = 5, name = "Marshal Redpath", npcID = 2263, icon = "Ability_Warrior_DefensiveStance",
      flavor = "The Alliance marshal who keeps watch over the foothills." },
    { id = "1424:high_executor_darthalia", kind = "npc", rarity = 5, name = "High Executor Darthalia", npcID = 2215, icon = "Spell_Shadow_DeathScream",
      flavor = "The Forsaken commander who runs Tarren Mill." },
    { id = "1424:purgation_isle", kind = "place", rarity = 3, name = "Purgation Isle", icon = "Spell_Shadow_AnimateDead", areaID = 896,
      flavor = "A small island that belongs to the restless dead." },
    { id = "1424:magistrate_henry_maleb", kind = "npc", rarity = 4, name = "Magistrate Henry Maleb", npcID = 2276, icon = "INV_Misc_Head_Dwarf_01",
      flavor = "The civic leader who keeps Southshore running." },
    { id = "1424:southshore", kind = "place", rarity = 2, name = "Southshore", icon = "INV_Drink_05", areaID = 271,
      flavor = "A quiet Alliance town on the coast." },
    { id = "1424:tarren_mill", kind = "place", rarity = 2, name = "Tarren Mill", icon = "INV_Misc_Gear_01", areaID = 272,
      flavor = "A Horde-held mill town and a famous place for a brawl." },
    { id = "1424:mountain_lion", kind = "creature", rarity = 1, name = "Mountain Lion", npcID = 2406, icon = "Ability_Hunter_Pet_Cat",
      flavor = "A big cat that watches the ridges from above." },
    { id = "1424:yeti", kind = "creature", rarity = 1, name = "Yeti", npcID = 2248, icon = "Ability_Hunter_Pet_Bear",
      flavor = "A shaggy snow ape from the northern hills." },
    { id = "1424:naga", kind = "creature", rarity = 1, name = "Naga", npcID = 2371, icon = "Spell_Frost_FrostArmor02",
      flavor = "A serpent-folk fighter from the shore." },
  },
})
