---@class Provider
---@field messages table?
local Provider = {}

---Base Provider class
---@param o table?
---@return Provider
function Provider:new(o)
  ---@type Provider
  o = o or {}
  o.messages = nil -- Initialize messages as instance variable
  setmetatable(o, self) -- Allows to inherit from Provider methods
  self.__index = self -- Ensures property that don't exist on an instance will be fetched from the Provider class
  return o
end

function Provider:reset_messages()
  self.messages = nil
end

---@enum (key) Role
local _role = {
  user = 1,
  assistant = 2,
}

---Builds messages for the LLM API
---@param role Role
---@param content string
---@param system_prompt string?
---@return table
function Provider:build_messages(role, content, system_prompt)
  local messages = self.messages

  Snacks.debug("MESSAGES", messages)

  if messages == nil then
    -- claude doesn't allow system promts in messages, but instead in the http request
    if system_prompt ~= nil then
      messages = {
        {
          role = "system",
          content = system_prompt,
        },
      }
    else
      messages = {}
    end
  end

  table.insert(messages, {
    role = role,
    content = content,
  })

  self.messages = messages

  return self.messages
end

function Provider:call(content, config, files_context)
  error("Provider must implement call method")
end

return { Provider = Provider }
