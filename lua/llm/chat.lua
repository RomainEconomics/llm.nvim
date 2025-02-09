---@module "snacks"

local curl = require("plenary.curl")

local M = {}

M.messages = nil

---@enum (key) Role
local _role = {
  user = 1,
  assistant = 2,
}

---Call LLM api provider
---@param role Role -- TODO: should be enum or smt
---@param content string
---@param system_prompt string?
---@param files_context string?
---@return table
local function build_messages(role, content, system_prompt, files_context)
  local messages = M.messages

  if messages == nil then
    -- claude doesn't allow system promts in messages, but instead in the http request
    if system_prompt ~= nil then
      messages = {
        {
          role = "system",
          content = system_prompt,
        },
      }
    else
      messages = {}
    end
  end

  if files_context ~= nil then
    table.insert(messages, {
      role = "user",
      content = files_context,
    })
  end

  table.insert(messages, {
    role = role,
    content = content,
  })

  return messages
end

---Call OpenAI API chat
---@param content string
---@param on_chunk function
---@param config Config
---@param files_context string?
---@return string
function M.call_openai(content, on_chunk, config, files_context)
  local accumulated_message = ""

  M.messages = build_messages("user", content, config.system_prompt, files_context)

  curl.post("https://api.openai.com/v1/chat/completions", {
    raw = { "--no-buffer", "--silent", "--show-error" },
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Bearer " .. vim.env.OPENAI_API_KEY,
    },
    body = vim.fn.json_encode({
      model = config.model,
      messages = M.messages,
      stream = true,
    }),
    stream = function(_, chunk)
      if not chunk or chunk == "" then
        return
      end

      if chunk == "data: [DONE]" then
        M.messages = build_messages("assistant", accumulated_message)
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
      if on_chunk then
        on_chunk(msg)
      end
    end,
  })

  return accumulated_message
end

---Call Anthropic API chat
---@param content string
---@param on_chunk function
---@param config Config
---@param files_context string?
---@return string
function M.call_claude(content, on_chunk, config, files_context)
  local accumulated_message = ""

  -- No system prompt with claude models. Instead passed through the request itself
  M.messages = build_messages("user", content, nil, files_context)

  Snacks.notifier.notify("Start calling claude", "info")

  curl.post("https://api.anthropic.com/v1/messages", {
    raw = { "--no-buffer", "--silent", "--show-error" },
    headers = {
      ["Content-Type"] = "application/json",
      ["anthropic-version"] = "2023-06-01",
      ["x-api-key"] = vim.env.ANTHROPIC_API_KEY,
    },
    body = vim.fn.json_encode({
      model = config.model,
      messages = M.messages,
      max_tokens = 4096,
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
      if
        type == "message_start" -- can be used to get input tokens
        or type == "content_block_start"
        or type == "ping"
        or type == "content_block_stop"
        or type == "message_delta" -- can be used to get output tokens
      then
        return
      elseif type == "error" then
        Snacks.debug(data)
        return
      elseif type == "message_stop" then
        M.messages = build_messages("assistant", accumulated_message)
        return
      end

      local msg = data.delta.text
      -- Snacks.debug(data, "msg", msg)

      if msg == nil then
        return
      end

      accumulated_message = accumulated_message .. msg
      if on_chunk then
        on_chunk(msg)
      end
    end,
  })

  Snacks.notifier.notify("Finish calling claude", "info")

  return accumulated_message
end

---Call LLM api provider
---@param content string
---@param on_chunk function
---@param config Config
---@param files_context string?
function M.call_llm(content, on_chunk, config, files_context)
  Snacks.notifier.notify("Model user: " .. config.model, "info", { title = "Model used" })
  if string.find(config.model, "claude") then
    M.call_claude(content, on_chunk, config, files_context)
  elseif string.find(config.model, "gpt") then
    M.call_openai(content, on_chunk, config, files_context)
  else
    error("Model not handled currently")
  end
end

return M
