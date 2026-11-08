# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [SemVer](https://semver.org/).

## [Unreleased]

### Added

- Addon skeleton: TOC for WoW Forever (Interface 16001), AceDB saved variables, `/wd` slash command.
- Step tracking: walking on foot outdoors counts steps; mounted, taxi, vehicle, dead, instance and teleport moves are ignored.
- Pack earning: one counter per character; each pack goes to the zone where most of its steps were walked.
- About 120 cards per zone: creatures, NPCs, elites, rares, dungeon bosses, quests and items generated from the AzerothCore world database by `scripts/generate-cards.py`, on top of the hand-written cards.
- Cards for the 33 other outdoor zones of Eastern Kingdoms and Kalimdor (40 in all): 9-10 hand-written cards each, with one Legendary, plus generated cards up to about 120 per zone. Deadwind Pass, Moonglade and a few high-level zones have fewer.
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
- Developer `/wd art` lists every card with its icon to spot icons missing on the client.
- Pack opening window: cards start face down, click to flip or Reveal all, then Open next.
- Binder (`/wd binder`): zones with completion, 3x3 card grid, missing cards as silhouettes, filters (owned, missing, duplicates), rarity filter, name search, paging; viewing a card clears its New tag.
- `/wd status` shows steps walked, progress to the next pack and unopened packs.
- Developer `/wd probe` command that reports which position, map and movement APIs work on the client.
