local M = {}

--- Get task
---@param uuid string
---@return table
M.task = function(uuid)
  local json_data = vim.fn.system("task " .. uuid .. " export")
  local task = vim.json.decode(json_data)
  return task[1]
end

--- Get tasks
---@param report string
---@param filter string
---@return table
M.tasks = function(report, filter)
  local default_limit = " limit:1000000 "
  if filter and string.find(filter, "limit:") then
    default_limit = ""
  end
  local cmd = "task " .. default_limit .. "export " .. report
  if filter then
    cmd = "task " .. default_limit .. filter .. " export " .. report
  end
  local json_data = vim.fn.system(cmd)
  return vim.json.decode(json_data:match("%b[]"))
end

--- Modify task
---@param uuid string
---@param mod_string string
M.modify = function(uuid, mod_string)
  if not (mod_string == "") then
    vim.fn.system("task modify " .. uuid .. " " .. mod_string)
  end
end

--- Add task
---@param task string
M.add = function(task)
  vim.fn.system("task add " .. task)
end

-- Add dependency
---@param uuid string
---@param dependency string
M.add_dependency = function(uuid, dependency)
  vim.fn.system("task " .. uuid .. " modify depends:" .. dependency)
end

--- Add annotation
---@param uuid string
---@param annotation string
M.annotate = function(uuid, annotation)
  vim.fn.system("task annotate " .. uuid .. " " .. annotation)
end

--- Complete task / mark done
---@param uuid string
M.complete = function(uuid)
  vim.fn.system("task done " .. uuid)
end

--- Delete task
--- TODO: make this work
---@param uuid 
M.delete = function(uuid)
  vim.fn.confirm("Use CLI to delete tasks", "OK")
end

return M
