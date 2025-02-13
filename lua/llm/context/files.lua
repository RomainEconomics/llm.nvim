local M = {}

function M.get_files_context(info_buf)
  local filepath_in_context = vim.api.nvim_buf_get_lines(info_buf, 0, -1, false)
  if #filepath_in_context < 1 or filepath_in_context[1] == "" then
    return nil
  end

  local files_context = {
    "To help answer the user requests, you're provided context from files located in the local project of the user. Use this context when you think it is useful to answer the user requests.",
  }

  for _, filepath in ipairs(filepath_in_context) do
    local lines = vim.fn.readfile(filepath)
    local s = table.concat(lines, "\n")
    table.insert(files_context, filepath .. "\n" .. s)
  end

  return table.concat(files_context, "\n\n")
end

return M
