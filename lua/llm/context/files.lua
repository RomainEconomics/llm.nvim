local M = {}

local function get_extension(filepath)
  return filepath:match("%.([^%.]+)$") or ""
end

function M.get_files_context(info_buf)
  local filepath_in_context = vim.api.nvim_buf_get_lines(info_buf, 0, -1, false)
  if #filepath_in_context < 1 or filepath_in_context[1] == "" then
    return nil
  end

  local files_context = {
    "To help answer the user requests, you're provided context from files located in the local project of the user. Use the context provided when you think it is useful to answer the user requests.",
  }

  for _, filepath in ipairs(filepath_in_context) do
    -- Remove icon if any
    local splits = vim.split(filepath, " ")
    local clean_filepath
    if #splits == 1 then
      clean_filepath = filepath
    elseif #splits == 2 then
      clean_filepath = splits[2]
    else
      error("File path format is not the expected one")
    end

    local lines = vim.fn.readfile(clean_filepath)
    local s = table.concat(lines, "\n")
    local file_type = get_extension(clean_filepath)
    table.insert(
      files_context,
      "FILEPATH: " .. clean_filepath .. "\n\nCONTEXT:\n```" .. file_type .. "\n" .. s .. "\n```"
    )
  end

  return table.concat(files_context, "\n\n")
end

return M
