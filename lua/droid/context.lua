---The context a prompt is being made in.
---@class droid.Context
---@field win integer
---@field buf integer
---@field cursor integer[] The cursor position. { row, col } (1,0-based).
---@field range? droid.context.Range The operator range or visual selection range.
local Context = {}
Context.__index = Context

local ns_id = vim.api.nvim_create_namespace("DroidContext")

local function is_buf_valid(buf)
  return vim.api.nvim_buf_is_loaded(buf)
    and vim.api.nvim_get_option_value("buftype", { buf = buf }) == ""
    and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function last_used_valid_win()
  local last_used_win = 0
  local latest_last_used = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if is_buf_valid(buf) then
      local last_used = vim.fn.getbufinfo(buf)[1].lastused or 0
      if last_used > latest_last_used then
        latest_last_used = last_used
        last_used_win = win
      end
    end
  end
  return last_used_win
end

---@class droid.context.Range
---@field from integer[] { line, col } (1,0-based)
---@field to integer[] { line, col } (1,0-based)
---@field kind "char"|"line"|"block"

---@param buf integer
---@param line integer 1-based line number
---@return integer 0-based max column for the line
local function get_line_max_col(buf, line)
  local lines = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)
  if #lines == 0 then
    return 0
  end
  return #lines[1]
end

---@param buf integer
---@return droid.context.Range|nil
local function selection(buf)
  local mode = vim.fn.mode()
  local in_visual = mode == "V" or mode == "v" or mode == "\22"
  local kind
  local from, to

  if in_visual then
    kind = (mode == "V" and "line") or (mode == "v" and "char") or "block"
    -- Get positions while still in visual mode using getpos
    local start_pos = vim.fn.getpos("v") -- Start of visual selection
    local end_pos = vim.fn.getpos(".") -- Current cursor (end of selection)
    from = { start_pos[2], math.max(0, start_pos[3] - 1) }
    to = { end_pos[2], math.max(0, end_pos[3] - 1) }
    -- Exit visual mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
  else
    -- Check if we just exited visual mode by looking at the last visual mode
    local last_visual = vim.fn.visualmode()
    if last_visual == "" then
      return nil
    end
    kind = (last_visual == "V" and "line") or (last_visual == "v" and "char") or "block"
    -- Use marks after visual mode has ended
    local mark_from = vim.api.nvim_buf_get_mark(buf, "<")
    local mark_to = vim.api.nvim_buf_get_mark(buf, ">")
    -- Marks are invalid (not set)
    if mark_from[1] == 0 or mark_to[1] == 0 then
      return nil
    end
    from = { mark_from[1], mark_from[2] }
    to = { mark_to[1], mark_to[2] }
  end

  if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
    from, to = to, from
  end

  -- Clamp columns to valid line lengths
  from[2] = math.min(from[2], get_line_max_col(buf, from[1]))
  to[2] = math.min(to[2], get_line_max_col(buf, to[1]))

  return {
    from = { from[1], from[2] },
    to = { to[1], to[2] },
    kind = kind,
  }
end

---@param buf integer
---@param range droid.context.Range
local function highlight(buf, range)
  local end_col = nil
  if range.kind ~= "line" then
    local max_col = get_line_max_col(buf, range.to[1])
    end_col = math.min(range.to[2] + 1, max_col)
  end
  vim.api.nvim_buf_set_extmark(buf, ns_id, range.from[1] - 1, range.from[2], {
    end_row = range.to[1] - (range.kind == "line" and 0 or 1),
    end_col = end_col,
    hl_group = "Visual",
  })
end

---@param range? droid.context.Range
function Context.new(range)
  local self = setmetatable({}, Context)
  self.win = last_used_valid_win()
  self.buf = vim.api.nvim_win_get_buf(self.win)
  self.cursor = vim.api.nvim_win_get_cursor(self.win)
  self.range = range or selection(self.buf)
  if self.range then
    highlight(self.buf, self.range)
  end
  return self
end

function Context:clear()
  vim.api.nvim_buf_clear_namespace(self.buf, ns_id, 0, -1)
end

