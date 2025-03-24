local windows = require("llm.ui.windows")
local M = {}

M.scroll_enabled = true

function M.update_output_buffer(msg)
  vim.schedule(function()
    local handles = windows.windows.output
    if not handles or not vim.api.nvim_buf_is_valid(handles.buf) then
      return
    end

    local lines = vim.api.nvim_buf_get_lines(handles.buf, 0, -1, false)
    local last_line = lines[#lines]
    local new_line_idx = string.find(msg, "\n")

    if new_line_idx then
      -- Update existing line
      local updated_line = last_line .. string.sub(msg, 1, new_line_idx - 1)
      vim.api.nvim_buf_set_lines(handles.buf, #lines - 1, #lines, false, { updated_line })

      -- Add new lines
      local new_lines = vim.split(string.sub(msg, new_line_idx + 1), "\n")
      if #new_lines > 0 then
        vim.api.nvim_buf_set_lines(handles.buf, #lines, #lines, false, new_lines)
      end
    else
      -- Append to last line
      local updated_last_line = last_line .. msg
      vim.api.nvim_buf_set_lines(handles.buf, #lines - 1, #lines, false, { updated_last_line })
    end

    -- Only scroll to bottom if enabled
    if M.scroll_enabled and vim.api.nvim_win_is_valid(handles.win) then
      vim.api.nvim_win_set_cursor(handles.win, { vim.api.nvim_buf_line_count(handles.buf), 0 })
    end
  end)
end

function M.setup_scroll_keymaps(handles)
  -- Stop scroll when user presses j/k keys
  vim.keymap.set("n", "j", function()
    M.scroll_enabled = false
    -- Perform normal j movement
    vim.cmd("normal! j")
  end, { buffer = handles.buf, desc = "Move down and disable auto-scroll" })

  vim.keymap.set("n", "k", function()
    M.scroll_enabled = false
    -- Perform normal k movement
    vim.cmd("normal! k")
  end, { buffer = handles.buf, desc = "Move up and disable auto-scroll" })

  -- Re-enable scroll when user presses G
  vim.keymap.set("n", "G", function()
    M.scroll_enabled = true
    -- Perform normal G movement
    vim.cmd("normal! G")
  end, { buffer = handles.buf, desc = "Move to bottom and enable auto-scroll" })
end

return M
