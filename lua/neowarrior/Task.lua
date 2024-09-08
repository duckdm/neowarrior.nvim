---@class Task
---@field description string|nil
---@field project string|nil
---@field priority string|nil
---@field due DateTime
---@field tags table|nil
---@field status string|nil
---@field entry DateTime
---@field modified DateTime
---@field uuid string|nil
---@field urgency number|nil
---@field estimate number|nil
---@field start DateTime
---@field end DateTime
---@field wait DateTime
---@field scheduled DateTime
---@field depends Tasks|nil
---@field annotations table|nil
---@field recurrence string|nil
local Task = {}

--- Create new task
---@param data table
---@return Task
function Task:new(data)

  local task = {}
  setmetatable(task, self)
  self.__index = self

  task.description = data.description or nil
  task.project = data.project or nil
  task.priority = data.priority or nil
  task.due = data.due or nil
  task.tags = data.tags or nil
  task.status = data.status or nil
  task.entry = data.entry or nil
  task.modified = data.modified or nil
  task.uuid = data.uuid or nil
  task.urgency = data.urgency or nil
  task.estimate = data.estimate or nil
  task.start = data.start or nil
  task['end'] = data['end'] or nil
  task.wait = data.wait or nil
  task.scheduled = data.scheduled or nil
  task.depends = data.depends or nil
  task.annotations = data.annotations or nil
  task.recurrence = data.recurrence or nil

  return task
end

return Task
