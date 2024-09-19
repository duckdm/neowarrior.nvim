local DateTime = require('neowarrior.DateTime')
local TaskCollection = require('neowarrior.TaskCollection')

---@class Task
---@field neowarrior NeoWarrior
---@field id number|nil
---@field status string|nil
---@field description string|nil
---@field project string|nil
---@field priority string|nil
---@field due DateTime|nil
---@field tags table|nil
---@field entry DateTime|nil
---@field modified DateTime|nil
---@field uuid string|nil
---@field urgency number|nil
---@field estimate number|nil
---@field estimate_string number|nil
---@field start DateTime|nil
---@field end DateTime|nil
---@field wait DateTime|nil
---@field scheduled DateTime|nil
---@field depends TaskCollection|nil
---@field parents TaskCollection|nil
---@field annotations table|nil
---@field recur string|nil
local Task = {}

--- Create new task
---@param neowarrior NeoWarrior
---@param task_data table
---@return Task
function Task:new(neowarrior, task_data)

  local data = {}
  setmetatable(data, self)
  self.__index = self

  data.id = task_data.id or nil
  data.uuid = task_data.uuid or nil
  data.status = task_data.status or nil
  data.description = task_data.description or nil
  data.project = task_data.project or neowarrior.config.no_project_name
  data.priority = task_data.priority or nil
  data.tags = task_data.tags or nil
  data.urgency = task_data.urgency or nil
  data.recur = task_data.recur or nil
  data.estimate = task_data.estimate or nil
  data.estimate_string = self:get_hour_duration_string(task_data.estimate)
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

  data.due = self:get_date_time_object(task_data.due)
  data.entry = self:get_date_time_object(task_data.entry)
  data.modified = self:get_date_time_object(task_data.modified)
  data.start = self:get_date_time_object(task_data.start)
  data['end'] = self:get_date_time_object(task_data['end'])
  data.wait = self:get_date_time_object(task_data.wait)
  data.scheduled = self:get_date_time_object(task_data.scheduled)

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
  for _, task in ipairs(_Neowarrior.all_pending_tasks:get()) do
    if task.depends then
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
    due = self.due,
    tags = self.tags,
    entry = self.entry,
    modified = self.modified,
    uuid = self.uuid,
    urgency = self.urgency,
    estimate = self.estimate,
    start = self.start,
    ['end'] = self['end'],
    wait = self.wait,
    scheduled = self.scheduled,
    depends = self.depends,
    annotations = self.annotations,
    recur = self.recur,
  }
end

return Task
