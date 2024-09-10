local util = require "neowarrior.util"

---@class TaskCollection
---@field task_collection Task[]
local TaskCollection = {}

--- Create new task_collection collection
---@return TaskCollection
function TaskCollection:new()
  local task_collection = {}
  setmetatable(task_collection, self)
  self.__index = self

  task_collection.task_collection = {}

  return task_collection
end

--- Add task
---@param task Task
function TaskCollection:add(task)
  table.insert(self.task_collection, task)
end

--- Get task_collection
---@return Task[]
function TaskCollection:get()
  return self.task_collection
end

-- Find task by uuid
-- @param uuid string
-- @return Task|nil
function TaskCollection:find_task_by_uuid(uuid)
  self:find_task_by_key("uuid", uuid)
end

--- Find task by key
---@param key string
---@param value string
---@return Task|nil
function TaskCollection:find_task_by_key(key, value)
  for _, task in ipairs(self.task_collection) do
    if task[key] == value then
      return task
    end
  end
  return nil
end

--- Get task count
---@return number
function TaskCollection:count()
  return util.table_size(self.task_collection)
end

return TaskCollection
