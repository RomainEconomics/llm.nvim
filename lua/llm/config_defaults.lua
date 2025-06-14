return {
  model = "gpt-4.1-mini",
  available_models = {
    "claude-sonnet-4-20250514",
    "claude-3-7-sonnet-20250219",
    "claude-3-5-haiku-20241022",
    -- "claude-3-5-sonnet-20241022",
    "gpt-4.1",
    "gpt-4.1-mini",
    "o4-mini",
    "gemini-2.5-pro-preview-06-05",
    "gemini-2.5-flash-preview-04-17",
  },
  system_prompt = "You're a professional programmer. You should prefer short, concise and precise answers. When writing codes, add proper typing when the language allows it. Prefer answering using markdowm formatting. If you're requested to use Python, target python 3.11+ and use types where necessary. When using types for python, avoid writing 'Optional' and use the '|' operator instead as it is more modern. When answering, you don't need to send back the provided context if you don't modify it. For exemple, if the functions and classes within a file are too long, you can simply define theirs names and modify only the needed parts.",
  max_tokens = 12192,
  window_sizes = {
    output = 15,
    info = nil,
    input = -2,
  },
  filetype = "markdown",
  chat_history_dir = vim.fn.expand("$HOME/.llm_chat_history"),
  cache_dir = vim.fn.stdpath("cache") .. "/llm_nvim",
  keys = {
    cycle_forward = "<Tab>",
    cycle_backward = "<S-Tab>",
    close_windows = "<Leader>q",
    add_file_to_context = "<leader>za",
    add_buffers_to_context = "<leader>zb",
    add_dir_to_context = "<leader>zd",
    toggle_windows = "<leader>zt",
    focus_window = "<Leader>zf",
    send_input = "<CR>",
    clear_chat = "<leader>zc",
    switch_model = "<leader>zm",
    -- Project management keymaps
    select_project = "<leader>zP",
    create_project = "<leader>zN",
    update_project = "<leader>zu",
  },
}
