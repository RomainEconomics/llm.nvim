local utils = require("llm.utils.utils")
local files = require("llm.utils.files")
local M = {}

function M.add_buffers_to_context(chat_windows)
  -- 1. Get files already in context
  local info_lines = vim.api.nvim_buf_get_lines(chat_windows.info.buf, 0, -1, false)

  local files_in_context = {}
  for _, v in ipairs(info_lines) do
    if v ~= "" then
      table.insert(files_in_context, v)
    end
  end

  -- 2. Add the buffers in context
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer) then
      local filename = vim.api.nvim_buf_get_name(buffer)
      -- Only add buffers files (ChatInput, ChatOutput ... have a `nofile` type, we skip those)
      if filename ~= "" and vim.bo[buffer].buftype == "" then
        local filepath = utils.get_relative_path(filename)
        local icon = files.get_icon(filepath)
        table.insert(files_in_context, icon .. filepath)
      end
    end
  end

  -- 3. Ensures no duplicates
  local clean_files_in_context = utils.remove_duplicates(files_in_context)

  vim.api.nvim_buf_set_lines(chat_windows.info.buf, 0, -1, false, clean_files_in_context)
end

return M
