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
  epic = { "UI_EPICLOOT_TOAST" },
  legendary = { "UI_LEGENDARY_LOOT_TOAST" },
}

---Sound event for revealing a card of `rarity` (1-5).
---@param rarity number
---@return string event "flip", "epic" or "legendary"
function Sound.eventForRarity(rarity)
  if rarity == 5 then return "legendary" end
  if rarity == 4 then return "epic" end
  return "flip"
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

---Plays one sound for several revealed cards (Reveal all): the one for the
---best rarity among them.
---@param rarities number[]
---@param env table|nil _G or a test stub
---@return boolean played
function Sound.playBest(rarities, env)
  local best = 0
  for _, rarity in ipairs(rarities) do
    if type(rarity) == "number" and rarity > best then best = rarity end
  end
  if best > 0 then return Sound.play(Sound.eventForRarity(best), env) end
  return false
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
