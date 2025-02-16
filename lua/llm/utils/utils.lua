local M = {}

function M.remove_duplicates(tbl)
  local hash = {}
  for _, v in ipairs(tbl) do
    hash[v] = true
  end
  return vim.tbl_keys(hash)
end

return M
