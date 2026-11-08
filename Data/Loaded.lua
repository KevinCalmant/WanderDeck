local _, ns = ...

-- Every zone and every addCards batch Data/ ships. Add a zone here when you
-- add its file, and a batch ("<zoneMapID>:<batch>") when you add a generated
-- file: Data counts as loaded only when all of them registered (a file that
-- errors, or one left out of the package, keeps saved cards from being
-- deleted). spec/Cards_spec.lua checks both lists against the Data files.
ns.Cards.EXPECTED_ZONES = {
  1411, 1412, 1413, 1416, 1417, 1418, 1419, 1420, 1421, 1422,
  1423, 1424, 1425, 1426, 1427, 1428, 1429, 1430, 1431, 1432,
  1433, 1434, 1435, 1436, 1437, 1438, 1439, 1440, 1441, 1442,
  1443, 1444, 1445, 1446, 1447, 1448, 1449, 1450, 1451, 1452,
}
ns.Cards.EXPECTED_BATCHES = {
  "1411:generated", "1412:generated", "1413:generated", "1416:generated",
  "1417:generated", "1418:generated", "1419:generated", "1420:generated",
  "1421:generated", "1422:generated", "1423:generated", "1424:generated",
  "1425:generated", "1426:generated", "1427:generated", "1428:generated",
  "1429:generated", "1430:generated", "1431:generated", "1432:generated",
  "1433:generated", "1434:generated", "1435:generated", "1436:generated",
  "1437:generated", "1438:generated", "1439:generated", "1440:generated",
  "1441:generated", "1442:generated", "1443:generated", "1444:generated",
  "1445:generated", "1446:generated", "1447:generated", "1448:generated",
  "1449:generated", "1450:generated", "1451:generated", "1452:generated",
}

ns.Cards.markLoaded(ns.Cards.EXPECTED_ZONES, ns.Cards.EXPECTED_BATCHES)
