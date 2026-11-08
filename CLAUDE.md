# WanderDeck (working name)

A World of Warcraft addon: a card-collection game driven by walking. Every `STEPS_PER_PACK` steps the player earns a booster pack bound to the zone it was earned in. Opening a pack rolls cards from that zone's card pool into the player's collection.

Read `docs/FEATURES.md` before building or changing anything the player sees: it holds the scope (solo V1, trading V2), card model, rarity, binder, achievements and trade protocol.

Structure, tooling and conventions follow the author's previous addon, MythicDungeonTools_NextPullTracker (https://github.com/KevinCalmant/MythicDungeonTools_NextPullTracker). When a pattern below is unclear, read how that repo does it.

## Target: World of Warcraft: Forever

- Forever (internal name Camelot) is Blizzard's Classic+ game, launched 2026-11-04: vanilla continents, level cap 60, no flying mounts. It runs on the **modern Mainline client**, so it uses the same API family as Retail Midnight, not the Classic Era API.
- TOC: `## Interface: 16001`, confirmed on the live client by `/wd probe`. The file may carry the suffix `_Forever.toc` (alias of `_Camelot.toc`). Re-check with `/dump select(4, GetBuildInfo())` after each game patch.
- Install folder (community guides, unverified): `World of Warcraft/_forever_/Interface/AddOns/<Addon>`.
- Midnight **secret values** are active: comparing, doing math on, indexing or using as a table key a secret value throws. Guard any unit-derived value with `type(issecretvalue) == "function" and issecretvalue(v)`. The combat log (`COMBAT_LOG_EVENT_UNFILTERED`) is unavailable.
- Globals reported removed on beta builds, with replacements: `GetSpellInfo` → `C_Spell.GetSpellInfo`, `GetItemInfo` → `C_Item.GetItemInfo`, `GetAddOnMetadata` → `C_AddOns.GetAddOnMetadata`, talent APIs → `C_Traits`.
- Sources on Forever's addon API are pre-launch fan guides (wowforeverguides.com). Treat any API not listed in the probe results (see Domain rules) as unconfirmed.
- Libraries are fetched by the packager (`.pkgmeta` externals) into `Libs/`: LibStub, CallbackHandler-1.0, AceDB-3.0. Add another Ace lib only when a module needs it.

## Layout

```
<Addon>.toc            load order; SavedVariables; @project-version@
init.lua               namespace: `local addonName, ns = ...`, exposes `_G[<Global>] = ns`, shared enums
locales.xml, Locales/  enUS.lua is the unguarded source of truth; other locales start with `if GetLocale() ~= "xxXX" then return end`
Utils/load_utils.xml   Debug.lua (tagged debug printers), Wow.lua (the only file that calls WoW APIs directly)
Data/                  static card and pack definitions, keyed by zone uiMapID
Modules/load_modules.xml
Modules/*.lua          one concern per file
Core.lua               loaded last: AceDB init on ADDON_LOADED, event frame, timers, fan-out to modules
Developer/             in-game test runner (`/wd test`), excluded from releases
spec/                  busted unit tests; spec/helpers/wow_mocks.lua stubs the WoW runtime
```

Files load in the order of the TOC and `load_*.xml`; a module may only capture (as a top-of-file `local`) modules loaded before it. Each module ends with `ns.ModuleName = { publicFn = publicFn, ... }`.

## Architecture

Split every feature into a **pure core** and a **thin shell**:

- Pure core (step math, pack thresholds, card rolls, collection updates, save-data sanitizing): plain functions over plain tables, no WoW globals, no frames. Randomness is injected (`roll(pool, rng)`) so tests are deterministic. This is what `spec/` covers.
- Shell (events, `C_Timer`, frames, chat output): calls the core and `Utils/Wow.lua`. Keep it small enough that the in-game Developer tests cover it.

Expected modules: `Config` (all tunables), `StepTracker` (position samples → steps), `Zone` (uiMapID → zone), `Packs` (thresholds, earning, inventory), `Cards` (pool lookup, rarity roll, stats), `Collection`, `Achievements`, `Trade` (V2: protocol parser and state machine, pure), `UI/*` (pack opening, binder, trade window), `Slash`, `Settings` (Blizzard `Settings.RegisterProxySetting` + `CreateCheckbox`, as in the reference repo).

## Domain rules

- **Probe results** (`/wd probe`, build 1.60.1.70862, Interface 16001 live, `WOW_PROJECT_ID` 18; outdoors in Westfall, on foot, in combat). The probe only ran in this one situation; re-run it before relying on any other.
  - Plain (not secret): `UnitPosition` (y, x in yards, instanceID 0 on Eastern Kingdoms), `C_Map.GetBestMapForUnit` (1436), `C_Map.GetMapInfo` chain (1436 Zone → 1415 Continent → 947 World), `C_Map.GetPlayerMapPosition`, `C_Map.GetWorldPosFromMapPos`, `UnitOnTaxi`, `IsMounted`, `IsFlying`, `UnitInVehicle`, `UnitIsDeadOrGhost`, `IsIndoors`, `IsInInstance`. Still plain while `InCombatLockdown()` is true.
  - **Secret: `GetUnitSpeed`**. Never use it; derive speed from position deltas.
  - Untested: the `true` case of the movement checks, and walking distance per second (`/wd watch` not run yet).
