---Health check for droid.nvim
local M = {}

function M.check()
  vim.health.start("droid.nvim")

  local config = require("droid.config")
  local cmd = config.opts.provider.cmd or "droid"
  local executable = vim.split(cmd, " ")[1]

  if vim.fn.executable(executable) == 1 then
    vim.health.ok("Command `" .. executable .. "` found")
  else
    vim.health.error("Command `" .. executable .. "` not found", {
      "Install Factory AI CLI",
      "Visit https://factory.ai for installation instructions",
    })
  end

  local provider = config.provider
  if provider then
    vim.health.ok("Provider: " .. (provider.name or "custom"))
  else
    vim.health.warn("No provider configured")
  end

  local has_snacks, snacks = pcall(require, "snacks")
  if has_snacks then
    vim.health.ok("`snacks.nvim` available")
    if snacks.input then
      vim.health.ok("`snacks.input` available")
    else
      vim.health.info("`snacks.input` not enabled (optional)")
    end
    if snacks.terminal then
      vim.health.ok("`snacks.terminal` available")
    else
      vim.health.info("`snacks.terminal` not enabled (optional for snacks provider)")
    end
  else
    vim.health.info("`snacks.nvim` not installed (optional)")
  end

  local has_blink = pcall(require, "blink.cmp")
  if has_blink then
    vim.health.ok("`blink.cmp` available for completions")
  else
    vim.health.info("`blink.cmp` not installed (optional)")
  end

  local contexts_count = 0
  for _ in pairs(config.opts.contexts or {}) do
    contexts_count = contexts_count + 1
  end
  vim.health.ok(contexts_count .. " context(s) configured")

  local prompts_count = 0
  for _ in pairs(config.opts.prompts or {}) do
    prompts_count = prompts_count + 1
  end
  vim.health.ok(prompts_count .. " prompt(s) configured")
end

return M
