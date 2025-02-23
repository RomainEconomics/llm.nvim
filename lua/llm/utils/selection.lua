local utils = require("llm.utils.utils")

local M = {}

function M.is_visual_mode()
  local mode = vim.fn.mode()
  return mode == "v" or mode == "V" or mode == "^V"
end

---@class VisualSelection
---@field file_path string The path of the current buffer
---@field start_line integer Starting line number
---@field end_line integer Ending line number
---@field start_col integer? Starting column (only for characterwise visual mode)
---@field end_col integer? Ending column (only for characterwise visual mode)
---@field text string The selected text content

---Handle visual selection
---@return VisualSelection|nil
function M.get_visual_selection()
  if not M.is_visual_mode() then
    return nil
  end

  local mode = vim.fn.mode()

  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getcurpos()

  -- Ensure start_pos is before end_pos
  if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
    start_pos, end_pos = end_pos, start_pos
  end

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  -- Get the selected lines
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if #lines == 0 then
    return nil
  end

  local file_path = utils.get_relative_path(vim.fn.expand("%:p"))

  local result = {
    file_path = file_path,
    start_line = start_line,
    end_line = end_line,
    text = "",
  }

  if mode == "v" then
    local start_col = start_pos[3]
    local end_col = end_pos[3]

    result.start_col = start_col
    result.end_col = end_col

    -- Adjust the first and last lines according to the selection
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_col, end_col)
    else
      lines[1] = string.sub(lines[1], start_col)
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
  end
  -- In Visual Line mode ('V'), we keep the entire lines as is

  result.text = table.concat(lines, "\n")
  return result
end

return M
