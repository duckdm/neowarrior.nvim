local DateTime = require('neowarrior.DateTime')
local TaskCollection = require('neowarrior.TaskCollection')

---@class Task
---@field neowarrior NeoWarrior
---@field id number|nil
---@field status string|nil
---@field description string|nil
---@field project string|nil
---@field priority string|nil
---@field due number
---@field due_dt DateTime|nil
---@field tags table|nil
---@field entry number
---@field entry_dt DateTime|nil
---@field modified number
---@field modified_dt DateTime|nil
---@field uuid string|nil
---@field urgency number|nil
---@field estimate number|nil
---@field estimate_string number|nil
---@field start number
---@field start_dt DateTime|nil
---@field end number
---@field end_dt DateTime|nil
---@field wait number
---@field wait_dt DateTime|nil
---@field scheduled number
---@field scheduled_dt DateTime|nil
---@field depends TaskCollection|nil
---@field parents TaskCollection|nil
---@field annotations table|nil
---@field recur string|nil
local Task = {}

--- Create new task
---@param task_data table
---@return Task
function Task:new(task_data)

  local data = {}
  setmetatable(data, self)
  self.__index = self

  data.id = task_data.id or nil
  data.uuid = task_data.uuid or nil
  data.status = task_data.status or nil
  data.description = task_data.description or nil
  data.project = task_data.project or _Neowarrior.config.no_project_name
  data.priority = task_data.priority or nil
  data.tags = task_data.tags or nil
  data.urgency = task_data.urgency or nil
  data.recur = task_data.recur or nil
  if task_data.estimate and type(task_data.estimate) == "string" then
    data.estimate = tonumber(task_data.estimate) or nil
    data.estimate_string = task_data.estimate
  else
    data.estimate = task_data.estimate or nil
    data.estimate_string = self:get_hour_duration_string(task_data.estimate)
  end
  data.depends = self:create_dependency_collection(task_data.depends)
  data.parents = nil
  -- TODO: Probably need a specific class for annotations (similar
  -- to TaskCollection).
  -- if task_data.annotations then
  --   local anno_collection = TaskCollection:new()
  --   for _, annotation in ipairs(task_data.annotations) do
  --     anno_collection:add(annotation)
  --   end
  -- else
  --   data.annotations = nil
  -- end
  data.annotations = task_data.annotations or nil
  data.recur = task_data.recur or nil

  data.due_dt = self:get_date_time_object(task_data.due)
  data.due = data.due_dt and data.due_dt.timestamp or 0
  data.entry_dt = self:get_date_time_object(task_data.entry)
  data.entry = data.entry_dt and data.entry_dt.timestamp or 0
  data.modified_dt = self:get_date_time_object(task_data.modified)
  data.modified = data.modified_dt and data.modified_dt.timestamp or 0
  data.start_dt = self:get_date_time_object(task_data.start)
  data.start = data.start_dt and data.start_dt.timestamp or 0
  data['end_dt'] = self:get_date_time_object(task_data['end'])
  data['end'] = data['end'] and data['end'].timestamp or 0
  data.wait_dt = self:get_date_time_object(task_data.wait)
  data.wait = data.wait_dt and data.wait_dt.timestamp or 0
  data.scheduled_dt = self:get_date_time_object(task_data.scheduled)
  data.scheduled = data.scheduled_dt and data.scheduled_dt.timestamp or 0

  return data
end

--- Create a collection of dependency tasks from uuids
---@param uuids string[]|nil
---@return TaskCollection|nil
function Task:create_dependency_collection(uuids)

  if not uuids then
    return nil
  end

  local collection = TaskCollection:new()

  for _, uuid in ipairs(uuids) do
    local task = _Neowarrior.all_pending_tasks:find(uuid)
    if task then
      collection:add(task)
    end
  end

  return collection
end

--- Create a collection of parent tasks
---@return TaskCollection|nil
function Task:create_parent_collection()

  local parents = TaskCollection:new()
  for _, task in ipairs(_Neowarrior.all_tasks:get()) do
    if task.depends and task.depends:count() > 0 then
      for _, dependency in ipairs(task.depends:get()) do
        if dependency.uuid == self.uuid then
          parents:add(task)
        end
      end
    end
  end

  if parents:count() == 0 then
    return nil
  end

  return parents
end

function Task:get_hour_duration_string(duration)
  local no = tonumber(duration)
  if not no then
    return ''
  end
  if no < 1 then
    local minutes = 60 * no
    return minutes .. "m"
  end
  return no .. "h"
end

function Task:get_date_time_object(value)
  if value then
    return DateTime:new(value)
  end
  return nil
end

function Task:get_attributes()
  return {
    id = self.id,
    status = self.status,
    description = self.description,
    project = self.project,
    priority = self.priority,
    tags = self.tags,
    uuid = self.uuid,
    ['end'] = self['end'],
    wait = self.wait,
    recur = self.recur,
  }
end

return Task
