local files_picker = require("llm.pickers.files")
local dirs_picker = require("llm.pickers.dirs")
local projects_picker = require("llm.pickers.projects")
local windows = require("llm.ui.windows")
local buf_context = require("llm.context.buffers")
local model_picker = require("llm.pickers.models")

local M = {}

-- Helper function to clear chat windows and reset chat state
local function clear_chat_state(config)
  local chat = require("llm.chat")
  local session = require("llm.session")
  local windows = require("llm.ui.windows")

  -- Check if windows are initialized, if not, initialize them
  if not windows.windows.output or not windows.windows.output.buf then
    windows.setup(config)
  end

  local output_buf = windows.windows.output.buf
  local info_buf = windows.windows.info.buf
  local input_buf = windows.windows.input.buf

  vim.api.nvim_buf_set_lines(output_buf, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(info_buf, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {})

  chat.reset_provider()
  chat.load_provider(config.model)

  config.chat_uid = nil
  config.chat_date = nil
  session.initialize_session(windows.windows.output.buf, config)
end

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

  -- Clear chat keymap
  vim.keymap.set("n", config.keys.clear_chat, callbacks.clear_chat, { buffer = buf, desc = "Clear chat windows" })

  -- Switch model keymap
  vim.keymap.set("n", config.keys.switch_model, callbacks.switch_model, { buffer = buf, desc = "Switch model" })
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

  vim.keymap.set("n", config.keys.create_project, function()
    projects_picker.create_project_picker(config)
  end, { desc = "Create new project" })

  vim.keymap.set("n", config.keys.update_project, function()
    projects_picker.update_project_picker(config)
  end, { desc = "Update project" })

  vim.keymap.set("n", config.keys.select_project, function()
    local windows = require("llm.ui.windows")
    local has_active_chat = windows.windows.output and windows.windows.output.buf and vim.api.nvim_win_is_valid(windows.windows.output.win)

    local function switch_project()
      -- Store current window to return to it after picker closes
      local current_win = vim.api.nvim_get_current_win()
      
      projects_picker.pick_projects(config, function(selected_project)
        if selected_project then
          -- Update config with project settings
          config.project_name = selected_project
          -- Clear chat state and reload provider
          clear_chat_state(config)
          
          -- Use vim.schedule to ensure this runs after the picker is fully closed
          vim.schedule(function()
            -- Reinitialize windows if needed
            if not windows.windows.output or not windows.windows.output.buf then
              windows.setup(config)
            end
            -- Try to focus input window, fallback to current window if it fails
            pcall(function()
              vim.api.nvim_set_current_win(windows.windows.input.win)
            end)
          end)
        end
      end)
    end

    if has_active_chat then
      -- Show confirmation dialog only if there's an active chat
      local choice = vim.fn.confirm("Switching project will clear the current chat. Continue?", "&Yes\n&No", 2)
      if choice == 1 then
        switch_project()
      end
    else
      -- No active chat, switch project immediately
      switch_project()
    end
  end, { desc = "Switch project" })
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
    clear_chat = function()
      clear_chat_state(config)
    end,
    switch_model = function()
      -- Show confirmation dialog
      local choice = vim.fn.confirm("Switching model will clear the current chat. Continue?", "&Yes\n&No", 2)
      if choice == 1 then
        model_picker.select_model(config, function(selected_model)
          if selected_model ~= nil then
            config.model = selected_model
            clear_chat_state(config)
            vim.api.nvim_set_current_win(windows.windows.input.win)
          end
        end)
      end
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
