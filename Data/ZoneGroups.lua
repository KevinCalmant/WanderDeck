local _, ns = ...

-- Cities fold into the outdoor zone around them (user decision, see
-- docs/FEATURES.md "Zone grouping"): walking in Stormwind earns Elwynn Forest
-- packs, and Stormwind cards belong to the Elwynn Forest set.
-- uiMapIDs are the Classic-era ones; only Westfall (1436) is confirmed on
-- Forever so far. Check each city with /wd probe (Zone.resolve line) and fix
-- the ID here if it differs.
local fold = ns.Cards.foldZone

fold(1453, 1429) -- Stormwind City -> Elwynn Forest
fold(1455, 1426) -- Ironforge -> Dun Morogh
fold(1457, 1438) -- Darnassus -> Teldrassil
fold(1454, 1411) -- Orgrimmar -> Durotar
fold(1458, 1420) -- Undercity -> Tirisfal Glades
fold(1456, 1412) -- Thunder Bluff -> Mulgore
