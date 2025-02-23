local M = {}

function M.parse_chat_filename(filename)
  local date, chat_uid = filename:match("(%d%d%d%d%-%d%d%-%d%d)/chat_([%w%-]+)%.json")

  if not date or not chat_uid then
    error("Invalid filename format")
  end

  return {
    date = date,
    chat_uid = chat_uid,
  }
end

local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    local success, err = pcall(function()
      vim.fn.mkdir(path, "p")
    end)
    if not success then
      vim.notify("Failed to create directory: " .. err, vim.log.levels.ERROR)
      return false
    end
  end
  return true
end

---Saves the chat history to a JSON file.
---@param config Config
---@param messages table
---@return string?
M.save_chat = function(config, messages)
  local chat_history_dir = config.chat_history_dir
  local today = os.date("%Y-%m-%d")
  local chat_dir = vim.fs.joinpath(chat_history_dir, today)

  if ensure_dir(chat_dir) then
    -- Generate a unique filename for the chat
    -- local timestamp = os.date("%H-%M-%S")
    local filename = string.format("chat_%s.json", config.chat_uid)
    local filepath = vim.fs.joinpath(chat_dir, filename)

    -- Load existing chat data if it exists
    local chat_data = {}
    local existing_file = io.open(filepath, "r")
    if existing_file then
      local content = existing_file:read("*all")
      existing_file:close()
      chat_data = vim.fn.json_decode(content)
    end

    chat_data.model = config.model
    chat_data.system_prompt = config.system_prompt
    chat_data.chat_uid = config.chat_uid
    chat_data.chat_date = config.chat_date
    chat_data.conversations = messages

    -- Write the chat data to the file
    local file, err = io.open(filepath, "w")
    if not file then
      vim.notify("Error opening file: " .. err, vim.log.levels.ERROR)
      return
    end

    local json_string = vim.fn.json_encode(chat_data)
    file:write(json_string)
    file:close()
    return filepath
  end
end

---Loads a chat history from a JSON file.
---@param config Config
---@param date string
---@param chat_uid string
---@return table|nil
M.load_chat = function(config, date, chat_uid)
  local filepath = vim.fs.joinpath(config.chat_history_dir, date, string.format("chat_%s.json", chat_uid))
  local file = io.open(filepath, "r")
  if not file then
    Snacks.debug(filepath, "No file found")
    return nil
  end

  local content = file:read("*all")
  file:close()
  return vim.fn.json_decode(content)
end

return M
