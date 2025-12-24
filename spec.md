# droid.nvim Implementation Spec

## Overview

droid.nvim is a Neovim plugin that integrates Factory AI (Droid) with Neovim, adapted from the opencode.nvim reference implementation.

## Key Differences from opencode.nvim

1. **No HTTP Server API**: Unlike opencode which exposes HTTP endpoints, Droid is a pure terminal application
2. **Terminal I/O**: Communication happens via terminal stdin/stdout
3. **Simplified Architecture**: No SSE events, no permission system, no server discovery

## Architecture

```
lua/droid.lua                 # Main API entry point
lua/droid/
├── config.lua               # Configuration management
├── promise.lua              # Async promise implementation
├── context.lua              # Editor context capture
├── events.lua               # File watching & buffer reload
├── status.lua               # Statusline component
├── health.lua               # Health check
├── api/
│   ├── prompt.lua           # Prompt sending
│   └── operator.lua         # Vim operator support
├── provider/
│   ├── init.lua             # Provider interface
│   ├── terminal.lua         # Native Neovim terminal
│   └── snacks.lua           # snacks.nvim terminal
├── ui/
│   ├── ask.lua              # Input prompt UI
│   └── select.lua           # Selection picker UI
└── cmp/
    └── blink.lua            # blink.cmp integration
```

## Features Implemented

- [x] Toggle droid terminal
- [x] Input prompts with context completion
- [x] Select from predefined prompts
- [x] Context injection (@this, @buffer, @diagnostics, etc.)
- [x] Auto-reload buffers on file changes
- [x] Statusline component
- [x] Vim operator support
- [x] snacks.nvim integration (optional)
- [x] blink.cmp integration (optional)
- [x] Health check

## Usage Example

```lua
-- Toggle droid
require("droid").toggle()

-- Ask with context
require("droid").ask("@this: ", { submit = true })

-- Send prompt directly
require("droid").prompt("Explain @diagnostics", { submit = true })

-- Use operator
vim.keymap.set("n", "go", function()
  return require("droid").operator("@this ")
end, { expr = true })
```
