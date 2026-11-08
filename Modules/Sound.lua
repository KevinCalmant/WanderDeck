local _, ns = ...

-- Sounds for opening a pack and revealing cards, by rarity. Played through
-- the client's SOUNDKIT names: a name the client does not have is skipped
-- silently (check with /wd sounds). Muted by /wd sound (settings.sound).

local L = ns.L

local Sound = {}
ns.Sound = Sound

-- SOUNDKIT names (unverified on Forever).
Sound.KEYS = {
  open = "IG_BACKPACK_OPEN",
  flip = "IG_ABILITY_PAGE_TURN",
  epic = "UI_EPICLOOT_TOAST",
  legendary = "UI_LEGENDARY_LOOT_TOAST",
}

---Sound event for revealing a card of `rarity` (1-5).
---@return string event "flip", "epic" or "legendary"
function Sound.eventForRarity(rarity)
  if rarity == 5 then return "legendary" end
  if rarity == 4 then return "epic" end
  return "flip"
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
  local key = Sound.KEYS[event]
  local kit = type(env.SOUNDKIT) == "table" and key and env.SOUNDKIT[key]
  if type(kit) ~= "number" or type(env.PlaySound) ~= "function" then return false end
  return (pcall(env.PlaySound, kit, "SFX"))
end

---Plays the sound for the best rarity among `rarities` (Reveal all).
function Sound.playBest(rarities, env)
  local best = 0
  for _, rarity in ipairs(rarities) do
    if rarity > best then best = rarity end
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
