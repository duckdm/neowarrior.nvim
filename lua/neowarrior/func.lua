local Util = require("neowarrior.util")
local M = {}

--- Set all tasks
---@param allTasks table
---@param allTasksByProject table
---@param opt table
M.all_tasks = function(allTasks, allTasksByProject, projects, opt)
  local cmd = "task description.not: limit:10000 export all"
  local json_data = vim.fn.system(cmd)
  local exported_tasks = vim.json.decode(json_data:match("%b[]"))
  for _, export in ipairs(exported_tasks) do
    if not Util.in_table(allTasks, { key = 'uuid', value = export.uuid }) then
      table.insert(allTasks, export)
      local tproj = opt.no_project_name
      if export.project then
        tproj = export.project
      end
      if not allTasksByProject[tproj] then
        allTasksByProject[tproj] = {
          name = tproj,
          tasks = {},
        }
      end
      table.insert(allTasksByProject[tproj].tasks, export)
      M.fill_project_tables(tproj, projects, opt)
    end
  end
end

--- Add project to project tables
---@param project_name string
---@param projects table
---@param opt table
M.add_to_project_tables = function(project_name, projects, opt)
  local found = false
    for _, prj in ipairs(projects) do
      if prj == project_name then
        found = true
        break
      end
    end

    if found == false then
      table.insert(projects, project_name)
      table.insert(opt.filters, "project:" .. project_name)
      table.insert(opt.filters, "project.not:" .. project_name)
    end
end

--- Fill project tables
---@param project string
---@param projects table
---@param opt table
M.fill_project_tables = function(project, projects, opt)
  local parts = { project }
  if string.find(project, '.') then
    parts = Util.split_string(project, ".")
  end

  local last = ''

  for _, part in ipairs(parts) do
    local project_name = last
    if project_name == '' then
      project_name = part
    else
      project_name = project_name .. '.' .. part
    end
    last = project_name
    M.add_to_project_tables(project_name, projects, opt)
  end
end

--- Find task by UUID
---@param uuid string
---@param tasks table
---@return table|nil
M.find_task_by_uuid = function(uuid, tasks)
  local found_task = nil
  for _, task in ipairs(tasks) do
    if task.uuid == uuid then
      found_task = task
      break
    end
  end
  return found_task
end

--- Check if task has pending dependencies
---@param dependency_uuids table
---@param all_tasks table
---@return boolean
M.has_pending_dependencies = function(dependency_uuids, all_tasks)
  local not_completed = {}
  if dependency_uuids and Util.table_size(dependency_uuids) > 0 then
    for _, uuid in ipairs(dependency_uuids) do
      local task = M.find_task_by_uuid(uuid, all_tasks)
      if task and task.status ~= "completed" then
        table.insert(not_completed, task)
      end
    end
  end
  if Util.table_size(not_completed) > 0 then
    return true
  end
  return false
end

--- Get estimate string
---@param est string|number
---@return string
M.get_estimate_string = function(est)
  local est_no = tonumber(est)
  if est_no < 1 then
    local minutes = 60 * est_no
    return minutes .. "m"
  end
  return est_no .. "h"
end

--- Get estimate color
---@param est number
---@return string
M.get_estimate_color = function(est)
  if est then
    if est < 1 then
      return "NeoWarriorTextSuccess"
    elseif est < 8 then
      return "NeoWarriorTextInfo"
    end
  end
  return "NeoWarriorTextWarning"
end

--- Get due color
---@param due string
---@return string
M.get_due_color = function(due)
  if string.find(due, "-") then
    return "NeoWarriorTextDangerBg"
  end
  if (string.find(due, "m") and not (string.find(due, "mon"))) or string.find(due, "h") then
    return "NeoWarriorTextDanger"
  elseif string.find(due, "d") then
    local no_days = tonumber(string.match(due, "%d+"))
    if no_days <= 7 then
      return "NeoWarriorTextWarning"
    end
  end
  return "NeoWarriorTextInfo"
end

---@param urgency string|number
---@return string
M.get_urgency_color = function(urgency)
  if not urgency then
    return "NeoWarriorTextDim"
  end
  if (urgency + 0.0) >= 10 then
    return "NeoWarriorTextDanger"
  end
  if (urgency + 0.0) >= 5 then
    return "NeoWarriorTextWarning"
  end
  return "NeoWarriorTextDim"
end

--- Get priority color
---@param priority string|nil
---@return string|nil
M.get_priority_color = function(priority)
  if priority == "H" then
    return "NeoWarriorTextDanger"
  end
  if priority == "M" then
    return "NeoWarriorTextWarning"
  end
  if priority == "L" then
    return "NeoWarriorTextSuccess"
  end
  return nil
end

---@param line string
---@param key string
---@return string|nil
M.get_meta_data = function(line, key)
  local pattern = "{{{" .. key .. ".-}}}"
  local value = nil
  for id in string.gmatch(line, pattern) do
    value = string.gsub(string.gsub(id, "{{{" .. key, ""), "}}}", "")
  end
  return value
end

--- Get project/category from meta data
---@param line string
---@return string|nil
M.get_category = function(line)
  return M.get_meta_data(line, "category")
end

--- Check if tree item is toggled
---@param category string
---@param toggled_trees table
---@return boolean
M.tree_is_toggled = function(category, toggled_trees)
  for _, cat in ipairs(toggled_trees) do
    if cat == category then
      return true
    end
  end
  return false
end

---@param toggled_trees table
---@return nil
M.toggle_tree = function(toggled_trees)
  local ca = M.get_category(vim.api.nvim_get_current_line())
  if ca then
    if M.tree_is_toggled(ca, toggled_trees) then
      for k, v in ipairs(toggled_trees) do
        if v == ca then
          table.remove(toggled_trees, k)
        end
      end
    else
      table.insert(toggled_trees, ca)
    end
  end
end

return M
