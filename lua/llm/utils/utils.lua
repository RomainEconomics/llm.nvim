local M = {}

function M.remove_duplicates(tbl)
  local hash = {}
  for _, v in ipairs(tbl) do
    hash[v] = true
  end
  return vim.tbl_keys(hash)
end

function M.get_relative_path(filename)
  local cwd = vim.fn.getcwd()
  if string.sub(filename, 1, #cwd) == cwd then
    return string.sub(filename, #cwd + 2)
  else
    return filename
  end
end

return M
