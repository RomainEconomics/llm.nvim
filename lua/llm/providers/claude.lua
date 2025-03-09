local buf_updates = require("llm.ui.buffer_updates")
local curl = require("plenary.curl")

---@class Claude : Provider -- Declare Claude as a subclass of Provider
local Claude = {}
setmetatable(Claude, { __index = require("llm.providers.base").Provider })

local M = {}

---@return Claude
function M.new()
  local instance = setmetatable({}, { __index = Claude })
  return instance
end

---Call Anthropic API chat
---@param content string
---@param config Config
---@param callback function
---@param files_context string?
---@return string
function Claude:call(content, config, callback, files_context)
  local accumulated_message = ""

  -- No system prompt with claude models. Instead passed through the request itself
  self.messages = self:build_messages("user", content, nil)
  local copy_messages = vim.deepcopy(self.messages)

  -- Add files context if present
  -- We copy the message and don't store the files_context to allow the files in context to be changed
  -- between chat messages (could be same files but with changes made in it)
  if files_context ~= nil then
    table.insert(copy_messages, {
      role = "user",
      content = files_context,
    })
  end

  local token_usage = { input_tokens = nil, output_tokens = nil }

  curl.post("https://api.anthropic.com/v1/messages", {
    raw = { "--no-buffer", "--silent", "--show-error" },
    headers = {
      ["Content-Type"] = "application/json",
      ["anthropic-version"] = "2023-06-01",
      ["x-api-key"] = vim.env.ANTHROPIC_API_KEY,
    },
    body = vim.fn.json_encode({
      model = config.model,
      messages = copy_messages,
      max_tokens = config.max_tokens,
      stream = true,
    }),
    system = config.system_prompt,
    stream = function(_, chunk)
      if not chunk or chunk == "" then
        return
      end

      local json_string = string.gsub(chunk, "^data: ", "")
      local success, data = pcall(vim.json.decode, json_string)
      if not success then
        return
      end

      local type = data["type"]

      if type == "content_block_start" or type == "ping" or type == "content_block_stop" then
        return
      elseif type == "message_start" then
        token_usage.input_tokens = data.message.usage.input_tokens
        return
      elseif type == "message_delta" then
        token_usage.output_tokens = data.usage.output_tokens
        return
      elseif type == "error" then
        Snacks.debug(data)
        return
      elseif type == "message_stop" then
        self.messages = self:build_messages("assistant", accumulated_message)
        Snacks.notifier.notify(
          "Input tokens: "
            .. token_usage.input_tokens
            .. " | Output tokens: "
            .. token_usage.output_tokens
            .. " | Total tokens: "
            .. token_usage.input_tokens + token_usage.output_tokens,
          "info",
          { title = "Token usage" }
        )

        callback()
        return
      end

      local msg = data.delta.text

      if msg == nil then
        return
      end

      accumulated_message = accumulated_message .. msg
      buf_updates.update_output_buffer(msg)
    end,
  })

  return accumulated_message
end

return M
