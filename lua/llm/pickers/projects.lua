local projects = require("llm.projects")
local models = require("llm.pickers.models")

local M = {}

function M.pick_projects(config, callback)
  local Snacks = require("snacks")
  local projects_list = projects.get_projects(config)

  -- If no projects exist, create Default project
  if #projects_list == 0 then
    if projects.create_project(config, "Default", config.system_prompt, config.model) then
      projects_list = projects.get_projects(config)
    else
      Snacks.notifier.notify("Failed to create Default project", "error", { title = "Error" })
      return
    end
  end

  return Snacks.picker({
    finder = function()
      local items = {}
      for i, project in ipairs(projects_list) do
        table.insert(items, {
          idx = i,
          project = project,
          text = project.name,
        })
      end
      return items
    end,
    layout = {
      layout = {
        box = "horizontal",
        width = 0.5,
        height = 0.5,
        {
          box = "vertical",
          border = "rounded",
          title = "Select Project",
          { win = "input", height = 1, border = "bottom" },
          { win = "list", border = "none" },
        },
      },
    },
    format = function(item, _)
      local project = item.project
      local ret = {}
      local a = Snacks.picker.util.align
      local icon, icon_hl = Snacks.util.icon("json", "file")
      ret[#ret + 1] = { a(icon, 3), icon_hl }
      ret[#ret + 1] = { " " }
      ret[#ret + 1] = { a(project.name, 20) }
      ret[#ret + 1] = { " " }
      ret[#ret + 1] = { os.date("%Y-%m-%d", project.updated_at) }

      return ret
    end,
    confirm = function(picker, item)
      picker:close()

      -- Update config with project settings
      config.system_prompt = item.project.system_prompt
      config.project_name = item.project.name
      if item.project.default_model then
        config.model = item.project.default_model
      end

      if callback then
        callback(item.project.name)
      end
    end,
  })
end

function M.create_project_picker(config)
  local Snacks = require("snacks")

  local function on_name_confirm(name)
    if not name or name == "" then
      Snacks.notifier.notify("Project name cannot be empty", "error", { title = "Error" })
      return
    end

    if projects.project_exists(config, name) then
      Snacks.notifier.notify("Project '" .. name .. "' already exists", "error", { title = "Error" })
      return
    end

    -- After name is confirmed, prompt for system prompt
    local function on_system_prompt_confirm(system_prompt)
      if not system_prompt or system_prompt == "" then
        Snacks.notifier.notify("System prompt cannot be empty", "error", { title = "Error" })
        return
      end

      -- After system prompt is confirmed, select model
      models.select_model(config, function(selected_model)
        if not selected_model then
          Snacks.notifier.notify("No model selected", "error", { title = "Error" })
          return
        end

        -- Create project with all collected information
        if projects.create_project(config, name, system_prompt, selected_model) then
          Snacks.notifier.notify("Project created: " .. name, "info", { title = "Project created" })
        end
      end)
    end

    -- Show system prompt input
    Snacks.input.input({
      title = "Enter system prompt",
      prompt = "System prompt: ",
      default = config.system_prompt,
      multiline = true,
    }, on_system_prompt_confirm)
  end

  -- Show project name input
  Snacks.input.input({
    title = "Create New Project",
    prompt = "Project name: ",
  }, on_name_confirm)
end

function M.update_project_picker(config)
  local Snacks = require("snacks")
  local projects_list = projects.get_projects(config)

  return Snacks.picker({
    finder = function()
      local items = {}
      for i, project in ipairs(projects_list) do
        table.insert(items, {
          idx = i,
          project = project,
          text = project.name,
        })
      end
      return items
    end,
    layout = {
      layout = {
        box = "horizontal",
        width = 0.5,
        height = 0.5,
        {
          box = "vertical",
          border = "rounded",
          title = "Update Project",
          { win = "input", height = 1, border = "bottom" },
          { win = "list", border = "none" },
        },
      },
    },
    format = function(item, _)
      local project = item.project
      local ret = {}
      local a = Snacks.picker.util.align
      local icon, icon_hl = Snacks.util.icon("json", "file")
      ret[#ret + 1] = { a(icon, 3), icon_hl }
      ret[#ret + 1] = { " " }
      ret[#ret + 1] = { a(project.name, 20) }
      ret[#ret + 1] = { " " }
      ret[#ret + 1] = { os.date("%Y-%m-%d", project.updated_at) }

      return ret
    end,
    confirm = function(picker, item)
      picker:close()

      -- Get new system prompt from input
      local system_prompt = vim.api.nvim_buf_get_lines(picker.input_win.buf, 0, -1, false)
      system_prompt = table.concat(system_prompt, "\n")

      if system_prompt then
        if projects.update_project(config, item.project.name, system_prompt) then
          Snacks.notifier.notify("Project updated: " .. item.project.name, "info", { title = "Project updated" })
        end
      end
    end,
  })
end

return M
