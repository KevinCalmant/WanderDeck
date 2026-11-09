local _, ns = ...

-- Western Plaguelands. uiMapID 1422 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/03-tirisfal-to-plaguelands.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1422,
  continentMapID = 1415,
  cards = {
    { id = "1422:uthers_tomb", kind = "place", rarity = 4, name = "Uther's Tomb", icon = "Spell_Holy_SealOfMight",
      flavor = "The resting place of a paladin whose name still carries weight." },
    { id = "1422:scholomance", kind = "place", rarity = 4, name = "Scholomance", icon = "Spell_Shadow_RaiseDead",
      flavor = "A school of necromancy on an island of the dead." },
    { id = "1422:hearthglen", kind = "place", rarity = 4, name = "Hearthglen", icon = "Spell_Holy_HolySmite",
      flavor = "A Scarlet Crusade stronghold that trusts no stranger." },
    { id = "1422:andorhal", kind = "place", rarity = 3, name = "Andorhal", icon = "Spell_Shadow_AnimateDead",
      flavor = "A ruined town overrun by the undead." },
    { id = "1422:commander_ashlam_valorfist", kind = "npc", rarity = 4, name = "Commander Ashlam Valorfist", icon = "Spell_Holy_SealOfWrath",
      flavor = "The Argent Dawn commander at Chillwind Camp." },
    { id = "1422:caer_darrow", kind = "place", rarity = 3, name = "Caer Darrow", icon = "Spell_Shadow_Twilight",
      flavor = "The island that holds the Scholomance." },
    { id = "1422:chillwind_camp", kind = "place", rarity = 2, name = "Chillwind Camp", icon = "INV_Shield_06",
      flavor = "An Alliance camp among the ruins." },
    { id = "1422:sorrow_hill", kind = "place", rarity = 2, name = "Sorrow Hill", icon = "Spell_Shadow_DeathScream",
      flavor = "A quiet hill crowned by a crypt." },
    { id = "1422:zombie", kind = "creature", rarity = 1, name = "Zombie", icon = "Spell_Shadow_AnimateDead",
      flavor = "A plague-risen dead that never stops walking." },
    { id = "1422:ooze", kind = "creature", rarity = 1, name = "Ooze", icon = "Spell_Nature_ProtectionformNature",
      flavor = "A plague slime oozing across the fields." },
    { id = "1422:darkmaster_gandling", kind = "npc", rarity = 5, name = "Darkmaster Gandling", icon = "Spell_Shadow_GatherShadows",
      flavor = "The headmaster whose school never lets its pupils graduate alive." },
  },
})
