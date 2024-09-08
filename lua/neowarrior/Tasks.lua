---@class Tasks
---@field tasks Task[]
local Tasks = {}

--- Create new tasks collection
---@return Tasks
function Tasks:new()
  local tasks = {}
  setmetatable(tasks, self)
  self.__index = self

  tasks.tasks = {}

  return tasks
end

--- Add task
---@param task Task
function Tasks:add(task)
  table.insert(task, task)
end

--- Get tasks
---@return Task[]
function Tasks:get()
  return self.tasks
end
