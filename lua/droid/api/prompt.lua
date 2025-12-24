local M = {}

---@class droid.api.prompt.Opts
---@field submit? boolean Submit the prompt immediately.
---@field context? droid.Context The context the prompt is being made in.

---Prompt `droid`.
---
---Resolves `prompt` if it references an `opts.prompts` entry by name.
---Injects `opts.contexts` into `prompt`.
---
---@param prompt string
---@param opts? droid.api.prompt.Opts
function M.prompt(prompt, opts)
  local referenced_prompt = require("droid.config").opts.prompts[prompt]
  prompt = referenced_prompt and referenced_prompt.prompt or prompt
  opts = {
    submit = opts and opts.submit or false,
    context = opts and opts.context or require("droid.context").new(),
  }

  local provider = require("droid.provider").get()
  if not provider then
    vim.notify("No droid provider available", vim.log.levels.ERROR, { title = "droid" })
    return
  end

  local rendered = opts.context:render(prompt)
  local plaintext = opts.context.plaintext(rendered.output)

  if not require("droid.provider").is_running() then
    provider:start()
    vim.defer_fn(function()
      M._send_prompt(provider, plaintext, opts.submit)
      opts.context:clear()
    end, 800)
  else
    M._send_prompt(provider, plaintext, opts.submit)
    opts.context:clear()
  end
end

---Send the prompt text to the provider.
---@param provider droid.Provider
---@param text string
---@param submit boolean
function M._send_prompt(provider, text, submit)
  local escaped = text:gsub("\\", "\\\\"):gsub("\n", "\\n")

  if submit then
    provider:send(text .. "\n")
  else
    provider:send(text)
  end
end

return M
