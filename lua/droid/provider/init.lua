---Provide an integrated `droid`.
---@class droid.Provider
---@field name? string The name of the provider.
---@field cmd? string The command to start `droid`.
---@field new? fun(opts: table): droid.Provider
---@field toggle? fun(self: droid.Provider) Toggle `droid`.
---@field start? fun(self: droid.Provider) Start `droid`.
---@field stop? fun(self: droid.Provider) Stop `droid`.
---@field send? fun(self: droid.Provider, text: string) Send text to `droid`.
---@field health? fun(): boolean|string, ...string|string[] Health check.

---@class droid.provider.Opts
---@field enabled? "terminal"|"snacks"|false
---@field cmd? string
---@field terminal? droid.provider.terminal.Opts
---@field snacks? droid.provider.snacks.Opts

local M = {}

---Get all providers.
---@return droid.Provider[]
function M.list()
  return {
    require("droid.provider.snacks"),
    require("droid.provider.terminal"),
  }
end

---Toggle `droid` via the configured provider.
function M.toggle()
  local provider = require("droid.config").provider
  if provider and provider.toggle then
    provider:toggle()
  else
    error("`provider.toggle` unavailable — run `:checkhealth droid` for details", 0)
  end
end

---Start `droid` via the configured provider.
function M.start()
  local provider = require("droid.config").provider
  if provider and provider.start then
    provider:start()
  else
    error("`provider.start` unavailable — run `:checkhealth droid` for details", 0)
  end
end

---Stop `droid` via the configured provider.
function M.stop()
  local provider = require("droid.config").provider
  if provider and provider.stop then
    provider:stop()
  else
    error("`provider.stop` unavailable — run `:checkhealth droid` for details", 0)
  end
end

---Send text to `droid` via the configured provider.
---@param text string
function M.send(text)
  local provider = require("droid.config").provider
  if provider and provider.send then
    provider:send(text)
  else
    error("`provider.send` unavailable — run `:checkhealth droid` for details", 0)
  end
end

---Get the current provider instance.
---@return droid.Provider|nil
function M.get()
  return require("droid.config").provider
end

---Check if droid is currently running.
---@return boolean
function M.is_running()
  local provider = require("droid.config").provider
  if provider and provider.bufnr then
    return vim.api.nvim_buf_is_valid(provider.bufnr)
  end
  return false
end

return M
