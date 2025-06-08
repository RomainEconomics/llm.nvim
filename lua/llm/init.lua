local ui = require("llm.ui")
local chat = require("llm.chat")
local model_picker = require("llm.pickers.models")
local history_picker = require("llm.pickers.history")
local history = require("llm.history")
local cache = require("llm.cache")
local selection = require("llm.utils.selection")
local projects_picker = require("llm.pickers.projects")

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
---@field project_name string? Current project name

---@class MyModule
local M = {}

local default_config = require("llm.config_defaults")

--
-- Commands
--

---@param opts Config?
M.setup = function(opts)
  M.config = vim.tbl_deep_extend("force", default_config, opts or {})
end

M.health = function()
  -- call: `:checkhealth llm`
  require("llm.health").check()
end

M.llm = function(opts)
  M.setup(opts)
  -- We extract selected text, if any, before starting the chat, otherwise vim.fn.mode may become "n" or "i"
  local visual_selection = require("llm.utils.selection").get_visual_selection()
  return M._start_chat(M.config, visual_selection)
end

M.llm_with_picker = function(opts)
  M.setup(opts)
  local visual_selection = require("llm.utils.selection").get_visual_selection()

  model_picker.select_model(M.config, function(selected_model)
    if selected_model ~= nil then
      M.config.model = selected_model
    end
    return M._start_chat(M.config, visual_selection)
  end)
end

M.llm_with_history = function(opts)
  M.setup(opts)
  local projects = require("llm.projects")

  projects_picker.pick_projects(M.config, function(selected_project)
    if selected_project then
      -- Ensure project exists and is properly initialized
      if not projects.project_exists(M.config, selected_project) then
        Snacks.notify.error("Project does not exist: " .. selected_project)
        return
      end

      -- Get project configuration
      local project_config = projects.get_project(M.config, selected_project)
      if not project_config then
        Snacks.notify.error("Failed to load project configuration: " .. selected_project)
        return
      end

      -- Update config with project settings
      M.config.project_name = selected_project
      M.config.system_prompt = project_config.system_prompt
      if project_config.default_model then
        M.config.model = project_config.default_model
      end

      -- Now pick history file
      history_picker.pick_history(M.config, function(selected_file_history)
        if selected_file_history ~= nil then
          local metadata = history.parse_chat_filename(selected_file_history)
          M._resume_chat(metadata.date, metadata.chat_uid, M.config)
        end
      end)
    end
  end)
end

M.llm_with_project = function(opts)
  M.setup(opts)
  local visual_selection = require("llm.utils.selection").get_visual_selection()

  projects_picker.pick_projects(M.config, function(selected_project)
    if selected_project then
      M.config.project_name = selected_project
      M._start_chat(M.config, visual_selection)
    end
  end)
end

---
--- Helpers
---

M._resume_chat = function(date, chat_uid, opts)
  M.setup(opts)
  M.config.chat_uid = chat_uid
  -- TODO: add also files in context as a list, and put them back to context
  local chat_data = require("llm.history").load_chat(M.config, date, chat_uid)
  if chat_data then
    M.config.model = chat_data.model
    M.config.system_prompt = chat_data.system_prompt
    M.config.chat_date = chat_data.chat_date

    if chat_data.project_name and not M.config.project_name then
      M.config.project_name = chat_data.project_name
    end
    -- Load provider with existing messages
    chat.load_provider(chat_data.model, chat_data.conversations)
    return ui.setup(M.config, chat_data.conversations)
  end
  return ui.setup(M.config)
end

--- Handle resuming or creating a new chat based on cache
---@param config Config
function M._handle_chat_initialization(config)
  local cache_info = cache.load_cache(config)
  if not cache_info then
    ui.setup(config)
    return
  end

  local metadata = history.parse_chat_filename(cache_info.history_path)
  if cache_info.model == config.model then
    M._resume_chat(metadata.date, metadata.chat_uid, config)
  else
    Snacks.notify.warn("LLM provided is different from the last chat. Creating a new one...")
    ui.setup(config)
  end
end

--- Create a unified start_chat function
---@param config Config
---@param visual_selection VisualSelection?
function M._start_chat(config, visual_selection)
  chat.load_provider(config.model)
  local filetype = vim.bo.filetype

  if visual_selection then
    ui.setup(config)
    selection.handle_visual_selection(visual_selection, filetype)
  else
    M._handle_chat_initialization(config)
  end
end

return M
