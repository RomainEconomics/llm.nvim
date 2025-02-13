local M = {}

function M.initialize_session(buf, config)
  local current_date = os.date("%Y-%m-%d %H:%M:%S")
  local header = {
    "# Chat Session",
    "",
    "- Date: " .. current_date,
    "- Model: " .. config.model,
    "",
    "---",
    "",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, header)
end

return M
