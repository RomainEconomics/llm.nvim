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

-- Format visual selected text
---@param selected_text string?
---@param filetype string?
---@return boolean
function M.format_visual_selection(selected_text, filetype)
  if not selected_text then
    return false
  end
  local windows = require("llm.ui.windows").windows

  -- Format the selected text with filetype
  local formatted_text = string.format("\n```%s\n%s\n```\n", filetype, selected_text)

  -- Add the formatted text to the input buffer
  if windows and windows.input and vim.api.nvim_buf_is_valid(windows.input.buf) then
    vim.api.nvim_buf_set_lines(windows.input.buf, 0, -1, false, vim.split(formatted_text, "\n"))
    vim.cmd("normal! G") -- Move cursor to the bottom
  end
  return true
end

--- Handle the visual selection formatting and context updates
---@param visual_selection VisualSelection
---@param filetype string
function M.handle_visual_selection(visual_selection, filetype)
  if not M.format_visual_selection(visual_selection.text, filetype) then
    Snacks.notify.error("No text selected")
    return
  end

  local windows = require("llm.ui.windows").windows
  if not (windows and windows.info and vim.api.nvim_buf_is_valid(windows.info.buf)) then
    return
  end

  -- Update context with file information
  local info_lines = vim.api.nvim_buf_get_lines(windows.info.buf, 0, -1, false)
  local files_in_context = { visual_selection.file_path }
  for _, v in ipairs(info_lines) do
    if v ~= "" and v ~= visual_selection.file_path then
      table.insert(files_in_context, v)
    end
  end
  vim.api.nvim_buf_set_lines(windows.info.buf, 0, -1, false, files_in_context)
end

return M
