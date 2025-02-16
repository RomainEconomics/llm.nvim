local chat = require("llm.chat")
local files_picker = require("llm.pickers.files")
local files_context = require("llm.context.files")
local input_processor = require("llm.input.processor")
local keymaps = require("llm.ui.keymaps")
local session = require("llm.session")
local windows = require("llm.ui.windows")
local utils = require("llm.utils.utils")

local M = {}

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

  -- Call API provider
  chat.call_llm(input_text, config, files_content_in_context)

  vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, { "" })

  -- Clear user input
  vim.api.nvim_buf_set_lines(handles.buf, 0, -1, false, { "" })
end

local function add_buffers_to_context(chat_windows)
  local function _get_relative_path(filename)
    local cwd = vim.fn.getcwd()
    if string.sub(filename, 1, #cwd) == cwd then
      return string.sub(filename, #cwd + 2)
    else
      return filename
    end
  end

  -- 1. Get files already in context
  local info_lines = vim.api.nvim_buf_get_lines(chat_windows.info.buf, 0, -1, false)

  local files_in_context = {}
  for _, v in ipairs(info_lines) do
    if v ~= "" then
      table.insert(files_in_context, v)
    end
  end

  -- 2. Add the buffers in context
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buffer) then
      local filename = vim.api.nvim_buf_get_name(buffer)
      -- Only add buffers files (ChatInput, ChatOutput ... have a `nofile` type, we skip those)
      if filename ~= "" and vim.bo[buffer].buftype == "" then
        local relative_filename = _get_relative_path(filename)
        table.insert(files_in_context, relative_filename)
      end
    end
  end

  -- 3. Ensures no duplicates
  local clean_files_in_context = utils.remove_duplicates(files_in_context)

  vim.api.nvim_buf_set_lines(chat_windows.info.buf, 0, -1, false, clean_files_in_context)
end

---@param config Config
function M.setup(config)
  -- create windows reset chat history, but only for a given provider
  local chat_windows = windows.create_windows(config)
  session.initialize_session(chat_windows.output.buf, config)

  --
  -- Setup Keymaps
  --

  -- Set up global toggle keymap
  vim.keymap.set("n", "<leader>zt", function()
    windows.toggle_windows(config) -- Pass config to toggle_windows
  end, { desc = "Toggle chat windows" })

  -- Focus input window
  vim.keymap.set("n", "<Leader>zf", function()
    vim.api.nvim_set_current_win(windows.windows.input.win)
  end, { desc = "Focus input window" })

  -- Setup keymaps for all windows
  local callbacks = {
    cycle = windows.cycle_windows,
    close = windows.close_windows,
    add_file_to_context = function()
      files_picker.pick_files(config)
    end,
    add_buffers_to_context = function()
      add_buffers_to_context(chat_windows)
    end,
    focus_input_window = function()
      vim.api.nvim_set_current_win(windows.windows.input.win)
    end,
  }

  for _, handles in pairs(chat_windows) do
    keymaps.setup_buffer_keymaps(handles.buf, callbacks)
  end

  -- Add send callback for input buffer
  keymaps.setup_buffer_keymaps(
    chat_windows.input.buf,
    vim.tbl_extend("force", callbacks, {
      send = function()
        send_input(config)
      end,
    })
  )

  -- Focus input window
  vim.cmd("wincmd j")
end

return M
