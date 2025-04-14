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

- [ ] ensures providers can use cache
- [ ] add command to end a chat immediately
- [ ] when chat starts, the cursor should go to the chat stream, instead of
      waiting in input window

### Prompts

- [ ] add custom prompt and ability to switch
  - system prompts + simple prompts
- [ ] have a project context (where to store it ? `PROJECT CONTEXT: `)
  - [ ] be able to provide the tree structure of a project, without the content
        itself (`tree --no-user --no-filesize --no-time --no-permissions --no-git -L 4`)

### User Rules / Project rules

`User rules`

```
Ensure the generated code is well organized and modular, with clear separation
of concerns.

Use descriptive variable, function and class names that reflect their purposes.

Include concise, meaningful inline comments dans documentation to explain
non-obvious logic.

Adhere to established coding standards and style guides relevant to the langague
or framework used.

Write code that is maintainable, with proper error handling and clear boundaries
for functionality.

Avoid overly complex or deeply nested structures by favoring simplicity and
clarity.

Optimize for performance and security by following best practices and using
efficient algorithms.

Incorporate unit tests or example test cases to demonstrate and verify
functionality.

Write code that is self-contained with minimal dependencies (or reused already
existing dependencies), to facilitate easy integration into larger projects.

Split code into separate files with meaningful names, and avoid large files with
more that 300 lines of code
```

`Project rules`

`Frontend rules`

```
Use Nextjs with tanstack query and tailwind and shadcn
```

`Backend rules`

```
Use fastapi and sqlalchemy
```

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
