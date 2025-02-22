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
  Snacks.picker.files({
    cwd = config.chat_history_dir,

    actions = {
      delete_file = function(picker, item)
        local file_path = vim.fs.joinpath(item.cwd, item.file)
        vim.fs.rm(file_path)
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
      -- ctx.preview:set_title(ctx.item.title)

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
          "",
          "---",
          "",
        }

        for _, line in ipairs(header) do
          table.insert(formatted_conv, line)
        end

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

      ctx.preview:set_lines(formatted_conv)
      ctx.preview:highlight({ file = path, ft = "markdown", buf = ctx.buf })
      ctx.preview:loc()
    end,
    confirm = function(picker, item)
      picker:close()
      Snacks.notifier.notify(item.file, "info", { title = "Start chat from this file history" })
      callback(item.file)

      -- local info = windows.windows.info
      --
      -- local info_lines = vim.api.nvim_buf_get_lines(info.buf, 0, -1, false)
      --
      -- local files_in_context = {}
      -- for _, v in ipairs(info_lines) do
      --   if v ~= "" then
      --     table.insert(files_in_context, v)
      --   end
      -- end
      -- table.insert(files_in_context, item.file)
      --
      -- local clean_files_in_context = utils.remove_duplicates(files_in_context)
      --
      -- vim.api.nvim_buf_set_lines(info.buf, 0, -1, false, clean_files_in_context)
      --
      -- -- Ensures the focus is on the input buf
      -- -- The function will run only after selection is made
      -- vim.schedule(function()
      --   vim.api.nvim_set_current_win(windows.windows.input.win)
      -- end)
    end,
  })
end

return M
