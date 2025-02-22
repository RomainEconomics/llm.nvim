local mini_icons = require("mini.icons")

local M = {}

---Get icon from filepath
---@param filepath string
function M.get_icon(filepath)
  if _G.MiniIcons ~= nil then
    local icon = mini_icons.get("file", filepath)
    icon = icon .. " "
    -- icon, _, _ = MiniIcons.get("filetype", filetype)
    return icon
  else
    return ""
  end
end

return M
