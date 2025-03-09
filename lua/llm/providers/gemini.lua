local buf_updates = require("llm.ui.buffer_updates")
local curl = require("plenary.curl")

---@class Gemini : Provider -- Declare Gemini as a subclass of Provider
local Gemini = {}
setmetatable(Gemini, { __index = require("llm.providers.base").Provider })

local M = {}

---@return Gemini
function M.new()
  local instance = setmetatable({}, { __index = Gemini })
  return instance
end

---Call Gemini API chat
---@param content string
---@param config Config
---@param callback function
---@param files_context string?
---@return string
function Gemini:call(content, config, callback, files_context)
  local accumulated_message = ""

  self.messages = self:build_messages("user", content, config.system_prompt)
  local messages = vim.deepcopy(self.messages)

  -- Add files context if present
  -- We copy the message and don't store the files_context to allow the files in context to be changed
  -- between chat messages (could be same files but with changes made in it)
  if files_context ~= nil then
    table.insert(messages.contents, {
      role = "user",
      parts = {
        {
          text = files_context,
        },
      },
    })
  end

  curl.post(
    "https://generativelanguage.googleapis.com/v1beta/models/"
      .. config.model
      .. ":streamGenerateContent?alt=sse&key="
      .. vim.env.GEMINI_API_KEY,
    {
      raw = { "--no-buffer", "--silent", "--show-error" },
      headers = {
        ["Content-Type"] = "application/json",
      },
      body = vim.fn.json_encode({
        system_instruction = messages.system_instruction,
        contents = messages.contents,
      }),
      stream = function(_, chunk)
        if not chunk or chunk == "" then
          return
        end

        local json_string = string.gsub(chunk, "^data: ", "")
        local success, data = pcall(vim.json.decode, json_string)
        if not success then
          return
        end

        local finished = data.candidates[1].finishReason
        local msg = data.candidates[1].content.parts[1].text

        accumulated_message = accumulated_message .. msg

        buf_updates.update_output_buffer(msg)

        if finished == "STOP" then
          local metadata = data.usageMetadata

          -- We add model response to the `self.messages` and not the copy
          self.messages = self:build_messages("assistant", accumulated_message)

          Snacks.notifier.notify(
            "Input tokens: "
              .. metadata.promptTokenCount
              .. " | Output tokens: "
              .. metadata.candidatesTokenCount
              .. " | Total token: "
              .. metadata.totalTokenCount,
            "info",
            { title = "Token usage" }
          )

          callback()
          return
        end
      end,
    }
  )

  return accumulated_message
end

---Builds messages for the Gemini API
---@param role Role
---@param content string
---@param system_prompt string?
---@return table
function Gemini:build_messages(role, content, system_prompt)
  -- Initialize messages if nil
  if self.messages == nil then
    self.messages = {}
  end

  -- Handle system instruction
  if system_prompt ~= nil then
    self.messages.system_instruction = {
      parts = {
        text = system_prompt,
      },
    }
  end

  -- Initialize contents array
  local contents = {}
  if self.messages.contents ~= nil then
    contents = self.messages.contents
  end

  -- Add new message
  table.insert(contents, {
    role = role == "assistant" and "model" or role, -- Gemini uses "model" instead of "assistant"
    parts = {
      {
        text = content,
      },
    },
  })

  self.messages.contents = contents

  return self.messages
end

---Handle Gemini conversation formatting
---@param parts table
---@return string
function M.handle_gemini_content(parts)
  local s = ""
  for _, p in ipairs(parts) do
    s = s .. p.text .. "\n"
  end
  return s
end

return M
