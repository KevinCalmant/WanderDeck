local _, ns = ...

-- Sounds for earning a pack (every STEPS_PER_PACK steps), opening one and
-- revealing cards. Played through the client's SOUNDKIT names: each event
-- lists candidate names, the first one the client has is played, and an event
-- with none is skipped silently (check with /wd sounds). Muted by /wd sound
-- (settings.sound).

local L = ns.L

local Sound = {}
ns.Sound = Sound

-- SOUNDKIT names, in order of preference (unverified on Forever).
Sound.KEYS = {
  -- Walking earned a pack: a loot pickup, else an item put in the bag.
  earn = { "LOOT_WINDOW_COIN_SOUND", "PUT_DOWN_SMALL_CHAIN" },
  open = { "IG_BACKPACK_OPEN" },
  flip = { "IG_ABILITY_PAGE_TURN" },
  -- A card owned for the first time: a loot pickup sound.
  new = { "UI_BONUS_LOOT_ROLL_END", "LOOT_WINDOW_COIN_SOUND" },
  epic = { "UI_EPICLOOT_TOAST" },
  legendary = { "UI_LEGENDARY_LOOT_TOAST" },
}

-- One sound per reveal, the most important wins: Legendary > Epic > new card > flip.
local PRIORITY = { flip = 1, new = 2, epic = 3, legendary = 4 }

---Sound event for revealing one card.
---@param rarity number 1-5
---@param isNew boolean|nil owned for the first time
---@return string event "flip", "new", "epic" or "legendary"
function Sound.eventFor(rarity, isNew)
  if rarity == 5 then return "legendary" end
  if rarity == 4 then return "epic" end
  if isNew then return "new" end
  return "flip"
end

---Kept for callers that only know the rarity.
function Sound.eventForRarity(rarity)
  return Sound.eventFor(rarity, false)
end

---The SOUNDKIT id of an event on this client, or nil.
---@return number|nil kit, string|nil name
function Sound.kitFor(event, env)
  local kit = type(env.SOUNDKIT) == "table" and env.SOUNDKIT or nil
  for _, name in ipairs(Sound.KEYS[event] or {}) do
    local id = kit and kit[name]
    if type(id) == "number" then return id, name end
  end
  return nil, nil
end

---Plays `event` unless muted or unknown on this client.
---@param event string a Sound.KEYS key
---@param env table|nil _G or a test stub
---@return boolean played
function Sound.play(event, env)
  env = env or _G
  local db = ns.GetDB and ns.GetDB()
  local settings = db and db.global and db.global.settings
  if settings and settings.sound == false then return false end
  local kit = Sound.kitFor(event, env)
  if not kit or type(env.PlaySound) ~= "function" then return false end
  return (pcall(env.PlaySound, kit, "SFX"))
end

---Plays one sound for several revealed cards (Reveal all): the most
---important event among them.
---@param reveals table[] { rarity = number, isNew = boolean }
function Sound.playReveal(reveals, env)
  local best
  for _, reveal in ipairs(reveals) do
    local event = Sound.eventFor(reveal.rarity, reveal.isNew)
    if not best or PRIORITY[event] > PRIORITY[best] then best = event end
  end
  if best then return Sound.play(best, env) end
  return false
end

---Kept for callers that only know rarities.
function Sound.playBest(rarities, env)
  local reveals = {}
  for i, rarity in ipairs(rarities) do reveals[i] = { rarity = rarity } end
  return Sound.playReveal(reveals, env)
end

ns.Slash.register({
  name = "sound",
  usage = "sound",
  help = L["Turn card sounds on or off"],
  handler = function()
    local db = ns.GetDB()
    if not db then return end
    local s = db.global.settings
    s.sound = not s.sound
    ns.print(s.sound and L["Sounds on."] or L["Sounds off."])
  end,
})
