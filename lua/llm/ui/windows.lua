-- TODO: add typing
local M = {}

M.windows = nil
M.is_visible = false -- Track visibility state
M.stored_contents = nil -- Store window contents

---@param config? Config
function M.toggle_windows(config)
  if M.is_visible and M.windows then
    -- Store windows contents and configs before hiding
    M.stored_contents = {}

    -- Store contents and configs for each window
    for name, handles in pairs(M.windows) do
      if vim.api.nvim_win_is_valid(handles.win) and vim.api.nvim_buf_is_valid(handles.buf) then
        -- Store buffer contents
        M.stored_contents[name] = vim.api.nvim_buf_get_lines(handles.buf, 0, -1, false)

        -- Close window
        vim.api.nvim_win_hide(handles.win)
      end
    end
    M.is_visible = false
  else
    -- Check for existing buffers
    local existing_buffers = {
      output = vim.fn.bufnr("ChatOutput"),
      info = vim.fn.bufnr("ChatInfo"),
      input = vim.fn.bufnr("ChatInput"),
    }

    -- Create new windows
    M.create_windows(config or require("llm").config, existing_buffers)

    -- Restore contents if they exist
    if M.stored_contents then
      for name, handles in pairs(M.windows) do
        if M.stored_contents[name] and vim.api.nvim_buf_is_valid(handles.buf) then
          vim.api.nvim_buf_set_lines(handles.buf, 0, -1, false, M.stored_contents[name])
        end
      end
    end

    M.is_visible = true
  end
end

---Create Windows
---@param config Config
---@param existing_buffers? table
---@return table
function M.create_windows(config, existing_buffers)
  -- TODO: to see if this needs to be added again
  -- if existing_buffers == nil then
  --   chat.reset_provider() -- Reset provider only when creating windows from scratch (not when toggling windows on/off)
  -- end
  existing_buffers = existing_buffers or {}

  -- Create the main vertical split
  vim.cmd("vsplit")

  -- Create the right-side layout with 3 windows
  vim.cmd("wincmd l")

  -- Create or reuse the output window (top)
  local output_buf
  if existing_buffers.output and existing_buffers.output ~= -1 then
    output_buf = existing_buffers.output
  else
    output_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(output_buf, "ChatOutput")
  end
  vim.api.nvim_win_set_buf(0, output_buf)
  local output_win = vim.api.nvim_get_current_win()

  -- Create or reuse the middle info window
  vim.cmd("split")
  local info_buf
  if existing_buffers.info and existing_buffers.info ~= -1 then
    info_buf = existing_buffers.info
  else
    info_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(info_buf, "ChatInfo")
  end
  vim.api.nvim_win_set_buf(0, info_buf)
  local info_win = vim.api.nvim_get_current_win()

  -- Create or reuse the input window (bottom)
  vim.cmd("split")
  local input_buf
  if existing_buffers.input and existing_buffers.input ~= -1 then
    input_buf = existing_buffers.input
  else
    input_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(input_buf, "ChatInput")
  end
  vim.api.nvim_win_set_buf(0, input_buf)
  local input_win = vim.api.nvim_get_current_win()

  -- Store window handles
  -- TODO: add typing
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

  M.is_visible = true

  return M.windows
end

function M.clear_stored_data()
  M.stored_contents = nil
  M.stored_configs = nil
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
