# droid.nvim

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

Integrate [Factory AI (Droid)](https://factory.ai) with Neovim — streamline editor-aware AI assistance for research, reviews, and code generation.

## Features

- Toggle droid terminal with a single keymap
- Input prompts with completions, highlights, and context injection
- Select from a library of prompts and define your own
- Inject editor context (buffer, cursor, selection, diagnostics, git diff)
- Auto-reload buffers when droid modifies files
- Statusline component for droid status
- Supports `snacks.nvim` for enhanced UI (optional)
- Vim-y — supports ranges and dot-repeat via operators

## Setup

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "fahmiauliarahman/droid.nvim",
  dependencies = {
    -- Optional but recommended for enhanced UI
    { "folke/snacks.nvim", opts = { input = {}, terminal = {} } },
  },
  config = function()
    ---@type droid.Opts
    vim.g.droid_opts = {
      -- Your configuration here
    }

    -- Required for auto-reload when droid edits files
    vim.o.autoread = true

    -- Recommended keymaps
    vim.keymap.set({ "n", "x" }, "<C-a>", function()
      require("droid").ask("@this: ", { submit = true })
    end, { desc = "Ask Droid" })

    vim.keymap.set({ "n", "x" }, "<C-x>", function()
      require("droid").select()
    end, { desc = "Droid actions" })

    vim.keymap.set({ "n", "t" }, "<C-.>", function()
      require("droid").toggle()
    end, { desc = "Toggle Droid" })

    vim.keymap.set({ "n", "x" }, "go", function()
      return require("droid").operator("@this ")
    end, { expr = true, desc = "Add range to Droid" })

    vim.keymap.set("n", "goo", function()
      return require("droid").operator("@this ") .. "_"
    end, { expr = true, desc = "Add line to Droid" })
  end,
}
```

> **Tip:** Run `:checkhealth droid` after setup to verify everything is configured correctly.

## Configuration

droid.nvim provides sensible defaults. See all options in `lua/droid/config.lua`.

### Contexts

droid.nvim replaces placeholders in prompts with editor context:

| Placeholder    | Context                                       |
| -------------- | --------------------------------------------- |
| `@this`        | Visual selection or cursor position with code |
| `@buffer`      | Current buffer path                           |
| `@buffers`     | All open buffer paths                         |
| `@visible`     | Visible text in all windows                   |
| `@diagnostics` | Current buffer diagnostics                    |
| `@quickfix`    | Quickfix list entries                         |
| `@diff`        | Git diff output                               |
| `@<filepath>`  | Include file contents by relative path        |

### Prompts

Built-in prompts for common tasks:

| Name          | Prompt                                                                 |
| ------------- | ---------------------------------------------------------------------- |
| `diagnostics` | Explain `@diagnostics`                                                 |
| `diff`        | Review the following git diff for correctness and readability: `@diff` |
| `document`    | Add comments documenting `@this`                                       |
| `explain`     | Explain `@this` and its context                                        |
| `fix`         | Fix `@diagnostics`                                                     |
| `implement`   | Implement `@this`                                                      |
| `optimize`    | Optimize `@this` for performance and readability                       |
| `review`      | Review `@this` for correctness and readability                         |
| `test`        | Add tests for `@this`                                                  |

### Custom Prompts

```lua
vim.g.droid_opts = {
  prompts = {
    refactor = {
      prompt = "Refactor @this for better readability and maintainability",
      submit = true,
    },
    security = {
      prompt = "Review @this for security vulnerabilities",
      submit = true,
    },
  },
}
```

### Provider

droid.nvim supports multiple terminal providers:

**Neovim Terminal (default)**

```lua
vim.g.droid_opts = {
  provider = {
    enabled = "terminal",
    terminal = {
      split = "right",  -- "left", "right", "above", "below"
      width = 80,
    },
  },
}
```

**snacks.terminal**

```lua
vim.g.droid_opts = {
  provider = {
    enabled = "snacks",
    snacks = {
      auto_close = false,
      win = {
        position = "right",
      },
    },
  },
}
```

## Usage

### Ask — `require("droid").ask()`

Input a prompt for droid with context completion support.

- Press `<Tab>` to complete context placeholders
- Highlights contexts in the input

### Select — `require("droid").select()`

Select from all droid.nvim functionality including prompts and provider controls.

### Prompt — `require("droid").prompt()`

Send a prompt directly to droid.

```lua
require("droid").prompt("Explain @this", { submit = true })
```

### Operator — `require("droid").operator()`

Use as a Vim operator for range selection, supporting dot-repeat.

```lua
vim.keymap.set("n", "go", function()
  return require("droid").operator("@this ")
end, { expr = true })
```

### Toggle — `require("droid").toggle()`

Toggle the droid terminal window visibility.

## Commands

| Command                | Description                   |
| ---------------------- | ----------------------------- |
| `:Droid`               | Toggle droid terminal         |
| `:Droid toggle`        | Toggle droid terminal         |
| `:Droid start`         | Start droid terminal          |
| `:Droid stop`          | Stop droid terminal           |
| `:Droid ask`           | Open ask prompt               |
| `:Droid ask <text>`    | Open ask with pre-filled text |
| `:Droid select`        | Open selection UI             |
| `:Droid prompt <text>` | Send prompt directly          |

## Statusline

### lualine

```lua
require("lualine").setup({
  sections = {
    lualine_z = {
      require("droid").statusline,
    },
  },
})
```

## Acknowledgments

- Inspired by [opencode.nvim](https://github.com/NickvanDyke/opencode.nvim)
- Built for [Factory AI](https://factory.ai)

## License

MIT
