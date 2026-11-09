# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [SemVer](https://semver.org/).

## [Unreleased]

### Changed

- The card collection is account-wide: owned cards, copies, New flags, tags and pins are shared by all your characters. Steps, pack progress and unopened packs stay per character. On first load, each character's existing collection is merged into the account one (copies summed, up to 999 per card; tags, pins and New flags combined), so no card is lost. Saved data layout version 2.

### Added

- Creature cards with an `npcID` show the creature's 3D model in their art panel (prototype, `Config.CARD_MODELS`); the icon stays until the model loads and remains when it never does. 280 of the 288 hand-written creature cards got an `npcID`: 241 by exact English name (Hogger, Vol'jin; a generic name such as "Raptor" takes the vanilla creature of that name) and 39 picked by hand from the zone's creatures ("Yeti" in Alterac is a Mountain Yeti). Lore cards naming a character (Thrall, Sylvanas, ...) show their model too. Five cards with no NPC on Forever (checked on Wowhead's Forever database) were removed: Twilight Lord Bathiel, Highlord Kruul, Brann Bronzebeard, Mountain Giant and Bog Beast. Durgen Dirgehammer, Kackle and Rexxar take their Forever NPC IDs. Developer `/wd model <npcID>` (or `display <displayID>`) checks a model on the client.
- French card names in a French client: generated cards (creatures, NPCs, quests, items) and hand-written creature cards get their French name from `Locales/frFR_Generated.lua` (built from the AzerothCore locale tables; a name with any character outside French letters and punctuation is skipped), and 134 place cards take their localized name from the client (`areaID`).
- Rarer Epics and Legendaries: about 1 pack in 10 holds an Epic and 1 in 40 a Legendary (was 1 in 5 and 1 in 20).
- Addon skeleton: TOC for WoW Forever (Interface 16001), AceDB saved variables, `/wd` slash command.
- Step tracking: walking on foot outdoors counts steps; mounted, taxi, vehicle, dead, instance and teleport moves are ignored.
- Pack earning: one counter per character; each pack goes to the zone where most of its steps were walked.
- About 120 cards per zone: creatures, NPCs, elites, rares, dungeon bosses, quests and items generated from the AzerothCore world database by `scripts/generate-cards.py`, on top of the hand-written cards.
- Cards for the 33 other outdoor zones of Eastern Kingdoms and Kalimdor (40 in all): 9-10 hand-written cards each, with one Legendary, plus generated cards up to about 120 per zone. Deadwind Pass, Moonglade and a few high-level zones have fewer.
- Leading NPCs are Legendary (1 to 3 per zone, e.g. Bolvar Fordragon and Anduin Wrynn in Elwynn) and notable NPCs Epic; iconic cards such as Hogger stay Legendary, filler Legendaries became Epic. 14 new NPC cards.
- Binder cards are sorted rarest first (pinned cards still lead).
- Binder zone list in pages, one continent at a time, sorted by name; `<` and `>` under the list switch pages (it showed only 14 zones before).
- Translated flavor text goes through the same checks as names; a bad translation falls back to English.
- Cards for the five starting zones: Dun Morogh (17, with Ironforge, Gnomeregan and the Hall of Thanes), Tirisfal Glades (16, with Undercity and the Scarlet Monastery), Teldrassil (14, with Darnassus), Durotar (14, with Orgrimmar and Ragefire Chasm) and Mulgore (15, with Thunder Bluff).
- Cards for Elwynn Forest (16) and Westfall (15), with five rarities and attack/defense derived from kind and rarity.
- `/wd open` opens the oldest pack (5 cards, at least one Uncommon) into the collection; `/wd cards` shows collection progress per zone. A zone without cards draws from its continent, then from every card.
- Minimap button: left-click opens the binder, right-click opens a pack, drag to move; badge with unopened packs and a progress tooltip. `/wd minimap` shows or hides it.
- Tags and pins: from a card's detail window, pin it to the top of its binder page, mark it For trade, or add up to 5 tags of your own; the binder filters by tag.
- Sounds on pack opening and card reveal (Epic and Legendary have their own); `/wd sound` mutes them. Developer `/wd sounds` checks which sounds exist on the client.
- Loot sound when walking earns a pack (every 1,500 steps); silent at the pack limit, muted by `/wd sound`.
- Missing-card protection: each card of a pack has a 50% chance to be one of its rarity you do not own yet, so zones of ~120 cards stay completable.
- Cards can carry an item, quest or area ID: their name (and an item's icon) then comes from the game, in your language.
- Illustrated card style: gold double frame, title bar with rarity gem, art panel with a game icon per card, attack/defense medallions; flip-in animation on reveal and a pulsing halo on Epic and Legendary cards. Windows and buttons use the same dark-and-gold look, drawn without texture files.
- Epic and Legendary reveal effects in the pack window: a burst in the rarity color, sparks, a light sweep across the card and a pop; Legendary is bigger and adds turning rays. The binder stays still. Developer `/wd fx [mix|epic|legendary]` opens a fake pack (never saved) to watch them.
- Developer `/wd art` lists every card with its icon to spot icons missing on the client.
- Pack opening window: cards start face down, click to flip or Reveal all, then Open next.
- Binder (`/wd binder`): zones with completion, 3x3 card grid, missing cards as silhouettes, filters (owned, missing, duplicates), rarity filter, name search, paging; viewing a card clears its New tag.
- `/wd status` shows steps walked, progress to the next pack and unopened packs.
- Developer `/wd probe` command that reports which position, map and movement APIs work on the client.
