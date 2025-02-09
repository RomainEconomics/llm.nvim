local M = {}

M.windows = nil

---Create Windows
---@param config Config
---@return table
function M.create_windows(config)
  -- Create the main vertical split
  vim.cmd("vsplit")

  -- Create the right-side layout with 3 windows
  vim.cmd("wincmd l")

  -- Create the output window (top)
  local output_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(output_buf, "ChatOutput")
  vim.api.nvim_win_set_buf(0, output_buf)
  local output_win = vim.api.nvim_get_current_win()

  -- Create the middle info window
  vim.cmd("split")
  local info_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(info_buf, "ChatInfo")
  vim.api.nvim_win_set_buf(0, info_buf)
  local info_win = vim.api.nvim_get_current_win()

  -- Create the input window (bottom)
  vim.cmd("split")
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(input_buf, "ChatInput")
  vim.api.nvim_win_set_buf(0, input_buf)
  local input_win = vim.api.nvim_get_current_win()

  -- Store window handles
  M.windows = {
    output = { buf = output_buf, win = output_win },
    info = { buf = info_buf, win = info_win },
    input = { buf = input_buf, win = input_win },
  }

  -- Adjust window sizes
  vim.cmd("wincmd k")
  vim.cmd("wincmd k")

  vim.cmd("resize +" .. config.window_sizes.output) -- increase output window size

  vim.cmd("wincmd j")
  if config.window_sizes.info ~= nil then
    vim.cmd("resize " .. config.window_sizes.info)
  end
  vim.cmd("wincmd j")
  vim.cmd("resize -" .. config.window_sizes.input)

  -- Configure buffers
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = output_buf })
  vim.api.nvim_set_option_value("modifiable", true, { buf = output_buf })
  vim.api.nvim_set_option_value("filetype", config.filetype, { buf = output_buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = input_buf })

  return M.windows
end

function M.close_windows()
  if M.windows then
    for _, handles in pairs(M.windows) do
      if vim.api.nvim_win_is_valid(handles.win) then
        vim.api.nvim_win_close(handles.win, true)
      end
      if vim.api.nvim_buf_is_valid(handles.buf) then
        vim.api.nvim_buf_delete(handles.buf, { force = true })
      end
    end
    M.windows = nil
  end
end

function M.cycle_windows(direction)
  if not M.windows then
    return
  end

  local windows = {
    M.windows.output.win,
    M.windows.info.win,
    M.windows.input.win,
  }
  local current_win = vim.api.nvim_get_current_win()

  for i, win in ipairs(windows) do
    if current_win == win then
      local next_index
      if direction == "forward" then
        next_index = (i % #windows) + 1
      else
        next_index = ((i - 2 + #windows) % #windows) + 1
      end
      vim.api.nvim_set_current_win(windows[next_index])
      break
    end
  end
end

return M
