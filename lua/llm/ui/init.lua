local chat = require("llm.chat")
local files_context = require("llm.context.files")
local input_processor = require("llm.input.processor")
local keymaps = require("llm.ui.keymaps")
local session = require("llm.session")
local windows = require("llm.ui.windows")
local history = require("llm.history")
local cache = require("llm.cache")
local gemini = require("llm.providers.gemini")

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
  vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, { "" })

  -- Add files in context (if any)
  local info_buf = windows.windows.info.buf
  local files_content_in_context = files_context.get_files_context(info_buf)

  -- Call API provider
  local promise = chat.call_llm(input_text, config, files_content_in_context)

  -- Create a timer to check for last stream message completion (once it happens, we save chat and cache)
  local timer = vim.uv.new_timer()
  timer:start(
    100,
    100,
    vim.schedule_wrap(function()
      if promise.done then
        timer:stop()
        -- Save chat history
        local filepath = history.save_chat(config, promise.messages)
        -- Cache last history file for a given project
        cache.save_cache({ history_path = filepath, cwd = vim.fn.getcwd(), model = config.model }, config)
      end
    end)
  )

  vim.api.nvim_buf_set_lines(output_buf, -1, -1, false, { "" })

  -- Clear user input
  vim.api.nvim_buf_set_lines(handles.buf, 0, -1, false, { "" })
end

---@param config Config
---@param messages? table Past messages used when resuming chat
function M.setup(config, messages)
  -- create windows reset chat history, but only for a given provider
  local chat_windows = windows.create_windows(config)
  session.initialize_session(chat_windows.output.buf, config)

  require("llm.ui.buffer_updates").setup_scroll_keymaps(chat_windows.output)

  if messages ~= nil then
    -- local formatted_msg = {}

    -- Gemini models uses contents keys, others do not
    local data = messages.contents or messages

    for _, v in ipairs(data) do
      if v.role == "system" then
      elseif v.role == "user" then
        local content = v.content or gemini.handle_gemini_content(v.parts)
        local lines, _ = input_processor.process_input(vim.split(content, "\n"))
        vim.api.nvim_buf_set_lines(chat_windows.output.buf, -1, -1, false, lines)
        vim.api.nvim_buf_set_lines(chat_windows.output.buf, -1, -1, false, { "" })
      else
        local content = v.content or gemini.handle_gemini_content(v.parts)
        vim.api.nvim_buf_set_lines(chat_windows.output.buf, -1, -1, false, vim.split(content, "\n"))
      end
    end
  end

  --
  -- Setup Keymaps
  --

  -- Set up global toggle keymap
  keymaps.global_keymaps(config)

  -- Setup keymaps for all windows
  keymaps.buffer_keymaps(config, chat_windows, send_input)

  -- Focus input window
  vim.cmd("wincmd j")
end

return M
