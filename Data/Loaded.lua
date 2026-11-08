local _, ns = ...

-- Every zone and every addCards batch Data/ ships. Add a zone here when you
-- add its file, and a batch ("<zoneMapID>:<batch>") when you add a generated
-- file: Data counts as loaded only when all of them registered (a file that
-- errors, or one left out of the package, keeps saved cards from being
-- deleted). spec/Cards_spec.lua checks both lists against the Data files.
ns.Cards.EXPECTED_ZONES = { 1411, 1412, 1420, 1426, 1429, 1436, 1438 }
ns.Cards.EXPECTED_BATCHES = {
  "1411:generated", "1412:generated", "1420:generated", "1426:generated",
  "1429:generated", "1436:generated", "1438:generated",
}

ns.Cards.markLoaded(ns.Cards.EXPECTED_ZONES, ns.Cards.EXPECTED_BATCHES)
