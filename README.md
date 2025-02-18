# LLM Nvim Plugin

## Usage

```lua
-- Examples
vim.keymap.set('n', '<leader>zz', function() require('llm').llm_with_picker() end, { desc = 'Start LLM Chat' })
-- or
vim.keymap.set('n', '<leader>zz', function() require('llm').llm() end, { desc = 'Start LLM Chat' })
```

## TODOs

- [ ] add custom prompt and ability to switch
  - system prompts + simple prompts
- [ ] start chat from visual selection
- [ ] history
  - [ ] be able to persist the last chat between neovim sessions (should be able
        to quit nvim, restart and have access again to the chat)
  - [ ] have chats stored in files (`\chat_storage\{year-month-day}\{datetime}\chat.json`)
- [x] llm providers
  - [x] add gemini support
- [ ] Multi models
  - [ ] add function to start multi model prompt request -> same prompt send to
        many models
  - [ ] add a tab for the output tab
- [x] toggle on and off the chat
  - [x] if not satisfied with current solution, instead, could recreate the windows
        from scratch, but using the current inputs/outputs/infos stored in each
        buf/windows -> way easier solution
    - this may avoid the painful issue of having to deal with splits and
      everything else
- [ ] keymaps:
  - [x] add focus input keymap
  - [ ] create global keymaps
- [ ] file context:
  - [x] when adding a file to context, the cursor move to the main window (left one)
        instead of the input window. annoying
  - [x] add all buffers to prompt
  - [ ] add files from a directory to the context
- [ ] count the number of tokens
- [ ] support passing images
- [ ] Checks what happen when api key invalid for each provider (at the moment
      it may silently fail)
