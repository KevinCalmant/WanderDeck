# Features

Player-facing scope, inspired by WikiMasters (https://wiki-masters.com), a card game built from Wikipedia articles: random packs, rarity from popularity, an album, achievements, duplicate trading. Here the cards come from the zones of WoW Forever and packs come from walking.

Numbers marked _tunable_ are starting values: keep them as named constants in one `Config.lua` so balancing is a one-file edit.

## Release order

1. **V1, solo**: steps → packs → opening → binder → achievements. Nothing depends on another player.
2. **V2, trading**: duplicate exchange between two players who both run the addon.

Out of scope: leaderboards, duels, auctions. They need a trusted server, and an addon only has user-editable SavedVariables.

## 1. Packs

Step counting and zone binding follow the Domain rules in `CLAUDE.md`: one counter, and each pack goes to the zone where most of its steps were walked.

- One pack every `STEPS_PER_PACK` steps (_tunable_, start at 2 000). Unopened packs are capped at `MAX_UNOPENED_PACKS` (_tunable_, 20); past the cap, steps still count toward achievements but earn no pack.
- A pack holds `CARDS_PER_PACK` cards (_tunable_, 5), all from the pack's zone pool (with the fallbacks from `CLAUDE.md`), and guarantees one card of Uncommon or better.
- Earning a pack prints one chat line and updates a small counter on the minimap button. The opening happens on demand.

## 2. Cards

A card is static data in `Data/<Continent>/<Zone>.lua`:

| Field | Meaning |
|---|---|
| `id` | Stable string, `<zoneMapID>:<slug>`; never reused once shipped, since SavedVariables reference it |
| `zoneMapID` | Zone uiMapID |
| `kind` | `creature`, `rare`, `elite`, `boss`, `npc`, `place`, `quest`, `lore` |
| `rarity` | One of the five quality tiers below |
| `name`, `flavor` | Localization keys (`L[...]`) |
| `displayID` or `icon` | Portrait via `SetPortraitTextureFromCreatureDisplayID`, or a texture path |
| `attack`, `defense` | Shown on the card; derived from `kind` and `rarity` by `Cards.stats` |

**Rarity** reuses WoW item quality names and colors (`ITEM_QUALITY_COLORS`), so players read it at a glance: Common, Uncommon, Rare, Epic, Legendary. Rarity reflects how notable the subject is in the zone: an ordinary creature is Common, a rare spawn Rare, a dungeon boss Epic, a lore figure Legendary. Drop odds per tier live in `Config.lua` (_tunable_: 60 / 25 / 10 / 4 / 1 %).

## 3. Opening

- Cards are revealed one by one, face down first; the frame border and a sound follow the rarity. A "reveal all" button skips the animation.
- New cards are flagged **New** until first seen in the binder.
- The roll and the write to SavedVariables happen before the animation starts, so a `/reload` mid-animation loses nothing.

## 4. Binder

- Navigation: continent → zone → cards. Each zone shows its completion (`owned / total`) and each continent sums its zones.
- Missing cards show as silhouettes with their rarity frame, so players see what is left to find.
- Filters: rarity, kind, owned / missing / duplicates, tag. Search by name.
- Tags: player-defined labels plus the built-in **For trade** tag. Players can pin favorites to the top.
- Duplicates are stored as counts (`collection[cardID] = n`); the binder shows `×n`.

## 5. Achievements

Local, stored per character, checked by pure functions over the save data so each one has a unit test. Starting set:

- Distance walked: 10, 100, 1 000 km.
- First card of each rarity.
- Zone completed (one per zone), continent completed.
- Packs opened: 10, 100, 1 000.
- V2: first trade completed.

## 6. Trading (V2)

Two players who both run the addon swap duplicates through whispered addon messages (`C_ChatInfo.RegisterAddonMessagePrefix` + `SendAddonMessage`, `WHISPER` channel).

Flow: A opens a trade window on B → both pick cards from their duplicates → each side locks its offer → both confirm → each client removes its own cards and adds the other's. A disconnect, a cancel or a timeout (_tunable_, 60 s) before both confirmations leaves both collections untouched.

Trades are honor-based: each player's collection is a local file they can edit, so the addon cannot prove a card is real. Say so in the trade window.

Every incoming message is untrusted input from another player. The parser:

- accepts only messages on the addon's prefix whose sender is the current trade partner;
- matches the whole payload against an anchored pattern (`^...$`), and rejects payloads over 255 bytes;
- accepts only card IDs that exist in `Data/` and counts from 1 to the per-trade limit (_tunable_, 10 cards);
- never echoes raw payload text into chat or a frame; it shows the localized card name looked up from the ID.

Each rejection rule gets a busted test: unknown card ID, a valid ID with a suffix or prefix glued on, an empty payload, an oversized payload, a count of 0 or a negative or huge count, a message from a third player, a confirm before both locks.

Addon messages may be throttled or blocked in combat and in instances on Forever (unverified, add it to `/wd probe`): offer trading only out of combat and out of instances.
