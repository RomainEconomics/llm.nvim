# LLM Nvim Plugin

## Usage

```lua
-- Examples
vim.keymap.set({'n', 'v'}, '<leader>zz', function() require('llm').llm_with_picker() end, { desc = 'Start LLM Chat' })
-- or
vim.keymap.set({'n', 'v'}, '<leader>zz', function() require('llm').llm() end, { desc = 'Start LLM Chat' })

vim.keymap.set("n", "<leader>zh", function() require("llm").llm_with_history() end, { desc = "Start LLM Chat" })

```

## TODOs

### Prompts

- [ ] add custom prompt and ability to switch
  - system prompts + simple prompts
- [ ] have a project context (where to store it ? `PROJECT CONTEXT: `)
  - [ ] be able to provide the tree structure of a project, without the content
        itself (`tree --no-user --no-filesize --no-time --no-permissions --no-git -L 4`)

### Git Diffs

- [ ] implement git diff

### History

- [x] be able to persist the last chat between neovim sessions (should be able
      to quit nvim, restart and have access again to the chat)
- [x] have chats stored in files (`\chat_storage\{year-month-day}\{datetime}\chat.json`)
- [x] can resume chat from history
- [ ] improve history picker
  - [ ] datetime should appears as only uuid appears at the moment (not really
        readable)
  - [ ] possibility to switch mode and use grep in file_history picker
        the moment

### LLM Providers

- [x] add gemini support
- [ ] ollama or other providers (vllm etc...)

### Multi Models

- [ ] add function to start multi model prompt request -> same prompt send to
      many models - [ ] to create tabs or hidden buffers, should use snacks.win /
      snacks.layout insteaf
- [ ] add a tab for the output tab

### UI

- [x] toggle on and off the chat
  - [x] if not satisfied with current solution, instead, could recreate the windows
        from scratch, but using the current inputs/outputs/infos stored in each
        buf/windows -> way easier solution
    - this may avoid the painful issue of having to deal with splits and
      everything else

### Keymaps

- [x] start chat from visual selection
- [x] add focus input keymap
- [x] create global keymaps
- [ ] file context:
  - [x] when adding a file to context, the cursor move to the main window (left one)
        instead of the input window. annoying
  - [x] add all buffers to prompt
  - [x] add files from a directory to the context

### Others

- [ ] add url as a context (llm.txt or html to md ? for documentation pages for
      ex)
- [ ] add rag support ? could use weaviate I guess
- [ ] count the number of tokens
- [ ] support passing images
- [ ] Checks what happen when api key invalid for each provider (at the moment
      it may silently fail)
- [x] when tokens are being streamed, the cursor is forced to be at the bottom
      of the output panel. (see: `lua/avante/sidebar.lua`)
