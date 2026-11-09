local _, ns = ...

-- Every tunable in one place. Values marked "guess" are starting points to
-- balance in play.
ns.Config = {
  -- Seconds between two position samples.
  SAMPLE_INTERVAL = 0.5,
  -- Yards walked per counted step (guess).
  YARDS_PER_STEP = 1,
  -- Steps needed to earn one pack (guess; lowered from 2000 when zones grew
  -- to about 120 cards).
  STEPS_PER_PACK = 1500,
  -- Fastest plausible on-foot speed, yards per second. Base run speed is about
  -- 7; sprint-type buffs can push it higher. A faster delta is a teleport,
  -- portal or loading screen and is discarded (guess, refine with /wd watch).
  MAX_FOOT_SPEED = 14,
  -- Longest gap between two samples that still counts, in seconds. A longer
  -- gap (loading screen, client stall) would let MAX_FOOT_SPEED * gap accept a
  -- same-zone teleport, so the delta is discarded.
  MAX_SAMPLE_GAP = 2,
  -- Consecutive failing ticks before the step tracker stops itself.
  MAX_TICK_FAILURES = 10,
  -- Unopened packs a character can hold; past it, walking earns no pack.
  MAX_UNOPENED_PACKS = 20,
  -- Cards in one pack.
  CARDS_PER_PACK = 5,
  -- Relative drop weight per rarity (1 Common .. 5 Legendary), per card.
  -- With 5 cards a pack: about 1 pack in 10 holds an Epic, 1 in 40 a
  -- Legendary (user decision, 2026-11-09).
  RARITY_WEIGHTS = { 124, 50, 20, 4, 1 },
  -- Every pack holds at least one card of this rarity or better (2 = Uncommon).
  GUARANTEED_RARITY = 2,
  -- Percent chance that a draw picks among the cards of its rarity the player
  -- does not own yet (guess).
  NEW_CARD_BIAS = 50,
  -- Copies of one card a collection can hold.
  MAX_COPIES = 999,
  -- Creature cards with an npcID show the creature's 3D model in their art
  -- panel; the icon stays as the fallback while the model loads or when it
  -- never does (prototype, unverified on Forever: check with /wd model).
  CARD_MODELS = true,
  -- Model framing: 0 shows the whole body, 1 a head-and-shoulders portrait.
  CARD_MODEL_ZOOM = 0.6,
}
