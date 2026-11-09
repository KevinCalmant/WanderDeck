local _, ns = ...

-- Un'Goro Crater, with its dungeons folded in. uiMapID 1449 from the Classic UiMapID table
-- (warcraft.wiki.gg/wiki/UiMapID); Kalimdor 1414 from memory. Not yet probed on Forever.
-- Candidates and sources: docs/research/06-central-southern-kalimdor.md.
ns.Cards.registerZone({
  zoneMapID = 1449,
  continentMapID = 1414,
  cards = {
    { id = "1449:larkorwi", kind = "rare", rarity = 4, name = "Lar'korwi", icon = "Ability_Hunter_Pet_Cat",
      flavor = "An elusive beast that hunters chase across the crater." },
    { id = "1449:blazerunner", kind = "elite", rarity = 4, name = "Blazerunner", icon = "Spell_Fire_Incinerate",
      flavor = "The leader of the fire elementals on Fire Plume Ridge." },
    { id = "1449:terror_run", kind = "place", rarity = 4, name = "Terror Run", icon = "Spell_Shadow_Curse", areaID = 539,
      flavor = "An elite area where a disguised succubus lies in wait." },
    { id = "1449:devilsaur", kind = "creature", rarity = 3, name = "Devilsaur", icon = "Ability_Hunter_Pet_TallStrider",
      flavor = "An apex dinosaur whose leather is highly prized." },
    { id = "1449:ravasaur_matriarch", kind = "rare", rarity = 3, name = "Ravasaur Matriarch", icon = "Ability_Hunter_Pet_TallStrider",
      flavor = "A rare dinosaur that stalks the crater jungle." },
    { id = "1449:uhkloc", kind = "rare", rarity = 3, name = "Uhk'loc", icon = "Ability_Hunter_Pet_Bear",
      flavor = "A rare of the crater that most visitors never see." },
    { id = "1449:fire_plume_ridge", kind = "place", rarity = 2, name = "Fire Plume Ridge", icon = "Spell_Fire_Volcano", areaID = 537,
      flavor = "The volcano at the heart of the crater." },
    { id = "1449:marshals_refuge", kind = "place", rarity = 2, name = "Marshal's Refuge", icon = "INV_Misc_Gear_01", areaID = 541,
      flavor = "An explorer camp that doubles as a flight point." },
    { id = "1449:raptor", kind = "creature", rarity = 1, name = "Raptor", icon = "Ability_Hunter_Pet_Cat",
      flavor = "A quick dinosaur that prowls the crater jungle." },
    { id = "1449:tar_beast", kind = "creature", rarity = 1, name = "Tar Beast", icon = "Ability_Hunter_Pet_Boar",
      flavor = "A sticky creature that bubbles up from the tar pits." },
  },
})
