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

-- ---@type Config
-- M.config = default_config

---@param opts Config?
M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", default_config, opts or {})
end

M.health = function()
  -- call: `:checkhealth llm`
  require("llm.health").check()
end

-- Format visual selected text
---@param selected_text string?
---@param filetype string?
---@return boolean
local function format_visual_selection(selected_text, filetype)
  if not selected_text then
    return false
  end
  local windows = require("llm.ui.windows").windows

  -- Format the selected text with filetype
  local formatted_text = string.format("\n```%s\n%s\n```\n", filetype, selected_text)

  -- Add the formatted text to the input buffer
  if windows and windows.input and vim.api.nvim_buf_is_valid(windows.input.buf) then
    vim.api.nvim_buf_set_lines(windows.input.buf, 0, -1, false, vim.split(formatted_text, "\n"))
    vim.cmd("normal! G") -- Move cursor to the bottom
  end
  return true
end

--- Create a unified start_chat function
---@param config Config
---@param visual_selection VisualSelection?
local function start_chat(config, visual_selection)
  chat.load_provider(config.model)
  local filetype = vim.bo.filetype -- take the filetype here before any buffer modifies it

  local cache_info = cache.load_cache(config)
  if cache_info ~= nil then
    local metadata = history.parse_chat_filename(cache_info.history_path)
    if cache_info.model == config.model then
      M._resume_chat(metadata.date, metadata.chat_uid, config)
    else
      Snacks.notify.warn("LLM provided is different from the last chat. Creating a new one...")
      ui.setup(config)
    end
  end

  if visual_selection then
    if format_visual_selection(visual_selection.text, filetype) then
      -- Add buffer/filepath to the context
      local windows = require("llm.ui.windows").windows
      if windows and windows.info and vim.api.nvim_buf_is_valid(windows.info.buf) then
        local info_lines = vim.api.nvim_buf_get_lines(windows.info.buf, 0, -1, false)

        local files_in_context = { visual_selection.file_path }
        for _, v in ipairs(info_lines) do
          if v ~= "" or v ~= visual_selection.file_path then
            table.insert(files_in_context, v)
          end
        end
        vim.api.nvim_buf_set_lines(windows.info.buf, 0, -1, false, files_in_context)
      end
    else
      Snacks.notify.error("No text selected")
    end
  end
end

M.llm = function(opts)
  M.setup(opts)
  -- We extract selected text, if any, before starting the chat, otherwise vim.fn.mode may become "n" or "i"
  local visual_selection = require("llm.utils.selection").get_visual_selection()
  return start_chat(M.config, visual_selection)
end

M.llm_with_picker = function(opts)
  M.setup(opts)
  local visual_selection = require("llm.utils.selection").get_visual_selection()

  model_picker.select_model(M.config, function(selected_model)
    if selected_model ~= nil then
      M.config.model = selected_model
    end
    return start_chat(M.config, visual_selection)
  end)
end

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
