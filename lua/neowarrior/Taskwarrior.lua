local Task = require("neowarrior.Task")
local TaskCollection = require("neowarrior.TaskCollection")

---@class Taskwarrior
---@field neowarrior NeoWarrior
---@field syscall fun(self: Taskwarrior, cmd: string): string
local Taskwarrior = {}

--- Create new taskwarrior instance
---@param neowarrior NeoWarrior
---@return Taskwarrior
function Taskwarrior:new(neowarrior)
  local taskwarrior = {}
  setmetatable(taskwarrior, self)
  self.__index = self

  taskwarrior.neowarrior = neowarrior

  return taskwarrior
end

--- Execute system call
---@param cmd string
---@return string
function Taskwarrior:syscall(cmd)
  return vim.fn.system(cmd)
end

--- Get single task by UUID
---@param uuid string
---@return Task
function Taskwarrior:task(uuid)

  local json_data = self:syscall("task " .. uuid .. " export")
  local task = vim.json.decode(json_data)

  return Task:new(self.neowarrior, task[1])
end

--- Get tasks
---@param report string
---@param filter string
---@return TaskCollection
function Taskwarrior:tasks(report, filter)

  local default_limit = " limit:1000000 "

  if filter and string.find(filter, "limit:") then
    default_limit = ""
  end
  local cmd = "task " .. default_limit .. "export " .. report

  if filter then
    cmd = "task " .. default_limit .. filter .. " export " .. report
  end

  local json_data = self:syscall(cmd)
  local data = vim.json.decode(json_data:match("%b[]"))
  local task_collection = TaskCollection:new()

  --- NOTE: We use the constructor of Task here (instead of perhaps
  --- a task_collection:set method) to parse and process some
  --- of the data, like dates etc.
  --- TODO: Make set method that can handle all that jazz too
  for _, task in ipairs(data) do
    task_collection:add(Task:new(self.neowarrior, task))
  end

  return task_collection
end

--- Add new task
---@param input string
function Taskwarrior:add(input)
  self:syscall("task add " .. input)
end
---
--- Modify task
---@param task Task
---@param mod_string string
function Taskwarrior:modify(task, mod_string)
  if not (mod_string == "") then
    self:syscall("task modify " .. task.uuid .. " " .. mod_string)
  end
end
--
-- Add dependency
---@param task Task
---@param dependency_uuid string
function Taskwarrior:add_dependency(task, dependency_uuid)
  self:syscall("task " .. task.uuid .. " modify depends:" .. dependency_uuid)
end

--- Start task
---@param task Task
---@return Task
function Taskwarrior:start(task)
  self:syscall("task start " .. task.uuid)
  return Taskwarrior:task(task.uuid)
end

--- Stop task
---@param task Task
function Taskwarrior:stop(task)
  self:syscall("task stop " .. task.uuid)
  return Taskwarrior:task(task.uuid)
end

--- Annotate task
---@param task Task
---@param annotation string
function Taskwarrior:annotate(task, annotation)
  self:syscall("task annotate " .. task.uuid .. " " .. annotation)
end
---
--- Complete task / mark done
---@param task Task
function Taskwarrior:done(task)
  self:syscall("task done " .. task.uuid)
end

--- Delete task
--- TODO: make this work
---@param task Task 
function Taskwarrior:delete(task)
  vim.fn.confirm("Use CLI to delete task\n[" .. task.description .. "]", "OK")
end

return Taskwarrior
