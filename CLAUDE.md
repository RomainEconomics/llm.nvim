# CLAUDE.md

## Project Overview

**llm.nvim** is a Neovim plugin written in Lua that provides an integrated LLM chat interface directly within the editor. It supports multiple AI providers (Claude, OpenAI, Gemini) with features like chat history, project management, and context-aware conversations.

## Development Commands

### Testing

```bash
make test
```

- Uses Plenary.nvim testing framework
- Runs headless Neovim with minimal init configuration from `tests/minimal_init.lua`

### Key API Functions

- `require('llm').llm()` - Start basic chat
- `require('llm').llm_with_picker()` - Chat with model selection
- `require('llm').llm_with_history()` - Resume from chat history

## Architecture

### Core Structure

- **`lua/llm/`** - Main plugin source with entry point in `init.lua`
- **`lua/llm/providers/`** - LLM provider implementations (Claude, OpenAI, Gemini) with base provider pattern
- **`lua/llm/ui/`** - Window management, keymaps, and real-time buffer updates for streaming
- **`lua/llm/pickers/`** - Selection interfaces for models, history, projects, and files
- **`lua/llm/context/`** - File and buffer context management
- **`lua/llm/utils/`** - Utility functions for selections, files, and UUID generation

### Key Features Architecture

- **Provider Pattern**: Abstracted LLM providers with common interface in `base.lua`
- **Project Management**: Custom prompts and configurations stored per project
- **Chat History**: Persistent sessions stored in `~/.llm_chat_history/{year-month-day}/{datetime}/chat.json`
- **Context Management**: Add files, buffers, directories, and visual selections to chat context
- **Streaming**: Real-time token streaming with cursor auto-scrolling

### Configuration

- Default configuration in `lua/llm/config_defaults.lua`
- Default model: `gpt-4.1-mini`
- Available models include Claude Sonnet 4, GPT-4.1, Gemini 2.5 Pro
- System prompt emphasizes concise, well-typed code with modern practices

### Default Keymaps

- `<leader>za` - Add file to context
- `<leader>zb` - Add buffers to context
- `<leader>zd` - Add directory to context
- `<leader>zt` - Toggle chat windows
- `<leader>zf` - Focus window
- `<leader>zc` - Clear chat
- `<leader>zm` - Switch model
- `<leader>zP` - Select project
- `<leader>zN` - Create project
- `<leader>zu` - Update project

## Coding Standards (from README)

When contributing code, follow these established patterns:

- Well organized and modular code with clear separation of concerns
- Descriptive variable, function and class names
- Concise, meaningful inline comments for non-obvious logic
- Proper error handling with clear functionality boundaries
- Avoid overly complex or deeply nested structures
- Split code into separate files with meaningful names (avoid >300 line files)
- Minimal dependencies, reuse existing ones when possible

