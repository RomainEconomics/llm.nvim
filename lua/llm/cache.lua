local M = {}

local cache_file = "cache_data.json"

function M.hash_path(path)
  return vim.fn.sha256(path)
end

---Get or create cache directory
---@param config Config
---@return string
function M.get_project_cache_dir(config)
  local cwd = vim.fn.getcwd()
  local path_hash = M.hash_path(cwd)

  local cache_path = string.format(
    "%s/%s",
    config.cache_dir,
    path_hash:sub(1, 8) -- Use first 8 characters for shorter paths
  )

  vim.fn.mkdir(cache_path, "p")

  return cache_path
end

---Get or create cache directory
---@param config Config
---@return string
function M.get_cache_file_path(config)
  return vim.fs.joinpath(M.get_project_cache_dir(config), cache_file)
end

---Save cache data (mainly the last chat history path for a given project)
---@param data table
---@param config Config
---@return boolean
function M.save_cache(data, config)
  local ok, result = pcall(function()
    local file_path = M.get_cache_file_path(config)
    local json_str = vim.fn.json_encode(data)
    vim.fn.writefile({ json_str }, file_path)
    Snacks.debug("Save cache", file_path, json_str)
  end)

  if not ok then
    vim.notify(string.format("Failed to save cache: %s", result), vim.log.levels.ERROR)
    return false
  end
  return true
end

-- TODO: add typing for the cache data
---Load cache data
---@param config Config
---@return table?
function M.load_cache(config)
  local file_path = M.get_cache_file_path(config)
  if vim.fn.filereadable(file_path) == 1 then
    local content = vim.fn.readfile(file_path)
    return vim.fn.json_decode(table.concat(content, "\n"))
  end
  return nil
end

return M

-- Save some data
-- cache.save_cache('settings', {
--     last_used = os.time(),
--     some_setting = "value"
-- })

-- Load the data
-- local data = cache.load_cache('settings')
-- if data then
--     print(data.some_setting)
-- end
