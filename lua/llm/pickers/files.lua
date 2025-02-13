local windows = require("llm.ui.windows")
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
      Snacks.debug(info_lines)
      local files_in_context = {}

      for _, v in ipairs(info_lines) do
        if v ~= "" then
          table.insert(files_in_context, v)
        end
      end
      table.insert(files_in_context, item.file)
      vim.api.nvim_buf_set_lines(info.buf, 0, -1, false, files_in_context)

      -- Move cursor to input buffer
      -- TODO: this doesn't work.
      -- vim.api.nvim_set_current_buf(windows.windows.input.buf)
    end,
  })
end

return M
