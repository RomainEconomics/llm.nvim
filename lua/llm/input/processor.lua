local M = {}

function M.process_input(input_lines)
  local formatted_lines = {}
  for _, line in ipairs(input_lines) do
    table.insert(formatted_lines, "> " .. line)
  end

  table.insert(formatted_lines, 1, "")
  table.insert(formatted_lines, "")

  return formatted_lines, table.concat(input_lines, "\n")
end

return M
