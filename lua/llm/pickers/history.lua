local M = {}

local function process_input(input_lines)
  local formatted_lines = {}
  for _, line in ipairs(input_lines) do
    table.insert(formatted_lines, "> " .. line)
  end

  table.insert(formatted_lines, 1, "")
  table.insert(formatted_lines, "")

  return table.concat(formatted_lines, "\n")
end

local function read_json_file(file_path)
  local content = vim.fn.readfile(file_path)
  if vim.tbl_isempty(content) then
    return nil, "Failed to read file"
  end

  -- Join all lines and decode
  local status, data = pcall(vim.json.decode, table.concat(content))
  if not status then
    return nil, "Failed to decode JSON"
  end

  return data
end

---@param config Config
---@param callback function
function M.pick_history(config, callback)
  local projects = require("llm.projects")
  local project_dir = projects.get_project_directory(config, config.project_name)

  Snacks.picker.files({
    cwd = project_dir,
    hidden = true,
    finder = function()
      local items = {}
      local files = vim.fn.glob(project_dir .. "/**/*.json", false, true)

      for _, file in ipairs(files) do
        if not file:match("project_config.json$") then
          local relative_path = vim.fn.fnamemodify(file, ":.")
          table.insert(items, {
            file = relative_path,
            text = relative_path,
          })
        end
      end
      return items
    end,
    actions = {
      delete_file = function(picker, item)
        vim.fs.rm(item.file)
        picker:find()
      end,
    },
    win = {
      input = {
        keys = {
          ["dd"] = { "delete_file", desc = "Delete file history", mode = { "n" } },
        },
      },
    },
    preview = function(ctx)
      local path = Snacks.picker.util.path(ctx.item)
      local data = read_json_file(path)

      if data == nil then
        return
      end

      local formatted_conv = {}

      if not data.conversations then
        table.insert(formatted_conv, "Empty conversations. Skip...")
      else
        local header = {
          "# Chat Session",
          "",
          "- Date: " .. (data.chat_date or ""),
          "- Model: " .. (data.model or ""),
          "- Chat ID: " .. (data.chat_uid or ""),
          "- Project: " .. (config.project_name or data.project_name or "No project"),
          "",
          "---",
          "",
        }

        for _, line in ipairs(header) do
          table.insert(formatted_conv, line)
        end

        if string.find(data.model, "gemini") then
          -- Gemini case
          local gemini = require("llm.providers.gemini")
          for _, x in ipairs(data.conversations.contents) do
            if x.role == "user" then
              local content = gemini.handle_gemini_content(x.parts)
              local lines = vim.split(content, "\n")
              local formatted_lines = process_input(lines)
              table.insert(formatted_conv, formatted_lines)
            elseif x.role == "system" then
            elseif x.role == "model" then -- For Gemini responses
              table.insert(formatted_conv, gemini.handle_gemini_content(x.parts))
            else
              Snacks.notify.warn("Unknown role")
            end
          end
        else
          -- Openai/Anthropic case
          for _, x in ipairs(data.conversations) do
            if x.role == "user" then
              local lines = vim.split(x.content, "\n")
              local formatted_lines = process_input(lines)
              table.insert(formatted_conv, formatted_lines)
            elseif x.role == "system" then
            else
              table.insert(formatted_conv, x.content)
            end
          end
        end
      end

      ctx.preview:set_lines(formatted_conv)
      ctx.preview:highlight({ file = path, ft = "markdown", buf = ctx.buf })
      ctx.preview:loc()
    end,
    confirm = function(picker, item)
      picker:close()
      Snacks.debug("Selected file: " .. item.file)
      Snacks.notifier.notify(item.file, "info", { title = "Start chat from this file history" })
      callback(item.file)
    end,
  })
end

return M
