local providers = require("llm.providers")

---@module "snacks"

local M = {}
local current_provider = nil

---Load LLM provider
---@param model string
---@param messages table?
---@return Provider
function M.load_provider(model, messages)
  current_provider = providers.get_provider(model)
  if messages then
    current_provider.messages = messages
  end
  return current_provider
end

---Call LLM api provider
---@param content string
---@param config Config
---@param files_context string?
---@return table
function M.call_llm(content, config, files_context)
  Snacks.notifier.notify("Model used: " .. config.model, "info", { title = "Model used" })

  if not current_provider then
    current_provider = M.load_provider(config.model)
  end

  -- Create a new promise
  local promise = {}
  promise.done = false
  promise.messages = nil

  current_provider:call(content, config, function()
    promise.done = true
    promise.messages = current_provider.messages
  end, files_context)

  return promise
end

M.reset_provider = function()
  current_provider = nil
end

return M
