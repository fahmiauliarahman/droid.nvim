---A simple Promise implementation for async operations.
---@class droid.Promise
---@field _state "pending"|"fulfilled"|"rejected"
---@field _value any
---@field _handlers table[]
local Promise = {}
Promise.__index = Promise

---Create a new Promise.
---@param executor fun(resolve: fun(value: any), reject: fun(reason: any))
---@return droid.Promise
function Promise.new(executor)
  local self = setmetatable({}, Promise)
  self._state = "pending"
  self._value = nil
  self._handlers = {}

  local function resolve(value)
    if self._state ~= "pending" then
      return
    end

    if type(value) == "table" and type(value.next) == "function" then
      value:next(resolve, function(reason)
        self._state = "rejected"
        self._value = reason
        self:_process_handlers()
      end)
      return
    end

    self._state = "fulfilled"
    self._value = value
    self:_process_handlers()
  end

  local function reject(reason)
    if self._state ~= "pending" then
      return
    end
    self._state = "rejected"
    self._value = reason
    self:_process_handlers()
  end

  local ok, err = pcall(executor, resolve, reject)
  if not ok then
    reject(err)
  end

  return self
end

---Process all pending handlers.
function Promise:_process_handlers()
  vim.schedule(function()
    for _, handler in ipairs(self._handlers) do
      self:_handle(handler)
    end
    self._handlers = {}
  end)
end

---Handle a single handler.
---@param handler table
function Promise:_handle(handler)
  if self._state == "pending" then
    table.insert(self._handlers, handler)
    return
  end

  local callback = self._state == "fulfilled" and handler.on_fulfilled or handler.on_rejected

  if not callback then
    if self._state == "fulfilled" then
      handler.resolve(self._value)
    else
      handler.reject(self._value)
    end
    return
  end

  local ok, result = pcall(callback, self._value)
  if ok then
    handler.resolve(result)
  else
    handler.reject(result)
  end
end

---Chain a callback to run when this promise is fulfilled.
---@param on_fulfilled? fun(value: any): any
---@param on_rejected? fun(reason: any): any
---@return droid.Promise
function Promise:next(on_fulfilled, on_rejected)
  return Promise.new(function(resolve, reject)
    self:_handle({
      on_fulfilled = on_fulfilled,
      on_rejected = on_rejected,
      resolve = resolve,
      reject = reject,
    })
  end)
end

---Chain a callback to run when this promise is rejected.
---@param on_rejected fun(reason: any): any
---@return droid.Promise
function Promise:catch(on_rejected)
  return self:next(nil, on_rejected)
end

---Create a promise that resolves with the given value.
---@param value any
---@return droid.Promise
function Promise.resolve(value)
  return Promise.new(function(resolve)
    resolve(value)
  end)
end

---Create a promise that rejects with the given reason.
---@param reason any
---@return droid.Promise
function Promise.reject(reason)
  return Promise.new(function(_, reject)
    reject(reason)
  end)
end

---Create a promise that resolves when all given promises resolve.
---@param promises droid.Promise[]
---@return droid.Promise
function Promise.all(promises)
  return Promise.new(function(resolve, reject)
    local results = {}
    local remaining = #promises

    if remaining == 0 then
      resolve(results)
      return
    end

    for i, promise in ipairs(promises) do
      promise
        :next(function(value)
          results[i] = value
          remaining = remaining - 1
          if remaining == 0 then
            resolve(results)
          end
        end)
        :catch(function(reason)
          reject(reason)
        end)
    end
  end)
end

return Promise
