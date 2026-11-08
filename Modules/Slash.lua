local _, ns = ...

local L = ns.L
local type, ipairs, assert = type, ipairs, assert

local SLASH = "/wd"
local NAME_PATTERN = "^[a-z][a-z0-9]*$"

-- Registered commands, by name for dispatch and in order for the help.
local byName, ordered = {}, {}

---@class SlashCommand
---@field name string lowercase word typed after /wd
---@field usage string shown in the help, e.g. "probe [label]"
---@field help string one-line description
---@field handler fun(rest: string)

---Registers a /wd sub-command. Modules and Developer files call this at load.
---@param command SlashCommand
local function register(command)
  assert(type(command) == "table", "command must be a table")
  assert(type(command.name) == "string" and command.name:match(NAME_PATTERN), "invalid command name")
  assert(type(command.handler) == "function", "command handler required")
  assert(not byName[command.name], "duplicate command: "..command.name)
  byName[command.name] = command
  ordered[#ordered + 1] = command
end

---Splits the slash input into a lowercase command word and the trimmed rest.
---@param msg any
---@return string name
---@return string rest
local function parse(msg)
  if type(msg) ~= "string" then return "", "" end
  local name, rest = msg:match("^%s*(%S*)%s*(.-)%s*$")
  return (name or ""):lower(), rest or ""
end

local function printHelp()
  ns.print(L["Commands:"])
  for _, command in ipairs(ordered) do
    print("  "..SLASH.." "..(command.usage or command.name).." - "..(command.help or ""))
  end
end

---Runs the command named by the first word of `msg`. Unknown or empty input
---prints the help; the raw input is never echoed back to chat.
---@param msg string text after the slash command
---@return boolean handled
local function dispatch(msg)
  local name, rest = parse(msg)
  local command = byName[name]
  if not command then
    printHelp()
    return false
  end
  command.handler(rest)
  return true
end

register({
  name = "help",
  usage = "help",
  help = L["Show this help"],
  handler = printHelp,
})

ns.Slash = {
  register = register,
  parse = parse,
  dispatch = dispatch,
}
