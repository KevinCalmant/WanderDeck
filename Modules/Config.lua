local _, ns = ...

-- Every tunable in one place. Values marked "guess" are starting points to
-- balance in play.
ns.Config = {
  -- Seconds between two position samples.
  SAMPLE_INTERVAL = 0.5,
  -- Yards walked per counted step (guess).
  YARDS_PER_STEP = 1,
  -- Steps needed to earn one pack (guess).
  STEPS_PER_PACK = 2000,
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
}
