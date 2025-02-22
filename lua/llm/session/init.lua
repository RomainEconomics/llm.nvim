local uuid = require("llm.utils.uuid")

local M = {}

function M.initialize_session(buf, config)
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
    "",
    "---",
    "",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)
end

return M
