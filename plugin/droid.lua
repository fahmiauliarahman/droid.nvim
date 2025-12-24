if vim.g.loaded_droid then
  return
end
vim.g.loaded_droid = true

vim.api.nvim_create_user_command("Droid", function(opts)
  local args = opts.args

  if args == "" or args == "toggle" then
    require("droid").toggle()
  elseif args == "start" then
    require("droid").start()
  elseif args == "stop" then
    require("droid").stop()
  elseif args == "ask" then
    require("droid").ask()
  elseif args == "select" then
    require("droid").select()
  elseif args:match("^ask ") then
    local prompt = args:gsub("^ask ", "")
    require("droid").ask(prompt)
  elseif args:match("^prompt ") then
    local prompt = args:gsub("^prompt ", "")
    require("droid").prompt(prompt, { submit = true })
  else
    require("droid").prompt(args, { submit = true })
  end
end, {
  nargs = "*",
  complete = function(ArgLead, CmdLine, CursorPos)
    local completions = {
      "toggle",
      "start",
      "stop",
      "ask",
      "select",
      "prompt",
    }

    for name, _ in pairs(require("droid.config").opts.prompts or {}) do
      table.insert(completions, "prompt " .. name)
    end

    return vim.tbl_filter(function(item)
      return item:find(ArgLead, 1, true) == 1
    end, completions)
  end,
  desc = "Droid AI commands",
})

vim.api.nvim_set_hl(0, "DroidContextPlaceholder", { link = "Special", default = true })
vim.api.nvim_set_hl(0, "DroidContextValue", { link = "String", default = true })

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local provider = require("droid.config").provider
    if provider and provider.stop then
      pcall(provider.stop, provider)
    end
  end,
})
