local M = {}

---@class droid.ask.Opts
---@field prompt? string Text of the prompt.
---@field blink_cmp_sources? string[] Completion sources for blink.cmp.
---@field snacks? table Options for snacks.input.

---Input a prompt for `droid`.
---
---Press the up arrow to browse recent asks.
---Highlights and completes contexts.
---
---@param default? string Text to pre-fill the input with.
---@param opts? droid.api.prompt.Opts Options for `prompt()`.
function M.ask(default, opts)
  opts = opts or {}
  opts.context = opts.context or require("droid.context").new()

  local config = require("droid.config").opts

  ---@type table
  local input_opts = {
    prompt = config.ask.prompt or "Ask Droid: ",
    default = default,
    highlight = function(text)
      local rendered = opts.context:render(text)
      return vim.tbl_map(function(extmark)
        return { extmark.col, extmark.end_col, extmark.hl_group }
      end, opts.context.extmarks(rendered.input))
    end,
    completion = "customlist,v:lua.droid_completion",
  }

  local has_snacks, snacks = pcall(require, "snacks")
  if has_snacks and snacks.input then
    input_opts = vim.tbl_deep_extend("force", input_opts, {
      win = {
        b = { completion = true },
        bo = { filetype = "droid_ask" },
      },
    })

    if config.ask.snacks then
      input_opts = vim.tbl_deep_extend("force", input_opts, config.ask.snacks)
    end
  end

  vim.ui.input(input_opts, function(value)
    if value and value ~= "" then
      opts.context:clear()
      require("droid").prompt(value, opts)
    else
      opts.context:resume()
    end
  end)
end

---Completion function for context placeholders.
---@param ArgLead string The text being completed.
---@param CmdLine string The entire current input line.
---@param CursorPos number The cursor position in the input line.
---@return table<string>
_G.droid_completion = function(ArgLead, CmdLine, CursorPos)
  local start_idx, end_idx = CmdLine:find("([^%s]+)$")
  local latest_word = start_idx and CmdLine:sub(start_idx, end_idx) or nil

  local completions = {}
  for placeholder, _ in pairs(require("droid.config").opts.contexts) do
    table.insert(completions, placeholder)
  end

  local items = {}
  for _, completion in pairs(completions) do
    if not latest_word then
      local new_cmd = CmdLine .. completion
      table.insert(items, new_cmd)
    elseif completion:find(latest_word, 1, true) == 1 then
      local new_cmd = CmdLine:sub(1, start_idx - 1) .. completion .. CmdLine:sub(end_idx + 1)
      table.insert(items, new_cmd)
    end
  end
  return items
end

return M
