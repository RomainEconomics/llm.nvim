local uuid = require("llm.utils.uuid")

local M = {}

---Initialize a new chat session
---@param buf number
---@param config Config
function M.initialize_session(buf, config)
  local chat = require("llm.chat")
  local history = require("llm.history")
  local projects = require("llm.projects")

  -- Set default project if none is specified
  if not config.project_name then
    config.project_name = "Default"
    -- Create Default project if it doesn't exist
    if not projects.project_exists(config, "Default") then
      projects.create_project(config, "Default", config.system_prompt, config.model)
    end
  end

  -- Get project directory for chat history
  local project_dir = projects.get_project_directory(config, config.project_name)
  -- Store the original chat_history_dir
  local original_chat_history_dir = config.chat_history_dir
  -- Temporarily set chat_history_dir to project directory for this session
  config.chat_history_dir = project_dir

  -- Initialize chat history
  history.initialize_history(buf, config)

  -- Restore original chat_history_dir
  config.chat_history_dir = original_chat_history_dir

  -- Generate new UUID if not provided
  if not config.chat_uid then
    config.chat_uid = uuid.generate_uuid()
  end

  if not config.chat_date then
    config.chat_date = os.date("%Y-%m-%d %H:%M:%S")
  end

  local header = {
    "# Chat Session",
    "",
    "- Date: " .. config.chat_date,
    "- Model: " .. config.model,
    "- Chat ID: " .. config.chat_uid,
    "- Project: " .. config.project_name,
    "",
    "---",
    "",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)
end

return M
