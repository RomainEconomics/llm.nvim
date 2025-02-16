local buf_updates = require("llm.ui.buffer_updates")
local curl = require("plenary.curl")

---@class OpenAI : Provider -- Declare OpenAI as a subclass of Provider
local OpenAI = {}
setmetatable(OpenAI, { __index = require("llm.providers.base").Provider })

local M = {}

---@return OpenAI
function M.new()
  local instance = setmetatable({}, { __index = OpenAI })
  return instance
end

---Call OpenAI API chat
---@param content string
---@param config Config
---@param files_context string?
---@return string
function OpenAI:call(content, config, files_context)
  local accumulated_message = ""

  self.messages = self:build_messages("user", content, config.system_prompt)
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

  curl.post("https://api.openai.com/v1/chat/completions", {
    raw = { "--no-buffer", "--silent", "--show-error" },
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. vim.env.OPENAI_API_KEY,
    },
    body = vim.fn.json_encode({
      model = config.model,
      messages = copy_messages,
      stream = true,
    }),
    stream = function(_, chunk)
      if not chunk or chunk == "" then
        return
      end

      if chunk == "data: [DONE]" then
        self.messages = self:build_messages("assistant", accumulated_message)
        return
      end

      local json_string = string.gsub(chunk, "^data: ", "")
      local success, data = pcall(vim.json.decode, json_string)
      if not success then
        return
      end

      local msg = data.choices[1].delta.content
      if not msg then
        return
      end

      accumulated_message = accumulated_message .. msg
      buf_updates.update_output_buffer(msg)
    end,
  })

  return accumulated_message
end

return M
