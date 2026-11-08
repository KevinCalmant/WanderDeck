local _, ns = ...

-- Pure state of a pack reveal: which cards are still face down. The cards are
-- already saved (Collection.openNext) before a reveal starts.

local type, floor = type, math.floor

local Reveal = {}
ns.Reveal = Reveal

---@param cardIDs string[]
---@param firstTime table<string, boolean>
---@return table state { cardIDs, firstTime, revealed = { [index] = true } }
function Reveal.new(cardIDs, firstTime)
  return { cardIDs = cardIDs, firstTime = firstTime or {}, revealed = {}, count = 0 }
end

---Turns card `index` face up.
---@return boolean changed false when the index is invalid or already revealed
function Reveal.flip(state, index)
  if type(index) ~= "number" or index ~= floor(index) or index < 1 or index > #state.cardIDs then return false end
  if state.revealed[index] then return false end
  state.revealed[index] = true
  state.count = state.count + 1
  return true
end

---Turns every card face up.
function Reveal.flipAll(state)
  for i = 1, #state.cardIDs do Reveal.flip(state, i) end
end

---@return boolean
function Reveal.isDone(state)
  return state.count >= #state.cardIDs
end
