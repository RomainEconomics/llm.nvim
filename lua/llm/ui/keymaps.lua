local files_picker = require("llm.pickers.files")
local dirs_picker = require("llm.pickers.dirs")
local windows = require("llm.ui.windows")
local buf_context = require("llm.context.buffers")

local M = {}

---Setup keymaps helper
---@param buf any
---@param config Config
---@param callbacks table
function M.setup_buffer_keymaps(buf, config, callbacks)
  -- Navigation keymaps
  vim.keymap.set("n", config.keys.cycle_forward, function()
    callbacks.cycle("forward")
  end, { buffer = buf, desc = "Cycle to next chat window" })

  vim.keymap.set("n", config.keys.cycle_backward, function()
    callbacks.cycle("backward")
  end, { buffer = buf, desc = "Cycle to previous chat window" })

  -- Close windows keymap
  vim.keymap.set("n", config.keys.close_windows, callbacks.close, { buffer = buf, desc = "Close chat windows" })

  -- Add File to context
  vim.keymap.set(
    "n",
    config.keys.add_file_to_context,
    callbacks.add_file_to_context,
    { buffer = buf, desc = "Add File to context" }
  )

  -- Add Files in a given directory to context
  vim.keymap.set(
    "n",
    config.keys.add_dir_to_context,
    callbacks.add_dir_to_context,
    { buffer = buf, desc = "Add Files from a directory to context" }
  )

  -- Add all open buffers to context
  vim.keymap.set(
    "n",
    config.keys.add_buffers_to_context,
    callbacks.add_buffers_to_context,
    { buffer = buf, desc = "Add Open Buffers to context" }
  )

  -- Send message keymap (only for input buffer)
  if callbacks.send then
    vim.keymap.set("n", config.keys.send_input, callbacks.send, { buffer = buf, desc = "Send chat message" })
  end
end

-- TODO: add param type for windows
---@param config Config
function M.global_keymaps(config)
  vim.keymap.set("n", config.keys.toggle_windows, function()
    windows.toggle_windows(config) -- Pass config to toggle_windows
  end, { desc = "Toggle chat windows" })

  -- Focus input window
  vim.keymap.set("n", config.keys.focus_window, function()
    vim.api.nvim_set_current_win(windows.windows.input.win)
  end, { desc = "Focus input window" })
end

function M.buffer_keymaps(config, chat_windows, send_input)
  local callbacks = {
    cycle = windows.cycle_windows,
    close = windows.close_windows,
    add_file_to_context = function()
      files_picker.pick_files(config)
    end,
    add_dir_to_context = dirs_picker.pick_dirs,
    add_buffers_to_context = function()
      buf_context.add_buffers_to_context(chat_windows)
    end,
    focus_input_window = function()
      vim.api.nvim_set_current_win(windows.windows.input.win)
    end,
  }

  for _, handles in pairs(chat_windows) do
    M.setup_buffer_keymaps(handles.buf, config, callbacks)
  end

  -- Add send callback for input buffer
  M.setup_buffer_keymaps(
    chat_windows.input.buf,
    config,
    vim.tbl_extend("force", callbacks, {
      send = function()
        send_input(config)
      end,
    })
  )
end

return M
