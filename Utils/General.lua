local _, ns = ...

local type, ipairs, floor, huge = type, ipairs, math.floor, math.huge

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

-- Invisible or direction-changing characters (UTF-8 bytes): C1 controls,
-- no-break space, zero-width and bidi marks (U+2000-200F, U+2028-202F),
-- word joiners (U+2060-206F) and the BOM.
local INVISIBLE_PATTERNS = {
  "\194[\128-\160]",          -- C1 controls, U+00A0
  "\194\173",                 -- U+00AD soft hyphen
  "\225\160\142",             -- U+180E
  "\226\128[\128-\143]",      -- U+2000-200F
  "\226\128[\168-\175]",      -- U+2028-202F
  "\226\129[\160-\175]",      -- U+2060-206F
  "\227\133\164",             -- U+3164 Hangul filler
  "\239\184[\128-\143]",      -- U+FE00-FE0F variation selectors
  "\239\187\191",             -- U+FEFF BOM
  "\243\160[\128-\129]",      -- U+E0000-E007F tag characters
}
-- Well-formed lead bytes whose second byte would make an overlong, a
-- surrogate or a code point above U+10FFFF.
local INVALID_PATTERNS = {
  "\224[\128-\159]",
  "\237[\160-\191]",
  "\240[\128-\143]",
  "\244[\144-\191]",
}

---True for well-formed UTF-8 without control, invisible or bidi characters.
---Malformed UTF-8 is refused because a renderer that decodes by lead-byte
---length could swallow a following "|" and revive an escape code.
---@param text string
---@return boolean
local function isCleanText(text)
  if type(text) ~= "string" or text:find("%c") then return false end
  for _, pattern in ipairs(INVISIBLE_PATTERNS) do
    if text:find(pattern) then return false end
  end
  for _, pattern in ipairs(INVALID_PATTERNS) do
    if text:find(pattern) then return false end
  end
  -- Each valid sequence becomes an ASCII placeholder, never "", so removing
  -- one can never join its neighbours into a new sequence.
  local rest = text
    :gsub("[\240-\244][\128-\191][\128-\191][\128-\191]", "x")
    :gsub("[\224-\239][\128-\191][\128-\191]", "x")
    :gsub("[\194-\223][\128-\191]", "x")
  return not rest:find("[\128-\255]")
end

ns.Utils = {
  isCleanText = isCleanText,
  INT32_MAX = INT32_MAX,
  isFiniteNonNegative = isFiniteNonNegative,
  isMapID = isMapID,
}
