local ui = require("llm.ui")
local chat = require("llm.chat")
local model_picker = require("llm.pickers.models")
local history_picker = require("llm.pickers.history")
local history = require("llm.history")
local cache = require("llm.cache")

---@class Config
---@field model string Default model to use
---@field system_prompt string Your default system prompt
---@field window_sizes table Windows sizes
---@field keys table Different keymaps used
---@field available_models table Supported models
---@field filetype string Default filetype for the output buffer
---@field cache_dir string Location for the cache directory
---@field chat_history_dir string Location for the chat history
---@field chat_uid string? Chat history uuid
---@field chat_date string? Chat date

---@class MyModule
local M = {}

local default_config = require("llm.config_defaults")

---@type Config
M.config = default_config

---@param opts Config?
M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

M.health = function()
  -- call: `:checkhealth llm`
  require("llm.health").check()
end

-- M.llm = function(opts)
--   M.setup(opts)
--   chat.load_provider(M.config.model)
--
--   local cache_info = cache.load_cache(M.config)
--   if cache_info ~= nil then
--     local metadata = history.parse_chat_filename(cache_info.history_path)
--     if cache_info.model == M.config.model then
--       return M._resume_chat(metadata.date, metadata.chat_uid, opts)
--     else
--       Snacks.notify.warn("LLM provided is different from the last chat. Creating a new one...")
--     end
--   end
--   return ui.setup(M.config)
-- end

-- Create a helper function to handle the visual selection
local function handle_visual_selection(windows)
  local selected_text = require("llm.utils.selection").get_visual_selection()
  if not selected_text then
    return false
  end

  -- Format the selected text with filetype
  local formatted_text = string.format("\n```%s\n%s\n```\n", vim.bo.filetype, selected_text)

  -- Add the formatted text to the input buffer
  if windows and windows.input and vim.api.nvim_buf_is_valid(windows.input.buf) then
    vim.api.nvim_buf_set_lines(windows.input.buf, 0, -1, false, vim.split(formatted_text, "\n"))
    vim.cmd("normal! G") -- Move cursor to the bottom
  end
  return true
end

-- Create a unified start_chat function
local function start_chat(config, with_selection)
  chat.load_provider(config.model)

  local cache_info = cache.load_cache(config)
  if cache_info ~= nil then
    local metadata = history.parse_chat_filename(cache_info.history_path)
    if cache_info.model == config.model then
      return M._resume_chat(metadata.date, metadata.chat_uid, config)
    else
      Snacks.notify.warn("LLM provided is different from the last chat. Creating a new one...")
    end
  end

  local windows = ui.setup(config)

  if with_selection then
    if not handle_visual_selection(windows) then
      Snacks.notify.error("No text selected")
    end
  end

  return windows
end

M.llm = function(opts)
  M.setup(opts)
  return start_chat(M.config, vim.fn.mode() == "v" or vim.fn.mode() == "V")
end

M.llm_with_picker = function(opts)
  M.setup(opts)
  model_picker.select_model(M.config, function(selected_model)
    if selected_model ~= nil then
      M.config.model = selected_model
    end
    return start_chat(M.config, vim.fn.mode() == "v" or vim.fn.mode() == "V")
  end)
end

-- M.llm_with_visual_selection = function(opts)
--   -- When starting a chat using visual selection, we don't use cache for now.
--   M.setup(opts)
--   chat.load_provider(M.config.model)
--
--   -- Get visual selection and current buffer filetype
--   local selected_text = require("llm.utils.selection").get_visual_selection()
--   if not selected_text then
--     Snacks.notify.error("No text selected")
--     return ui.setup(M.config)
--   end
--
--   -- Setup the chat UI
--   ui.setup(M.config)
--   local windows = require("llm.ui.windows").windows
--
--   -- Format the selected text with filetype
--   local formatted_text = string.format("\n```%s\n%s\n```\n", vim.bo.filetype, selected_text)
--
--   -- Add the formatted text to the input buffer
--   if windows and windows.input and vim.api.nvim_buf_is_valid(windows.input.buf) then
--     vim.api.nvim_buf_set_lines(windows.input.buf, 0, -1, false, vim.split(formatted_text, "\n"))
--   end
--
--   -- Move cursor to the bottom of the input buffer
--   vim.cmd("normal! G")
-- end

-- M.llm_with_picker = function(opts)
--   M.setup(opts)
--   model_picker.select_model(M.config, function(selected_model)
--     if selected_model ~= nil then
--       M.config.model = selected_model
--       chat.load_provider(selected_model)
--     end
--     return ui.setup(M.config)
--   end)
-- end

M.llm_with_history = function(opts)
  M.setup(opts)
  history_picker.pick_history(M.config, function(selected_file_history)
    if selected_file_history ~= nil then
      local metadata = history.parse_chat_filename(selected_file_history)
      M._resume_chat(metadata.date, metadata.chat_uid, opts)
    end
  end)
end

M._resume_chat = function(date, chat_uid, opts)
  M.setup(opts)
  M.config.chat_uid = chat_uid
  -- TODO: add also files in context as a list, and put them back to context
  local chat_data = require("llm.history").load_chat(M.config, date, chat_uid)
  if chat_data then
    M.config.model = chat_data.model
    M.config.system_prompt = chat_data.system_prompt
    M.config.chat_date = chat_data.chat_date
    -- Load provider with existing messages
    chat.load_provider(chat_data.model, chat_data.conversations)
    return ui.setup(M.config, chat_data.conversations)
  end
  return ui.setup(M.config)
end

return M
