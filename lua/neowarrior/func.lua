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

--- Get meta data from current line
---@param key string
---@return string|nil
M.get_line_meta_data = function(key)
  local line = vim.api.nvim_get_current_line()
  return M.get_meta_data(line, key)
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
