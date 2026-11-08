local _, ns = ...

-- Every zone Data/ ships. Add a zone here when you add its file: Data counts
-- as loaded only when all of them registered (a file that errors, or one left
-- out of the package, keeps saved cards from being deleted).
-- spec/Cards_spec.lua checks this list against the Data files.
ns.Cards.EXPECTED_ZONES = { 1429, 1436 }

ns.Cards.markLoaded(ns.Cards.EXPECTED_ZONES)
