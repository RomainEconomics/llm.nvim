# llm.nvim

A powerful Neovim plugin that brings AI chat capabilities directly into your editor. Chat with Claude, GPT, and Gemini models without leaving your development environment.

## Features

- **Multiple AI Providers**: Claude, OpenAI GPT, and Google Gemini support
- **Context-Aware Chats**: Add files, buffers, directories, and visual selections to conversations
- **Persistent Chat History**: Resume conversations across Neovim sessions
- **Project Management**: Custom prompts and configurations per project
- **Real-time Streaming**: Live token streaming with auto-scrolling
- **Visual Selection**: Start chats from selected text
- **Integrated Interface**: Chat windows that integrate seamlessly with your workflow

## Installation

### Requirements

- Neovim >= 0.10.0
- curl (for API requests)
- API keys for your chosen providers (see [Configuration](#configuration))

### Using lazy.nvim

```lua
{
  "RomainEconomics/llm.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("llm").setup({
      -- Optional: Override default configuration
      model = "claude-sonnet-4-20250514", -- or "gpt-4.1", "gemini-2.5-pro-preview-06-05"
    })
  end,
}
```

## Configuration

### API Keys

Set your API keys as environment variables:

```bash
# For Claude
export ANTHROPIC_API_KEY="your-anthropic-api-key"

# For OpenAI
export OPENAI_API_KEY="your-openai-api-key"

# For Gemini
export GEMINI_API_KEY="your-gemini-api-key"
```

### Basic Setup

```lua
require("llm").setup({
  model = "claude-sonnet-4-20250514", -- Default model
  max_tokens = 12192,
  system_prompt = "You're a professional programmer...", -- Custom system prompt
  window_sizes = {
    output = 15,  -- Output window height
    input = -2,   -- Input window height (negative means from bottom)
  },
})
```

### Available Models

- **Claude**: `claude-sonnet-4-20250514`, `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022`
- **OpenAI**: `gpt-4.1`, `gpt-4.1-mini`, `o4-mini`
- **Gemini**: `gemini-2.5-pro-preview-06-05`, `gemini-2.5-flash-preview-04-17`

## Usage

### Basic Keymaps

Add these to your configuration:

```lua
-- Start chat with model picker
vim.keymap.set({'n', 'v'}, '<leader>zz', function() require('llm').llm_with_picker() end, { desc = 'Start LLM Chat' })

-- Start chat with default model
vim.keymap.set({'n', 'v'}, '<leader>zl', function() require('llm').llm() end, { desc = 'Start LLM Chat' })

-- Resume from chat history
vim.keymap.set('n', '<leader>zh', function() require('llm').llm_with_history() end, { desc = 'Resume Chat History' })
```

### Default Keymaps (Active in Chat)

| Keymap       | Action                         |
| ------------ | ------------------------------ |
| `<leader>za` | Add file to context            |
| `<leader>zb` | Add all buffers to context     |
| `<leader>zd` | Add directory to context       |
| `<leader>zt` | Toggle chat windows            |
| `<leader>zf` | Focus input window             |
| `<leader>zc` | Clear current chat             |
| `<leader>zm` | Switch model                   |
| `<leader>zP` | Select project                 |
| `<leader>zN` | Create new project             |
| `<leader>zu` | Update current project         |
| `<Tab>`      | Cycle forward through windows  |
| `<S-Tab>`    | Cycle backward through windows |
| `<Leader>q`  | Close chat windows             |
| `<CR>`       | Send message                   |

### Workflow Examples

#### Start a Chat from Visual Selection

1. Select text in visual mode
2. Press `<leader>zz` to start chat with the selection as context

#### Add Context to Your Chat

1. In chat mode, press `<leader>za` to add current file
2. Press `<leader>zd` to add an entire directory
3. Press `<leader>zb` to add all open buffers

#### Resume Previous Conversations

1. Press `<leader>zh` to open chat history picker
2. Select a previous conversation to resume

#### Project-Specific Prompts

1. Press `<leader>zN` to create a new project configuration
2. Define custom prompts and settings for your project
3. Press `<leader>zP` to switch between projects

## Advanced Configuration

### Custom Window Layout

```lua
require("llm").setup({
  window_sizes = {
    output = 20,    -- Larger output window
    info = 5,       -- Show info window
    input = -3,     -- Taller input window
  },
  filetype = "markdown", -- Set filetype for syntax highlighting
})
```

### Custom Keymaps

```lua
require("llm").setup({
  keys = {
    add_file_to_context = "<leader>af",
    toggle_windows = "<leader>tt",
    switch_model = "<leader>sm",
    -- ... customize other keymaps
  },
})
```

### Custom System Prompt

```lua
require("llm").setup({
  system_prompt = [[
You are an expert software engineer. Focus on:
- Clean, maintainable code
- Proper error handling
- Security best practices
- Performance optimization
]],
})
```

## Chat History and Projects

Chat history is automatically saved to `~/.llm_chat_history/` organized by projects. Each project has its own directory with date-based chat organization:

```
~/.llm_chat_history/
├── default/                    # Default project
│   ├── project_config.json     # Project configuration
│   ├── 2024-01-15/            # Date-based folders
│   │   ├── chat_abc123.json   # Individual chat files (UUID-based)
│   │   └── chat_def456.json
│   └── 2024-01-16/
│       └── chat_ghi789.json
├── my_web_project/            # Custom project (sanitized name)
│   ├── project_config.json
│   ├── 2024-01-15/
│   │   └── chat_xyz890.json
│   └── 2024-01-16/
│       └── chat_abc123.json
└── machine_learning/          # Another project
    ├── project_config.json
    └── 2024-01-15/
        └── chat_def456.json
```

**Note**: Project names are automatically sanitized (lowercase, spaces become underscores) when creating directories.

## Development

### Running Tests

```bash
make test
```

### Project Structure

- `lua/llm/` - Main plugin source code
- `lua/llm/providers/` - AI provider implementations
- `lua/llm/ui/` - User interface components
- `lua/llm/pickers/` - Selection interfaces
- `lua/llm/context/` - Context management
- `tests/` - Test suite

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the coding standards
4. Run tests with `make test`
5. Submit a pull request

### Coding Standards

- Well organized and modular code with clear separation of concerns
- Descriptive variable, function and class names
- Concise, meaningful inline comments for non-obvious logic
- Proper error handling with clear functionality boundaries
- Avoid overly complex or deeply nested structures
- Split code into separate files with meaningful names (avoid >300 line files)
- Minimal dependencies, reuse existing ones when possible

## Troubleshooting

### Common Issues

**API Key Not Found**

- Ensure environment variables are set correctly
- Restart Neovim after setting environment variables

**Model Not Available**

- Check if your API key has access to the requested model
- Try switching to a different model with `<leader>zm`

**Windows Not Appearing**

- Check for conflicts with other plugins
- Try toggling windows with `<leader>zt`

## License

MIT License - see LICENSE file for details

