local M = {}

function M.is_visual_mode()
  local mode = vim.fn.mode()
  Snacks.debug("Mode", mode)
  return mode == "v" or mode == "V" or mode == "^V"
end

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
    return ""
  end

  if mode == "v" then
    local start_col = start_pos[3]
    local end_col = end_pos[3]

    -- Adjust the first and last lines according to the selection
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_col, end_col)
    else
      lines[1] = string.sub(lines[1], start_col)
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
  end
  -- In Visual Line mode ('V'), we keep the entire lines as is

  return table.concat(lines, "\n")
end

return M