function Context:resume()
  self:clear()
  vim.cmd("normal! gv")
end

---Render `opts.contexts` in `prompt`.
---@param prompt string
---@return { input: table[], output: table[] }
function Context:render(prompt)
  local contexts = require("droid.config").opts.contexts or {}
  local context_placeholders = vim.tbl_keys(contexts)
  table.sort(context_placeholders, function(a, b)
    return #a > #b
  end)

  local input, output = {}, {}
  local i = 1
  while i <= #prompt do
    local at_pos = prompt:find("@", i, true)

    if not at_pos then
      local text = prompt:sub(i)
      if #text > 0 then
        table.insert(input, { text })
        table.insert(output, { text })
      end
      break
    end

    if at_pos > i then
      local text = prompt:sub(i, at_pos - 1)
      table.insert(input, { text })
      table.insert(output, { text })
    end

    -- Check for fixed placeholders
    local matched_placeholder = nil
    for _, placeholder in ipairs(context_placeholders) do
      if prompt:sub(at_pos, at_pos + #placeholder - 1) == placeholder then
        matched_placeholder = placeholder
        break
      end
    end

    if matched_placeholder then
      table.insert(input, { matched_placeholder, "DroidContextPlaceholder" })
      local value = contexts[matched_placeholder](self)
      if value then
        table.insert(output, { value, "DroidContextValue" })
      else
        table.insert(output, { matched_placeholder, "DroidContextPlaceholder" })
      end
      i = at_pos + #matched_placeholder
    else
      -- Check for relative file path
      local remainder = prompt:sub(at_pos)
      local file_path = remainder:match("^@([%w%-%._/]+)")
      local processed = false

      if file_path then
        local value = self:file(file_path)
        if value then
          table.insert(input, { "@" .. file_path, "DroidContextPlaceholder" })
          table.insert(output, { value, "DroidContextValue" })
          i = at_pos + 1 + #file_path
          processed = true
        end
      end

      if not processed then
        table.insert(input, { "@" })
        table.insert(output, { "@" })
        i = at_pos + 1
      end
    end
  end

  return {
    input = input,
    output = output,
  }
end

---Get content of a file relative to project root.
---@param path string
---@return string|nil
function Context:file(path)
  local full_path = vim.fn.fnamemodify(path, ":p")
  if vim.fn.filereadable(full_path) == 1 then
    local lines = vim.fn.readfile(full_path)
    local content = table.concat(lines, "\n")
    local header = Context.format({ path = path })
    return header .. "\n```\n" .. content .. "\n```"
  end
  return nil
end

---Convert rendered context to plaintext.
---@param rendered table[]
---@return string
function Context.plaintext(rendered)
  return table.concat(vim.tbl_map(function(part)
    return part[1]
  end, rendered))
end

---Convert rendered context to extmarks.
---@param rendered table[]
---@return table[]
function Context.extmarks(rendered)
  local row = 1
  local col = 1
  local extmarks = {}
  for _, part in ipairs(rendered) do
    local part_text = part[1]
    local part_hl = part[2] or nil
    local segments = vim.split(part_text, "\n", { plain = true })
    for i, segment in ipairs(segments) do
      if i > 1 then
        row = row + 1
        col = 1
      end
      if part_hl then
        local extmark = {
          row = row,
          col = col - 1,
          end_col = col + #segment - 1,
          hl_group = part_hl,
        }
        table.insert(extmarks, extmark)
      end
      col = col + #segment
    end
  end
  return extmarks
end

---Format a location for context.
---@param args { buf?: integer, path?: string, start_line?: integer, start_col?: integer, end_line?: integer, end_col?: integer }
function Context.format(args)
  local result = ""
  if (args.buf and is_buf_valid(args.buf)) or args.path then
    local rel_path = vim.fn.fnamemodify(args.path or vim.api.nvim_buf_get_name(args.buf), ":.")
    result = "@" .. rel_path .. " "
  end
  if args.start_line and args.end_line and args.start_line > args.end_line then
    args.start_line, args.end_line = args.end_line, args.start_line
    if args.start_col and args.end_col then
      args.start_col, args.end_col = args.end_col, args.start_col
    end
  end
  if args.start_line then
    result = result .. string.format("L%d", args.start_line)
    if args.start_col then
      result = result .. string.format(":C%d", args.start_col)
    end
    if args.end_line then
      result = result .. string.format("-L%d", args.end_line)
      if args.end_col then
        result = result .. string.format(":C%d", args.end_col)
      end
    end
  end
  return result
end

---Get file content for a range
---@param buf integer
---@param start_line integer
---@param end_line integer
---@return string
function Context.get_lines(buf, start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)
  return table.concat(lines, "\n")
end

---Range if present, else cursor position.
function Context:this()
  if self.range then
    local content = Context.get_lines(self.buf, self.range.from[1], self.range.to[1])
    local location = Context.format({
      buf = self.buf,
      start_line = self.range.from[1],
      start_col = (self.range.kind ~= "line") and self.range.from[2] or nil,
      end_line = self.range.to[1],
      end_col = (self.range.kind ~= "line") and self.range.to[2] or nil,
    })
    return location .. "\n```\n" .. content .. "\n```"
  else
    local line = vim.api.nvim_buf_get_lines(self.buf, self.cursor[1] - 1, self.cursor[1], false)[1] or ""
    return Context.format({
      buf = self.buf,
      start_line = self.cursor[1],
      start_col = self.cursor[2] + 1,
    }) .. "\n" .. line
  end
end

---The current buffer.
function Context:buffer()
  return Context.format({ buf = self.buf })
end

---All open buffers.
function Context:buffers()
  local file_list = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local path = Context.format({ buf = buf })
    if path and path ~= "" then
      table.insert(file_list, path)
    end
  end
  if #file_list == 0 then
    return nil
  end
  return table.concat(file_list, ", ")
end

---The visible lines in all open windows.
function Context:visible_text()
  local visible = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if is_buf_valid(buf) then
      local start_line = vim.fn.line("w0", win)
      local end_line = vim.fn.line("w$", win)
      table.insert(
        visible,
        Context.format({
          buf = buf,
          start_line = start_line,
          end_line = end_line,
        })
      )
    end
  end
  if #visible == 0 then
    return nil
  end
  return table.concat(visible, " ")
end

---Diagnostics for the current buffer.
function Context:diagnostics()
  local diagnostics = vim.diagnostic.get(self.buf)
  if #diagnostics == 0 then
    return nil
  end

  local file_ref = Context.format({ buf = self.buf })
  local diagnostic_strings = {}

  for _, diagnostic in ipairs(diagnostics) do
    local location = Context.format({
      start_line = diagnostic.lnum + 1,
      start_col = diagnostic.col + 1,
      end_line = diagnostic.end_lnum + 1,
      end_col = diagnostic.end_col + 1,
    })

    local severity = vim.diagnostic.severity[diagnostic.severity] or "UNKNOWN"
    table.insert(
      diagnostic_strings,
      string.format(
        "- [%s] %s (%s): %s",
        severity,
        location,
        diagnostic.source or "unknown",
        diagnostic.message:gsub("%s+", " "):gsub("^%s", ""):gsub("%s$", "")
      )
    )
  end

  return #diagnostics .. " diagnostics in " .. file_ref .. ":\n" .. table.concat(diagnostic_strings, "\n")
end

---Formatted quickfix list entries.
function Context:quickfix()
  local qflist = vim.fn.getqflist()
  if #qflist == 0 then
    return nil
  end
  local lines = {}
  for _, entry in ipairs(qflist) do
    local has_buf = entry.bufnr ~= 0 and vim.api.nvim_buf_get_name(entry.bufnr) ~= ""
    if has_buf then
      table.insert(
        lines,
        Context.format({
          buf = entry.bufnr,
          start_line = entry.lnum,
          start_col = entry.col,
        })
      )
    end
  end
  return table.concat(lines, " ")
end

---The git diff (unified diff format).
function Context:git_diff()
  local handle = io.popen("git --no-pager diff 2>/dev/null")
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  if result and result ~= "" then
    return "```diff\n" .. result .. "\n```"
  end
  return nil
end

return Context
