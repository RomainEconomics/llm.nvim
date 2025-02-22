local windows = require("llm.ui.windows")
local utils = require("llm.utils.utils")
local files = require("llm.utils.files")

local M = {}

local function get_directories()
  local directories = {}

  -- local handle = io.popen("fd . --type directory --hidden")
  local handle = io.popen("fd . --type directory")
  if handle then
    for line in handle:lines() do
      table.insert(directories, line)
    end
    handle:close()
  else
    Snacks.notify.error("Failed to execute fd command")
  end

  return directories
end

function M.pick_dirs()
  local Snacks = require("snacks")
  local dirs = get_directories()

  return Snacks.picker({
    finder = function()
      local items = {}
      for i, item in ipairs(dirs) do
        table.insert(items, {
          idx = i,
          file = item,
          text = item,
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
          title = "Find directory",
          { win = "input", height = 1, border = "bottom" },
          { win = "list", border = "none" },
        },
      },
    },
    format = function(item, _)
      local file = item.file
      local ret = {}
      local a = Snacks.picker.util.align
      local icon, icon_hl = Snacks.util.icon(file.ft, "directory")
      ret[#ret + 1] = { a(icon, 3), icon_hl }
      ret[#ret + 1] = { " " }
      ret[#ret + 1] = { a(file, 20) }

      return ret
    end,
    confirm = function(picker, item)
      picker:close()

      Snacks.notifier.notify(item.file, "info", { title = "File added to context" })

      local info = windows.windows.info

      local info_lines = vim.api.nvim_buf_get_lines(info.buf, 0, -1, false)

      local files_in_context = {}
      for _, v in ipairs(info_lines) do
        if v ~= "" then
          table.insert(files_in_context, v)
        end
      end

      local handle = io.popen("fd . " .. item.file .. " --type file")
      if handle then
        for line in handle:lines() do
          local icon = files.get_icon(item.file)
          table.insert(files_in_context, icon .. line)
        end
      end

      local clean_files_in_context = utils.remove_duplicates(files_in_context)

      vim.api.nvim_buf_set_lines(info.buf, 0, -1, false, clean_files_in_context)

      -- Ensures the focus is on the input buf
      -- The function will run only after selection is made
      vim.schedule(function()
        vim.api.nvim_set_current_win(windows.windows.input.win)
      end)
    end,
  })
end

return M
