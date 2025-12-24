local M = {}

---Your `droid.nvim` configuration.
---@type droid.Opts|nil
vim.g.droid_opts = vim.g.droid_opts

---@class droid.Opts
---@field contexts? table<string, fun(context: droid.Context): string|nil> Contexts to inject into prompts.
---@field prompts? table<string, droid.Prompt> Prompts to reference or select from.
---@field ask? droid.ask.Opts Options for `ask()`.
---@field select? droid.select.Opts Options for `select()`.
---@field events? droid.events.Opts Options for event handling.
---@field provider? droid.Provider|droid.provider.Opts Provider configuration.

---@class droid.Prompt : droid.api.prompt.Opts
---@field prompt string The prompt to send to `droid`.
---@field ask? boolean Call `ask(prompt)` instead of `prompt(prompt)`.

---@type droid.Opts
local defaults = {
  contexts = {
    ["@this"] = function(context)
      return context:this()
    end,
    ["@buffer"] = function(context)
      return context:buffer()
    end,
    ["@buffers"] = function(context)
      return context:buffers()
    end,
    ["@visible"] = function(context)
      return context:visible_text()
    end,
    ["@diagnostics"] = function(context)
      return context:diagnostics()
    end,
    ["@quickfix"] = function(context)
      return context:quickfix()
    end,
    ["@diff"] = function(context)
      return context:git_diff()
    end,
  },
  prompts = {
    ask_append = { prompt = "", ask = true },
    ask_this = { prompt = "@this: ", ask = true, submit = true },
    diagnostics = { prompt = "Explain @diagnostics", submit = true },
    diff = { prompt = "Review the following git diff for correctness and readability: @diff", submit = true },
    document = { prompt = "Add comments documenting @this", submit = true },
    explain = { prompt = "Explain @this and its context", submit = true },
    fix = { prompt = "Fix @diagnostics", submit = true },
    implement = { prompt = "Implement @this", submit = true },
    optimize = { prompt = "Optimize @this for performance and readability", submit = true },
    review = { prompt = "Review @this for correctness and readability", submit = true },
    test = { prompt = "Add tests for @this", submit = true },
  },
  ask = {
    prompt = "Ask Droid: ",
    blink_cmp_sources = { "droid", "buffer" },
    snacks = {
      icon = "󰚩 ",
      win = {
        title_pos = "left",
        relative = "cursor",
        row = -3,
        col = 0,
      },
    },
  },
  select = {
    prompt = "Droid: ",
    sections = {
      prompts = true,
      provider = true,
    },
    snacks = {
      preview = "preview",
      layout = {
        preset = "vscode",
        hidden = {},
      },
    },
  },
  events = {
    enabled = true,
    reload = true,
  },
  provider = {
    cmd = "droid",
    enabled = (function()
      for _, provider in ipairs(require("droid.provider").list()) do
        local ok, _ = provider.health()
        if ok == true then
          return provider.name
        end
      end
      return "terminal"
    end)(),
    terminal = {
      split = "right",
      width = math.floor(vim.o.columns * 0.4),
    },
    snacks = {
      auto_close = false,
      win = {
        position = "right",
        enter = false,
        wo = {
          winbar = "",
        },
        bo = {
          filetype = "droid_terminal",
        },
      },
    },
  },
}

---Plugin options, lazily merged from `defaults` and `vim.g.droid_opts`.
---@type droid.Opts
M.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), vim.g.droid_opts or {})

local user_opts = vim.g.droid_opts or {}
for _, field in ipairs({ "contexts", "prompts" }) do
  if user_opts[field] and M.opts[field] then
    for k, v in pairs(user_opts[field]) do
      if not v then
        M.opts[field][k] = nil
      end
    end
  end
end

---The `droid` provider resolved from `opts.provider`.
---@type droid.Provider|nil
M.provider = nil

local function resolve_provider()
  local provider_or_opts = M.opts.provider
  local provider

  if provider_or_opts and (provider_or_opts.toggle or provider_or_opts.start or provider_or_opts.stop) then
    ---@cast provider_or_opts droid.Provider
    provider = provider_or_opts
  elseif provider_or_opts and provider_or_opts.enabled then
    local ok, resolved_provider = pcall(require, "droid.provider." .. provider_or_opts.enabled)
    if not ok then
      vim.notify(
        "Failed to load `droid` provider '" .. provider_or_opts.enabled .. "': " .. resolved_provider,
        vim.log.levels.ERROR,
        { title = "droid" }
      )
      return nil
    end

    local resolved_provider_opts = provider_or_opts[provider_or_opts.enabled]
    provider = resolved_provider.new(resolved_provider_opts)
    provider.cmd = provider.cmd or provider_or_opts.cmd
  end

  return provider
end

M.provider = resolve_provider()

function M.reload()
  M.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), vim.g.droid_opts or {})
  M.provider = resolve_provider()
end

return M