- **Steps** are derived from distance: sample `UnitPosition("player")` on a `C_Timer.NewTicker` (about 0.5 s), convert the moved distance in yards to steps with one constant (`YARDS_PER_STEP`). WoW has no step API.
- **Only walking outdoors counts** (user decision). Discard the delta when the player is mounted, on a taxi, in a vehicle, dead or a ghost, inside an instance (`IsInInstance()`), when the position is unavailable or secret, when `UnitPosition`'s instanceID or the zone changed between samples, or when the delta exceeds `MAX_FOOT_SPEED` (yards per second, tunable) over the interval (teleport, portal, hearthstone, loading screen).
- **Zone** means the zone-level map: take `C_Map.GetBestMapForUnit("player")` and walk `C_Map.GetMapInfo(id).parentMapID` up to the first map whose `mapType` is `Enum.UIMapType.Zone`. Subzones, micro-dungeons and floors roll up to their zone. Store the uiMapID, never the localized name.
- **Cities and dungeons are not card zones** (user decision): a city folds into the outdoor zone around it (`Data/ZoneGroups.lua`, `Cards.cardZone`), and a dungeon's cards go in the set of the zone holding its entrance. Details in `docs/FEATURES.md`, "Zone grouping".
- **Zone binding** (user decision): one global counter per character. Each counted delta is also added to that zone's share of the current pack (`char.progress.byZone`). When the counter reaches `STEPS_PER_PACK`, the pack goes to the zone with the most steps in that share (tie: the current zone, else the lowest uiMapID); the share is then cleared and the overflow is credited to the current zone.
- A **pack** is persisted as `{ zoneMapID, earnedAt }`; its cards are rolled when it is opened, and the result is written to SavedVariables in the same call.
- A zone with no pool in `Data/` falls back to the pool of its continent, then to a generic pool, so walking never earns an empty pack.

Each rule above has a busted test; add one per discard reason and per fallback level.

## Saved variables

- AceDB with `global` (settings) and `char` (step counters, unopened packs, collection). Bump `schemaVersion` and add a migration function for every layout change; a layout break is a major version.
- SavedVariables are a user-editable file: run every loaded value through a schema sanitizer (type, range, known IDs) before use, as `BeaconState.lua` does in the reference repo, and drop card IDs that `Data/` no longer defines.
- Unknown card IDs are deleted only when every zone in `Data/Loaded.lua`'s `EXPECTED_ZONES` registered (`Cards.dataLoaded`): the client keeps loading after a file errors, and a failed Data file must not wipe that zone from collections. Add each new zone to that list. Renaming a shipped card ID (including a uiMapID fix) needs a migration step that rewrites saved IDs, or players lose those cards.

## Commands

- `busted` runs the unit tests (config in `.busted`, helpers on `spec/helpers/?.lua`). Without a system Lua, install one locally: `pip install hererocks && hererocks .lua51 -l5.1 -rlatest && .lua51/bin/luarocks install busted`.
- `scripts/fetch-libs.sh` copies LibStub, CallbackHandler and AceDB from the Ace3 GitHub mirror into the git-ignored `Libs/`; run it once before loading the addon in game.
- `/wd probe [label]` and `/wd watch [label]` (Developer only) report the position, map and movement APIs and save each run in `WanderDeckDB.global.probes`.
- Develop by symlinking the repo into the Forever `Interface/AddOns/<Addon>` folder and running `/reload` in game.
- Release: push a `v*` tag; `.github/workflows/release.yml` runs `BigWigsMods/packager@v2` (CurseForge/Wago secrets).

## Conventions

- 2-space indent, LF, UTF-8 (`.editorconfig`). Annotate public functions with LuaLS `---@param` / `---@return`.
- Every WoW global the code reads goes in `.luarc.json` `diagnostics.globals`.
- User-facing strings go through `L["English text"]`, with the key added to `Locales/enUS.lua` first.
- Chat output uses one colored prefix constant per addon; debug output goes through `Debug.make(name, enabled)` channels, off by default.
- Wrap APIs that differ between game versions in `Utils/Wow.lua` with a modern-first, legacy-fallback check (`if C_X and C_X.Fn then`), as the reference repo does for scenario and specialization APIs.
- Conventional Commits; `CHANGELOG.md` follows Keep a Changelog; SemVer.

## Open decisions (ask the user before implementing)

- V1 zones are Elwynn Forest and Westfall (user decision). Card lists in `Data/` are drafted by Claude: the user reviews names, rarities and French names before release. Elwynn's uiMapID 1429 is still unverified on Forever.
