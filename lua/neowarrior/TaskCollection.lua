local util = require "neowarrior.util"

---@class TaskCollection
---@field task_collection Task[]
---@field new fun(self: TaskCollection): TaskCollection
---@field add fun(self: TaskCollection, task: Task): nil
---@field sort fun(self: TaskCollection, key: string): TaskCollection
---@field get fun(self: TaskCollection): Task[]
---@field find_max fun(self: TaskCollection, key: string): number
---@field find_min fun(self: TaskCollection, key: string): number
---@field find_task_by_uuid fun(self: TaskCollection, uuid: string): Task|nil
---@field find_task_by_key fun(self: TaskCollection, key: string, value: string): Task|nil
---@field count fun(self: TaskCollection): number
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

--- Sort task collection
---@param key string
---@return TaskCollection
function TaskCollection:sort(key)
  local tasks_array = {}
  for _, proj in pairs(self.task_collection) do
    table.insert(tasks_array, proj)
  end
  table.sort(tasks_array, function(a, b)
    if key:find('%.') then
        local keys = util.split_string(key, '.')
        return a[keys[1]][keys[2]] > b[keys[1]][keys[2]]
    end
    return a[key] > b[key]
  end)
  self.task_collection = tasks_array

  return self
end

--- Get task_collection
---@return Task[]
function TaskCollection:get()
  return self.task_collection
end

--- Find task by uuid
---@param uuid string
function TaskCollection:find(uuid)
  for _, task in ipairs(self.task_collection) do
    if task.uuid == uuid then
      return task
    end
  end
  return nil
end

--- Find max task_collection
---@param key string
---@return number
function TaskCollection:find_max(key)
  local max = 0
  for _, task in ipairs(self.task_collection) do
    if task[key] > max then
      max = task[key]
    end
  end
  return max
end

--- Find min task_collection
---@param key string
---@return number
function TaskCollection:find_min(key)
  local min = 0
  for _, task in ipairs(self.task_collection) do
    if task[key] < min then
      min = task[key]
    end
  end
  return min
end

-- Find task by uuid
---@param uuid string
---@return Task|nil
function TaskCollection:find_task_by_uuid(uuid)
  return self:find_task_by_key("uuid", uuid)
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
