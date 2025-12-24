---Blink.cmp source for droid context completions.
local M = {}

M.context = nil

---Setup blink.cmp source for droid.
---@param sources string[]
function M.setup(sources)
  local has_blink, blink = pcall(require, "blink.cmp")
  if not has_blink then
    return
  end

  blink.register_source("droid", {
    name = "droid",
    get_trigger_characters = function()
      return { "@" }
    end,
    get_completions = function(self, ctx, callback)
      local items = {}

      for placeholder, _ in pairs(require("droid.config").opts.contexts) do
        table.insert(items, {
          label = placeholder,
          kind = vim.lsp.protocol.CompletionItemKind.Variable,
          documentation = {
            kind = "markdown",
            value = "Context placeholder: " .. placeholder,
          },
        })
      end

      callback({
        is_incomplete_forward = false,
        is_incomplete_backward = false,
        items = items,
      })
    end,
  })
end

return M
