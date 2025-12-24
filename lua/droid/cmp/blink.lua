---Blink.cmp source for droid context completions.
---
---To use this source, add to your blink.cmp config:
---```lua
---sources = {
---  providers = {
---    droid = { module = "droid.cmp.blink", name = "Droid" },
---  },
---  per_filetype = {
---    droid_ask = { "droid", "buffer" },
---  },
---}
---```
local source = {}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  return vim.bo.filetype == "droid_ask"
end

function source:get_trigger_characters()
  return { "@" }
end

function source:get_completions(_, callback)
  local items = {}

  for placeholder, _ in pairs(require("droid.config").opts.contexts) do
    table.insert(items, {
      label = placeholder,
      kind = require("blink.cmp.types").CompletionItemKind.Variable,
      insertText = placeholder,
      documentation = {
        kind = "markdown",
        value = "Context placeholder: " .. placeholder,
      },
    })
  end

  callback({
    items = items,
    is_incomplete_forward = false,
    is_incomplete_backward = false,
  })
end

return source
