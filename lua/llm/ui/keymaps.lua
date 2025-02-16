local M = {}

function M.setup_buffer_keymaps(buf, callbacks)
  -- Navigation keymaps
  vim.keymap.set("n", "<Tab>", function()
    callbacks.cycle("forward")
  end, { buffer = buf, desc = "Cycle to next chat window" })

  vim.keymap.set("n", "<S-Tab>", function()
    callbacks.cycle("backward")
  end, { buffer = buf, desc = "Cycle to previous chat window" })

  -- Close windows keymap
  vim.keymap.set("n", "<Leader>q", callbacks.close, { buffer = buf, desc = "Close chat windows" })

  -- Add File to context
  vim.keymap.set("n", "<leader>za", callbacks.add_file_to_context, { buffer = buf, desc = "Add File to context" })

  -- Add all open buffers to context
  vim.keymap.set(
    "n",
    "<leader>zb",
    callbacks.add_buffers_to_context,
    { buffer = buf, desc = "Add Open Buffers to context" }
  )

  -- Send message keymap (only for input buffer)
  if callbacks.send then
    vim.keymap.set("n", "<CR>", callbacks.send, { buffer = buf, desc = "Send chat message" })
  end
end

return M
