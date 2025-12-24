---Provide an embedded `droid` via a Neovim terminal buffer.
---@class droid.provider.Terminal : droid.Provider
---@field opts droid.provider.terminal.Opts
---@field bufnr? integer
---@field winid? integer
---@field job_id? integer
local Terminal = {}
Terminal.__index = Terminal
Terminal.name = "terminal"

---@class droid.provider.terminal.Opts
---@field split? "left"|"right"|"above"|"below" Split direction.
---@field width? integer Width for vertical splits.
---@field height? integer Height for horizontal splits.

function Terminal.new(opts)
  local self = setmetatable({}, Terminal)
  self.opts = opts or {}
  self.winid = nil
  self.bufnr = nil
  self.job_id = nil
  return self
end

function Terminal.health()
  local cmd = require("droid.config").opts.provider.cmd or "droid"
  local executable = vim.split(cmd, " ")[1]
  if vim.fn.executable(executable) == 1 then
    return true
  end
  return "Command `" .. executable .. "` not found", { "Install Factory AI CLI (droid)" }
end

---Get window configuration based on options.
---@return table
function Terminal:_get_win_config()
  local split = self.opts.split or "right"
  local config = {
    split = split,
  }

  if split == "left" or split == "right" then
    config.width = self.opts.width or math.floor(vim.o.columns * 0.4)
  else
    config.height = self.opts.height or math.floor(vim.o.lines * 0.3)
  end

  return config
end

---Start if not running, else hide/show the window.
function Terminal:toggle()
  if self.bufnr == nil or not vim.api.nvim_buf_is_valid(self.bufnr) then
    self:start()
  else
    if self.winid ~= nil and vim.api.nvim_win_is_valid(self.winid) then
      vim.api.nvim_win_hide(self.winid)
      self.winid = nil
    elseif self.bufnr ~= nil and vim.api.nvim_buf_is_valid(self.bufnr) then
      local previous_win = vim.api.nvim_get_current_win()
      self.winid = vim.api.nvim_open_win(self.bufnr, true, self:_get_win_config())
      vim.api.nvim_set_current_win(previous_win)
    end
  end
end

---Open a window with a terminal buffer.
function Terminal:start()
  if self.bufnr ~= nil and vim.api.nvim_buf_is_valid(self.bufnr) then
    if self.winid == nil or not vim.api.nvim_win_is_valid(self.winid) then
      local previous_win = vim.api.nvim_get_current_win()
      self.winid = vim.api.nvim_open_win(self.bufnr, true, self:_get_win_config())
      vim.api.nvim_set_current_win(previous_win)
    end
    return
  end

  local previous_win = vim.api.nvim_get_current_win()

  self.bufnr = vim.api.nvim_create_buf(true, false)
  self.winid = vim.api.nvim_open_win(self.bufnr, true, self:_get_win_config())

  vim.api.nvim_set_option_value("filetype", "droid_terminal", { buf = self.bufnr })

  self.job_id = vim.fn.jobstart(self.cmd or "droid", {
    term = true,
    cwd = vim.fn.getcwd(),
    on_exit = function(_, exit_code)
      if self.winid and vim.api.nvim_win_is_valid(self.winid) then
        vim.api.nvim_win_close(self.winid, true)
      end
      self.winid = nil
      self.bufnr = nil
      self.job_id = nil

      if exit_code ~= 0 and exit_code ~= 130 then
        vim.schedule(function()
          vim.notify("Droid exited with code: " .. exit_code, vim.log.levels.WARN, { title = "droid" })
        end)
      end
    end,
  })

  vim.api.nvim_set_current_win(previous_win)

  require("droid.events").setup_file_watcher()
end

---Close the window and delete the buffer.
function Terminal:stop()
  if self.job_id then
    vim.fn.jobstop(self.job_id)
    self.job_id = nil
  end
  if self.winid ~= nil and vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_win_close(self.winid, true)
    self.winid = nil
  end
  if self.bufnr ~= nil and vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
    self.bufnr = nil
  end
end

---Send text to the terminal.
---@param text string
function Terminal:send(text)
  if not self.job_id then
    self:start()
    vim.defer_fn(function()
      if self.job_id then
        vim.api.nvim_chan_send(self.job_id, text)
      end
    end, 500)
  else
    vim.api.nvim_chan_send(self.job_id, text)
  end
end

---Focus the terminal window.
function Terminal:focus()
  if self.winid and vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_set_current_win(self.winid)
  elseif self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
    self.winid = vim.api.nvim_open_win(self.bufnr, true, self:_get_win_config())
  else
    self:start()
    if self.winid then
      vim.api.nvim_set_current_win(self.winid)
    end
  end
end

return Terminal
