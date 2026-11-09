local _, ns = ...

-- Loch Modan. uiMapID 1432 from the Classic UiMapID table (warcraft.wiki.gg); not yet
-- probed on Forever. Candidates and sources in docs/research/02-dun-morogh-to-burning-steppes.md
-- Icons from the list validated in game.
ns.Cards.registerZone({
  zoneMapID = 1432,
  continentMapID = 1415,
  cards = {
    { id = "1432:large_loch_crocolisk", kind = "rare", rarity = 4, name = "Large Loch Crocolisk", npcID = 2476, icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "The lake's biggest jaws, and they know it." },
    { id = "1432:mogrosh_stronghold", kind = "place", rarity = 4, name = "Mo'grosh Stronghold", icon = "INV_Misc_Head_Gnoll_01", areaID = 143,
      flavor = "An ogre den that most travelers wisely walk around." },
    { id = "1432:kackle", kind = "elite", rarity = 4, name = "Kackle", icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "A crocolisk with more muscle than the rest of its kin." },
    { id = "1432:lord_condar", kind = "rare", rarity = 3, name = "Lord Condar", npcID = 14268, icon = "Ability_Hunter_Pet_Vulture",
      flavor = "A rare bird that rules the skies over the loch." },
    { id = "1432:shanda_the_spinner", kind = "rare", rarity = 3, name = "Shanda the Spinner", npcID = 14266, icon = "Ability_Hunter_Pet_Spider",
      flavor = "She weaves her web where hunters least expect it." },
    { id = "1432:thelsamar", kind = "place", rarity = 2, name = "Thelsamar", icon = "INV_Drink_05", areaID = 144,
      flavor = "The dwarven town where every trip around the loch begins." },
    { id = "1432:stonewrought_dam", kind = "place", rarity = 2, name = "Stonewrought Dam", icon = "Trade_BlackSmithing", areaID = 146,
      flavor = "A huge dam that holds back the whole loch." },
    { id = "1432:loch_crocolisk", kind = "creature", rarity = 1, name = "Loch Crocolisk", npcID = 1693, icon = "Ability_Hunter_Pet_Scorpid",
      flavor = "It lurks in the shallows and snaps at anything that wades in." },
    { id = "1432:stonesplinter_trogg", kind = "creature", rarity = 1, name = "Stonesplinter Trogg", npcID = 1161, icon = "INV_Misc_Head_Kobold_01",
      flavor = "Small, grubby and always up to no good in the caves." },
    { id = "1432:kobold", kind = "creature", rarity = 1, name = "Kobold", npcID = 1202, icon = "INV_Misc_Head_Kobold_01",
      flavor = "A mine digger who guards his tunnel with a candle and a grudge." },
  },
})
