local droid = require("droid")

describe("droid", function()
  it("should have public API functions", function()
    assert.is_function(droid.ask)
    assert.is_function(droid.select)
    assert.is_function(droid.prompt)
    assert.is_function(droid.operator)
    assert.is_function(droid.toggle)
    assert.is_function(droid.start)
    assert.is_function(droid.stop)
    assert.is_function(droid.statusline)
    assert.is_function(droid.setup)
  end)
end)

describe("droid.config", function()
  local config = require("droid.config")

  it("should have default contexts", function()
    assert.is_table(config.opts.contexts)
    assert.is_function(config.opts.contexts["@this"])
    assert.is_function(config.opts.contexts["@buffer"])
    assert.is_function(config.opts.contexts["@diagnostics"])
  end)

  it("should have default prompts", function()
    assert.is_table(config.opts.prompts)
    assert.is_table(config.opts.prompts.explain)
    assert.is_table(config.opts.prompts.review)
    assert.is_table(config.opts.prompts.fix)
  end)

  it("should have provider config", function()
    assert.is_table(config.opts.provider)
    assert.is_string(config.opts.provider.cmd)
  end)
end)

describe("droid.context", function()
  local Context = require("droid.context")

  it("should format locations correctly", function()
    local result = Context.format({
      path = "test.lua",
      start_line = 1,
      end_line = 10,
    })
    assert.is_string(result)
    assert.is_true(result:find("test.lua") ~= nil)
    assert.is_true(result:find("L1") ~= nil)
  end)

  it("should convert rendered to plaintext", function()
    local rendered = {
      { "Hello " },
      { "world", "Special" },
    }
    local plaintext = Context.plaintext(rendered)
    assert.equals("Hello world", plaintext)
  end)
end)

describe("droid.promise", function()
  local Promise = require("droid.promise")

  it("should resolve with value", function()
    local resolved_value = nil
    Promise.new(function(resolve)
      resolve("test")
    end):next(function(value)
      resolved_value = value
    end)

    vim.wait(100, function()
      return resolved_value ~= nil
    end)

    assert.equals("test", resolved_value)
  end)

  it("should catch rejections", function()
    local caught_error = nil
    Promise.new(function(_, reject)
      reject("error")
    end):catch(function(err)
      caught_error = err
    end)

    vim.wait(100, function()
      return caught_error ~= nil
    end)

    assert.equals("error", caught_error)
  end)
end)
