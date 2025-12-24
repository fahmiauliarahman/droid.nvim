---Event handling for droid.nvim
local M = {}

local file_watcher = nil
local watched_files = {}

---@class droid.events.Opts
---@field enabled? boolean Enable event handling.
---@field reload? boolean Auto-reload buffers when files change.

---Setup file watcher to reload buffers when droid modifies files.
function M.setup_file_watcher()
  if not require("droid.config").opts.events.enabled then
    return
  end

  if not require("droid.config").opts.events.reload then
    return
  end

  if file_watcher then
    return
  end

  vim.o.autoread = true

  file_watcher = vim.uv.new_fs_event()
  if not file_watcher then
    return
  end

  local cwd = vim.fn.getcwd()

  file_watcher:start(cwd, { recursive = true }, function(err, filename, events)
    if err then
      return
    end

    if not filename then
      return
    end

    if events.change then
      vim.schedule(function()
        M._reload_buffer(cwd .. "/" .. filename)
      end)
    end
  end)

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.stop_file_watcher()
    end,
  })
end

---Stop the file watcher.
function M.stop_file_watcher()
  if file_watcher then
    file_watcher:stop()
    file_watcher = nil
  end
end

---Reload a buffer if it corresponds to the given file path.
---@param filepath string
function M._reload_buffer(filepath)
  local normalized = vim.fn.fnamemodify(filepath, ":p")

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      if bufname == normalized then
        local modified = vim.api.nvim_get_option_value("modified", { buf = buf })
        if not modified then
          vim.api.nvim_buf_call(buf, function()
            vim.cmd("checktime")
          end)
        end
      end
    end
  end
end

---Emit a custom autocmd event.
---@param event_type string
---@param data? table
function M.emit(event_type, data)
  vim.api.nvim_exec_autocmds("User", {
    pattern = "DroidEvent:" .. event_type,
    data = data,
  })
end

return M
