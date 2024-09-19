local TaskCollection = require('neowarrior.TaskCollection')

local TaskUtil = {}

--- Check if task has dependencies in provided collection
---@param task Task
---@param task_collection TaskCollection
---@return boolean|TaskCollection
function TaskUtil.has_dependencies(task, task_collection)

  if task.depends then

    local dependencies = TaskCollection:new()

    for _, dependency in ipairs(task.depends) do
      local dependency_task = task_collection:find_task_by_uuid(dependency.uuid)
      if dependency_task then
        dependencies:add(dependency_task)
      end
    end

    if dependencies:count() > 0 then
      return dependencies
    end
  end

  return false
end

return TaskUtil
