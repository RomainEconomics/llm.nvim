local ui = require("llm.ui")
local model_picker = require("llm.pickers.models")

---@class Config
---@field model string Your config option
---@field system_promt string Your config option
---@field window_sizes table Your config option
---@field filetype string Your config option
local config = {
  model = "gpt-4o-mini",
  available_models = {
    "claude-3-5-haiku-20241022",
    "claude-3-5-sonnet-20241022",
    "gpt-4o",
    "gpt-4o-mini",
  },
  system_prompt = "You're a professional programmer. You should prefer short, concise and precise answers. You code mainly using Python and Lua. Prefer answering using markdowm formatting.",
  window_sizes = {
    output = 15, -- height of input window
    info = nil, -- height of info window
    input = -2, -- height of input window
  },
  filetype = "markdown",
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config?
-- you can define your setup function here. Usually configurations can be merged, accepting outside params and
-- you can also put some validation here for those.
M.setup = function(args)
  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.health = function()
  -- call: `:checkhealth llm`
  require("llm.health").check()
end

M.llm = function(args)
  M.setup(args)
  return ui.setup(M.config)
end

M.llm_with_picker = function(args)
  M.setup(args)
  model_picker.select_model(M.config, function(selected_model)
    if selected_model ~= nil then
      M.config.model = selected_model
    end
    return ui.setup(M.config)
  end)
end

return M
