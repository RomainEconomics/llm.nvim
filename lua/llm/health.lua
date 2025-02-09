local M = {}

local function check_openai()
  if vim.env.OPENAI_API_KEY then
    vim.health.ok("OpenAI API key found")
  else
    vim.health.error("OpenAI API key not found. Set OPENAI_API_KEY environment variable")
  end
end

local function check_anthropic()
  if vim.env.ANTHROPIC_API_KEY then
    vim.health.ok("Anthropic API key found")
  else
    vim.health.error("Anthropic API key not found. Set ANTHROPIC_API_KEY environment variable")
  end
end

M.check = function()
  vim.health.start("LLM Plugin")
  check_openai()
  check_anthropic()
end

return M
