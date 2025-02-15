local providers = require("llm.providers")

---@module "snacks"

local M = {}
local current_provider = nil

---Call LLM api provider
---@param content string
---@param config Config
---@param files_context string?
function M.call_llm(content, config, files_context)
  Snacks.notifier.notify("Model used: " .. config.model, "info", { title = "Model used" })

  if not current_provider then
    current_provider = providers.get_provider(config.model)
  end
  return current_provider:call(content, config, files_context)
end

M.reset_provider = function()
  current_provider = nil
end

return M
