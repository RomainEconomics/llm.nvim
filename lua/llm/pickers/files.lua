local windows = require("llm.ui.windows")
local utils = require("llm.utils.utils")
local mini_icons = require("mini.icons")
local files = require("llm.utils.files")
local M = {}

---Send input
---@param config Config
function M.pick_files(config)
  local Snacks = require("snacks")

  Snacks.picker({
    finder = "files",
    -- layout = {
    --   layout = {
    --     box = "horizontal",
    --     width = 0.5,
    --     height = 0.5,
    --     {
    --       box = "vertical",
    --       border = "rounded",
    --       title = "Choose your model",
    --       { win = "input", height = 1, border = "bottom" },
    --       { win = "list", border = "none" },
    --     },
    --   },
    -- },
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

      local icon = files.get_icon(item.file)
      table.insert(files_in_context, icon .. item.file)

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
