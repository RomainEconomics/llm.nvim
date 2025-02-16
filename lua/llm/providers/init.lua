local M = {}

M.get_provider = function(model)
  if string.find(model, "claude") then
    return require("llm.providers.claude"):new()
  elseif string.find(model, "gemini") then
    return require("llm.providers.gemini"):new()
  elseif string.find(model, "gpt") or string.find(model, "o-") then
    return require("llm.providers.openai"):new()
  else
    error("Model " .. model .. " not supported")
  end
end

return M
