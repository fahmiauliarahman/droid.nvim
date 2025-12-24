local M = {}

local operator_context = nil
local operator_prefix = ""

---Wraps `prompt` as an operator, supporting ranges and dot-repeat.
---@param prefix? string Text to prepend to the context.
---@return string
function M.operator(prefix)
  operator_prefix = prefix or ""
  vim.o.operatorfunc = "v:lua.require'droid.api.operator'._callback"
  return "g@"
end

---Operator callback function.
---@param type string The motion type: "line", "char", or "block".
function M._callback(type)
  local start_pos = vim.api.nvim_buf_get_mark(0, "[")
  local end_pos = vim.api.nvim_buf_get_mark(0, "]")

  local kind
  if type == "line" then
    kind = "line"
  elseif type == "char" then
    kind = "char"
  else
    kind = "block"
  end

  ---@type droid.context.Range
  local range = {
    from = { start_pos[1], start_pos[2] },
    to = { end_pos[1], end_pos[2] },
    kind = kind,
  }

  operator_context = require("droid.context").new(range)

  require("droid").ask(operator_prefix, {
    context = operator_context,
    submit = false,
  })
end

return M
