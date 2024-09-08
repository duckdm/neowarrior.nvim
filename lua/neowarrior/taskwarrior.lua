local Task = require("Task")
local Tasks = require("Tasks")
local M = {}

--- Get task
---@param uuid string
---@return Task
function M.task(uuid)
  local json_data = vim.fn.system("task " .. uuid .. " export")
  local task = vim.json.decode(json_data)

  return Task:new(task[1])
end

--- Get tasks
---@param report string
---@param filter string
---@return Tasks
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
  local data = vim.json.decode(json_data:match("%b[]"))
  local tasks = Tasks:new()

  for _, task in ipairs(data) do
    tasks:add(Task:new(task))
  end

  return tasks
end

return M
