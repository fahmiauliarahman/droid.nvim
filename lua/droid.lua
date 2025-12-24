---`droid.nvim` public API.
---Integrates Factory AI (Droid) with Neovim.
local M = {}

M.ask = function(default, opts)
  return require("droid.ui.ask").ask(default, opts)
end

M.select = function(opts)
  return require("droid.ui.select").select(opts)
end

M.prompt = function(prompt, opts)
  return require("droid.api.prompt").prompt(prompt, opts)
end

M.operator = function(prefix)
  return require("droid.api.operator").operator(prefix)
end

M.toggle = function()
  return require("droid.provider").toggle()
end

M.start = function()
  return require("droid.provider").start()
end

M.stop = function()
  return require("droid.provider").stop()
end

M.statusline = function()
  return require("droid.status").statusline()
end

M.setup = function(opts)
  if opts then
    vim.g.droid_opts = vim.tbl_deep_extend("force", vim.g.droid_opts or {}, opts)
    require("droid.config").reload()
  end
end

return M
