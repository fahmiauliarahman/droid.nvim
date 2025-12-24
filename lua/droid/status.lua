---Statusline component for droid.nvim
local M = {}

---Get the current droid status for the statusline.
---@return string
function M.statusline()
  local provider = require("droid.provider").get()

  if not provider then
    return ""
  end

  local is_running = require("droid.provider").is_running()

  if is_running then
    return "󰚩 Droid"
  else
    return ""
  end
end

---Get status with icon.
---@return string icon
---@return string text
---@return string hl_group
function M.status()
  local provider = require("droid.provider").get()

  if not provider then
    return "", "No provider", "Comment"
  end

  local is_running = require("droid.provider").is_running()

  if is_running then
    return "󰚩", "Running", "DiagnosticOk"
  else
    return "󰚩", "Stopped", "Comment"
  end
end

---Lualine component configuration.
---@return table
function M.lualine()
  return {
    function()
      return M.statusline()
    end,
    cond = function()
      return M.statusline() ~= ""
    end,
  }
end

return M
