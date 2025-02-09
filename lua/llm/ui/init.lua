local windows = require("llm.ui.windows")
local keymaps = require("llm.ui.keymaps")
local chat = require("llm.chat")
local files_picker = require("llm.pickers.files")

local M = {}

local function update_output_buffer(msg)
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

    -- Scroll to bottom
    if vim.api.nvim_win_is_valid(handles.win) then
      vim.api.nvim_win_set_cursor(handles.win, { vim.api.nvim_buf_line_count(handles.buf), 0 })
    end
  end)
end

---Send input
---@param config Config
local function send_input(config)
  local handles = windows.windows.input
  if not handles or not vim.api.nvim_buf_is_valid(handles.buf) then
    return
  end

  local input_lines = vim.api.nvim_buf_get_lines(handles.buf, 0, -1, false)
  local input_text = table.concat(input_lines, "\n")

  for idx, v in ipairs(input_lines) do
    input_lines[idx] = "> " .. v
  end

  table.insert(input_lines, 1, "")
  table.insert(input_lines, "")

  -- Add user input to output
  local output_buf = windows.windows.output.buf
  vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, input_lines)

  -- Add files in context
  local info_buf = windows.windows.info.buf
  local filepath_in_context = vim.api.nvim_buf_get_lines(info_buf, 0, -1, false)

  Snacks.debug("Filepath", filepath_in_context)

  local files_content_in_context = nil
  local files_context = {}
  if #filepath_in_context >= 1 and filepath_in_context[1] ~= "" then
    table.insert(
      files_context,
      "To help answer the user requests, you're provided context from files located in the local project of the user. Use this context when you think it is useful to answer the user requests."
    )
    for _, filepath in ipairs(filepath_in_context) do
      Snacks.debug("Reading file:", filepath)
      local lines = vim.fn.readfile(filepath)
      local s = table.concat(lines, "\n")
      table.insert(files_context, filepath .. "\n" .. s)
    end
    files_content_in_context = table.concat(files_context, "\n\n")
  end

  Snacks.debug(files_content_in_context)

  -- Call API
  chat.call_llm(input_text, update_output_buffer, config, files_content_in_context)
  vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, { "" })

  -- Clear input
  vim.api.nvim_buf_set_lines(handles.buf, 0, -1, false, { "" })
end

---@param config Config
function M.setup(config)
  local chat_windows = windows.create_windows(config)

  -- Initialize output buffer with header
  local current_date = os.date("%Y-%m-%d %H:%M:%S")
  vim.api.nvim_buf_set_lines(chat_windows.output.buf, 0, -1, false, {
    "# Chat Session",
    "",
    "- Date: " .. current_date,
    "- Model: " .. config.model,
    "",
    "---",
    "",
  })

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
