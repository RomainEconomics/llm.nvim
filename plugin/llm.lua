vim.opt.runtimepath:append("~/Documents/repos/llm.nvim")
-- require("llm").llm({
--   model = "claude-3-5-haiku-20241022",
--   -- window_sizes = {
--   --   info = 3, -- height of info window
--   -- },
-- })
require("llm").llm_with_picker()
