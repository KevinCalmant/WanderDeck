local _, ns = ...

---@class DebugChannel
---@field print fun(msg: any)
---@field setEnabled fun(enabled: boolean)
---@field isEnabled fun(): boolean

---Creates a tagged debug printer that prints only while enabled.
---@param name string channel tag shown in the chat prefix
---@param enabled boolean initial state
---@return DebugChannel
local function make(name, enabled)
  local channel = { enabled = enabled and true or false }

  function channel.print(msg)
    if channel.enabled then
      print("|cff33ccffWanderDeck-"..name.."|r: "..tostring(msg))
    end
  end

  function channel.setEnabled(value)
    channel.enabled = value and true or false
  end

  function channel.isEnabled()
    return channel.enabled
  end

  return channel
end

ns.Debug = {
  make = make,
}
