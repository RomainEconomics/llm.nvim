local M = {}

local function get_projects_dir(config)
  return config.chat_history_dir
end

local function sanitize_name(name)
  if not name then
    return "default"
  end
  return name:gsub("%s+", "_"):lower()
end

local function get_project_dir(config, name)
  local sanitized = sanitize_name(name)
  return vim.fs.joinpath(get_projects_dir(config), sanitized)
end

local function get_project_config_path(project_dir)
  return vim.fs.joinpath(project_dir, "project_config.json")
end

---Create a new project
---@param config Config
---@param name string
---@param system_prompt string
---@param default_model string
---@return boolean
function M.create_project(config, name, system_prompt, default_model)
  local project_dir = get_project_dir(config, name)
  vim.fn.mkdir(project_dir, "p")

  local project_file = get_project_config_path(project_dir)
  local data = {
    name = name,
    system_prompt = system_prompt,
    default_model = default_model,
    created_at = os.time(),
    updated_at = os.time(),
  }

  local ok, result = pcall(function()
    local json_str = vim.fn.json_encode(data)
    vim.fn.writefile({ json_str }, project_file)
  end)

  if not ok then
    vim.notify(string.format("Failed to create project: %s", result), vim.log.levels.ERROR)
    return false
  end
  return true
end

---Get all available projects
---@param config Config
---@return table
function M.get_projects(config)
  local projects_dir = get_projects_dir(config)
  local projects = {}

  if vim.fn.isdirectory(projects_dir) == 0 then
    return projects
  end

  -- Get all directories in the projects directory
  local dirs = vim.fn.glob(projects_dir .. "/*", false, true)
  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local config_file = get_project_config_path(dir)
      if vim.fn.filereadable(config_file) == 1 then
        local content = vim.fn.readfile(config_file)
        local data = vim.fn.json_decode(table.concat(content, "\n"))
        table.insert(projects, data)
      end
    end
  end

  return projects
end

---Update project system prompt
---@param config Config
---@param name string
---@param system_prompt string
---@return boolean
function M.update_project(config, name, system_prompt)
  local project_dir = get_project_dir(config, name)
  local project_file = get_project_config_path(project_dir)

  if vim.fn.filereadable(project_file) == 0 then
    return false
  end

  local content = vim.fn.readfile(project_file)
  local data = vim.fn.json_decode(table.concat(content, "\n"))
  data.system_prompt = system_prompt
  data.updated_at = os.time()

  local ok, result = pcall(function()
    local json_str = vim.fn.json_encode(data)
    vim.fn.writefile({ json_str }, project_file)
  end)

  if not ok then
    vim.notify(string.format("Failed to update project: %s", result), vim.log.levels.ERROR)
    return false
  end
  return true
end

---Get project by name
---@param config Config
---@param name string
---@return table?
function M.get_project(config, name)
  local project_dir = get_project_dir(config, name)
  local project_file = get_project_config_path(project_dir)

  if vim.fn.filereadable(project_file) == 0 then
    return nil
  end

  local content = vim.fn.readfile(project_file)
  return vim.fn.json_decode(table.concat(content, "\n"))
end

---Check if project exists
---@param config Config
---@param name string
---@return boolean
function M.project_exists(config, name)
  local project_dir = get_project_dir(config, name)
  local project_file = get_project_config_path(project_dir)
  return vim.fn.filereadable(project_file) == 1
end

---Get project directory for a given project name
---@param config Config
---@param name string
---@return string
function M.get_project_directory(config, name)
  return get_project_dir(config, name)
end

return M
