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
- [x] llm providers
  - [x] add gemini support
- [x] toggle on and off the chat
  - [x] if not satisfied with current solution, instead, could recreate the windows
        from scratch, but using the current inputs/outputs/infos stored in each
        buf/windows -> way easier solution
    - this may avoid the painful issue of having to deal with splits and
      everything else
- [ ] keymaps:
  - add focus input keymap
  - create global keymaps
- [ ] file context:
  - [x] when adding a file to context, the cursor move to the main window (left one)
        instead of the input window. annoying
  - [ ] add all buffers to prompt
  - [ ] add files from a directory to the context
- [ ] count the number of tokens
- [ ] support passing images
- [ ] Checks what happen when api key invalid for each provider (at the moment
      it may silently fail)
