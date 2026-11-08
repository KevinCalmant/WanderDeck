local _, ns = ...

local type, floor, huge = type, math.floor, math.huge

-- Largest value the client's int32 API arguments accept.
local INT32_MAX = 2147483647

---A finite number >= 0 (rejects NaN and infinities).
local function isFiniteNonNegative(n)
  return type(n) == "number" and n == n and n >= 0 and n ~= huge
end

---A plausible uiMapID: a positive int32 integer (rejects NaN, fractions,
---infinities and values the client API would refuse).
local function isMapID(n)
  return type(n) == "number" and n == n and n > 0 and n <= INT32_MAX and n == floor(n)
end

ns.Utils = {
  INT32_MAX = INT32_MAX,
  isFiniteNonNegative = isFiniteNonNegative,
  isMapID = isMapID,
}
