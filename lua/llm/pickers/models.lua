local M = {}

---Select model
---@param config Config
---@param callback function Called with selected model
function M.select_model(config, callback)
  local Snacks = require("snacks")

  Snacks.picker({
    finder = function()
      local items = {}
      for i, item in ipairs(config.available_models) do
        table.insert(items, {
          idx = i,
          file = item,
          text = item,
        })
      end
      return items
    end,
    layout = {
      layout = {
        box = "horizontal",
        width = 0.5,
        height = 0.5,
        {
          box = "vertical",
          border = "rounded",
          title = "Choose your model",
          { win = "input", height = 1, border = "bottom" },
          { win = "list", border = "none" },
        },
      },
    },
    confirm = function(picker, item)
      picker:close()
      Snacks.notifier.notify(item.file, "info", { title = "Model chosen" })
      callback(item.file)
    end,
  })
end

return M
