---Provide an embedded `droid` via snacks.nvim terminal.
---@class droid.provider.Snacks : droid.Provider
---@field opts droid.provider.snacks.Opts
---@field terminal? table The snacks terminal instance.
---@field bufnr? integer
---@field winid? integer
local Snacks = {}
Snacks.__index = Snacks
Snacks.name = "snacks"

---@class droid.provider.snacks.Opts
---@field auto_close? boolean Close the terminal when droid exits.
---@field win? table Window options for snacks.terminal.

function Snacks.new(opts)
  local self = setmetatable({}, Snacks)
  self.opts = opts or {}
  self.terminal = nil
  self.bufnr = nil
  self.winid = nil
  return self
end

function Snacks.health()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    return "`snacks.nvim` not installed", { "Install folke/snacks.nvim" }
  end

  if not snacks.terminal then
    return "`snacks.terminal` not available", { "Enable terminal in snacks.nvim config" }
  end

  local cmd = require("droid.config").opts.provider.cmd or "droid"
  local executable = vim.split(cmd, " ")[1]
  if vim.fn.executable(executable) ~= 1 then
    return "Command `" .. executable .. "` not found", { "Install Factory AI CLI (droid)" }
  end

  return true
end

---Toggle the droid terminal.
function Snacks:toggle()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    vim.notify("`snacks.nvim` not available", vim.log.levels.ERROR, { title = "droid" })
    return
  end

  if self.terminal then
    self.terminal:toggle()
  else
    self:start()
  end
end

---Start droid in a snacks terminal.
function Snacks:start()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    vim.notify("`snacks.nvim` not available", vim.log.levels.ERROR, { title = "droid" })
    return
  end

  local cmd = self.cmd or "droid"
  local win_opts = vim.tbl_deep_extend("force", {
    position = "right",
    enter = false,
    wo = { winbar = "" },
    bo = { filetype = "droid_terminal" },
  }, self.opts.win or {})

  self.terminal = snacks.terminal.open(cmd, {
    cwd = vim.fn.getcwd(),
    auto_close = self.opts.auto_close or false,
    win = win_opts,
  })

  if self.terminal then
    self.bufnr = self.terminal.buf
    self.winid = self.terminal.win

    require("droid.events").setup_file_watcher()
  end
end

---Stop the droid terminal.
function Snacks:stop()
  if self.terminal then
    self.terminal:close()
    self.terminal = nil
    self.bufnr = nil
    self.winid = nil
  end
end

---Send text to the terminal.
---@param text string
function Snacks:send(text)
  if not self.terminal then
    self:start()
    vim.defer_fn(function()
      if self.terminal and self.terminal.buf then
        local chan = vim.api.nvim_buf_get_var(self.terminal.buf, "terminal_job_id")
        if chan then
          vim.api.nvim_chan_send(chan, text)
        end
      end
    end, 500)
  else
    local chan = vim.api.nvim_buf_get_var(self.terminal.buf, "terminal_job_id")
    if chan then
      vim.api.nvim_chan_send(chan, text)
    end
  end
end

---Focus the terminal window.
function Snacks:focus()
  if self.terminal then
    self.terminal:focus()
  else
    self:start()
  end
end

return Snacks
