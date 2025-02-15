local chat = require("llm.chat")
local files_picker = require("llm.pickers.files")
local files_context = require("llm.context.files")
local input_processor = require("llm.input.processor")
local keymaps = require("llm.ui.keymaps")
local session = require("llm.session")
local windows = require("llm.ui.windows")

local M = {}

M.messages = nil

---Send input
---@param config Config
local function send_input(config)
  local handles = windows.windows.input
  if not handles or not vim.api.nvim_buf_is_valid(handles.buf) then
    return
  end

  -- Process user input
  local input_lines = vim.api.nvim_buf_get_lines(handles.buf, 0, -1, false)
  local formatted_lines, input_text = input_processor.process_input(input_lines)

  -- Add user input to output
  local output_buf = windows.windows.output.buf
  vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, formatted_lines)

  -- Add files in context (if any)
  local info_buf = windows.windows.info.buf
  local files_content_in_context = files_context.get_files_context(info_buf)

  Snacks.debug(files_content_in_context)

  -- Call API provider
  chat.call_llm(input_text, config, files_content_in_context)

  vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, { "" })

  -- Clear user input
  vim.api.nvim_buf_set_lines(handles.buf, 0, -1, false, { "" })
end

---@param config Config
function M.setup(config)
  -- Set up global toggle keymap
  vim.keymap.set("n", "<leader>zt", function()
    windows.toggle_windows(config) -- Pass config to toggle_windows
  end, { desc = "Toggle chat windows" })

  -- create windows reset chat history, but only for a given provider
  local chat_windows = windows.create_windows(config)
  session.initialize_session(chat_windows.output.buf, config)

  -- Partials
  local function pick_files_with_config()
    return files_picker.pick_files(config)
  end
  local function send_input_with_config()
    return send_input(config)
  end

  -- Setup keymaps for all windows
  local callbacks = {
    cycle = windows.cycle_windows,
    close = windows.close_windows,
    add_file_to_context = pick_files_with_config,
  }

  for _, handles in pairs(chat_windows) do
    keymaps.setup_buffer_keymaps(handles.buf, callbacks)
  end

  -- Add send callback for input buffer
  keymaps.setup_buffer_keymaps(
    chat_windows.input.buf,
    vim.tbl_extend("force", callbacks, {
      send = send_input_with_config,
    })
  )

  -- Focus input window
  vim.cmd("wincmd j")
end

return M
