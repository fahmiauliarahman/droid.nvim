local M = {}

---@class droid.select.Opts
---@field prompt? string Prompt text.
---@field sections? droid.select.sections.Opts Configure displayed sections.
---@field snacks? table Options for snacks.picker.

---@class droid.select.sections.Opts
---@field prompts? boolean Show prompts section.
---@field provider? boolean Show provider section.

---Select from all `droid.nvim` functionality.
---
---Highlights and previews items when using snacks.picker.
---
---@param opts? droid.select.Opts
function M.select(opts)
  local config = require("droid.config").opts
  opts = vim.tbl_deep_extend("force", config.select or {}, opts or {})

  if not require("droid.config").provider then
    opts.sections.provider = false
  end

  local context = require("droid.context").new()
  local prompts = config.prompts or {}

  ---@type table[]
  local items = {}

  if opts.sections.prompts then
    table.insert(items, { __group = true, name = "PROMPT", preview = { text = "" } })
    local prompt_items = {}
    for name, prompt_config in pairs(prompts) do
      local rendered = context:render(prompt_config.prompt)
      local item = {
        __type = "prompt",
        name = name,
        text = prompt_config.prompt .. (prompt_config.ask and "..." or ""),
        highlights = rendered.input,
        preview = {
          text = context.plaintext(rendered.output),
          extmarks = context.extmarks(rendered.output),
        },
        ask = prompt_config.ask,
        submit = prompt_config.submit,
      }
      table.insert(prompt_items, item)
    end

    table.sort(prompt_items, function(a, b)
      if a.ask and not b.ask then
        return true
      elseif not a.ask and b.ask then
        return false
      elseif not a.submit and b.submit then
        return true
      elseif a.submit and not b.submit then
        return false
      else
        return a.name < b.name
      end
    end)

    for _, item in ipairs(prompt_items) do
      table.insert(items, item)
    end
  end

  if opts.sections.provider then
    table.insert(items, { __group = true, name = "PROVIDER", preview = { text = "" } })
    table.insert(items, {
      __type = "provider",
      name = "toggle",
      text = "Toggle Droid",
      highlights = { { "Toggle Droid", "Comment" } },
      preview = { text = "" },
    })
    table.insert(items, {
      __type = "provider",
      name = "start",
      text = "Start Droid",
      highlights = { { "Start Droid", "Comment" } },
      preview = { text = "" },
    })
    table.insert(items, {
      __type = "provider",
      name = "stop",
      text = "Stop Droid",
      highlights = { { "Stop Droid", "Comment" } },
      preview = { text = "" },
    })
  end

  for i, item in ipairs(items) do
    item.idx = i
  end

  local select_opts = {
    prompt = opts.prompt or "Droid: ",
    format_item = function(item, is_snacks)
      if is_snacks then
        if item.__group then
          return { { item.name, "Title" } }
        end
        local formatted = vim.deepcopy(item.highlights or {})
        if item.ask then
          table.insert(formatted, { "...", "Keyword" })
        end
        table.insert(formatted, 1, { item.name, "Keyword" })
        table.insert(formatted, 2, { string.rep(" ", 18 - #item.name) })
        return formatted
      else
        local indent = #tostring(#items) - #tostring(item.idx)
        if item.__group then
          local divider = string.rep("-", (60 - #item.name) / 2)
          return string.rep(" ", indent) .. divider .. item.name .. divider
        end
        return ("%s[%s]%s%s"):format(
          string.rep(" ", indent),
          item.name,
          string.rep(" ", 18 - #item.name),
          item.text or ""
        )
      end
    end,
  }

  local has_snacks, _ = pcall(require, "snacks")
  if has_snacks and opts.snacks then
    select_opts = vim.tbl_deep_extend("force", select_opts, opts.snacks)
  end

  vim.ui.select(items, select_opts, function(choice)
    if not choice then
      context:resume()
      return
    else
      context:clear()
    end

    if choice.__type == "prompt" then
      local prompt_config = config.prompts[choice.name]
      prompt_config.context = context
      if prompt_config.ask then
        require("droid").ask(prompt_config.prompt, prompt_config)
      else
        require("droid").prompt(prompt_config.prompt, prompt_config)
      end
    elseif choice.__type == "provider" then
      if choice.name == "toggle" then
        require("droid").toggle()
      elseif choice.name == "start" then
        require("droid").start()
      elseif choice.name == "stop" then
        require("droid").stop()
      end
    end
  end)
end

return M
