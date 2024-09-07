local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Buffer = require("neowarrior.buffer")
local Util = require("neowarrior.util")
local Time = require("neowarrior.time")
local Func = require("neowarrior.func")
local Data = require("neowarrior.data")
local opt = require("neowarrior.opt")

local M = {}

local user_opt = {}
local pad = 0
local bufnr = -1
local grouped = false
local treeview = false
local icons = {
  task = "\u{f1db}",
  task_completed = "\u{f14a}",
  recur = "\u{f021}",
  project = "\u{f07b}",
  warning = "\u{f071}",
  annotated = "\u{f1781}",
  start = "\u{f040a}",
  due = "\u{f1442}",
  est = "\u{f0520}",
  deleted = "\u{f014}",
  depends = "\u{f111}",
}
local NWLines = {}
local NWLineColors = {}
local NWLineCount = 0
local NWCurrentTask = nil
local NWAllTasks = {}
local NWAllTasksByProject = {}
local NWTasks = {}
local NWTasksByProject = {}
local NWProjectTree = {}
local NWProjects = {}
local NWToggledTrees = {}
local NWCurrentReport = "next"
local NWCurrentFilter = nil
local NWRecentFilters = {}

--- Set options
---@param o table
local set_opts = function(o)
  if o and Util.table_size(o) > 0 then
    opt = vim.tbl_deep_extend('force', opt, o)
  end

  if opt.dir_setup and Util.table_size(opt.dir_setup) > 0 then
    local cwd = vim.uv.cwd()
    for _, dir_setup in ipairs(opt.dir_setup) do
      if dir_setup.dir == cwd then
        opt = vim.tbl_deep_extend('force', opt, dir_setup)
      end
    end
  end
end

local init = function()
  if opt.mode and opt.mode == "grouped" then
    grouped = true
  elseif opt.mode and opt.mode == "tree" then
    treeview = true
  else
    grouped = false
    treeview = false
  end
  if opt.report then
    NWCurrentReport = opt.report
  end
  if opt.filter then
    NWCurrentFilter = opt.filter
  end
end

local function set_colors()
  vim.cmd("highlight NeoWarriorTextDim guifg=#666666")
  vim.cmd("highlight NeoWarriorTextDanger guifg=#cc0000")
  vim.cmd("highlight NeoWarriorTextWarning guifg=#ccaa00")
  vim.cmd("highlight NeoWarriorTextSuccess guifg=#00cc00")
  vim.cmd("highlight NeoWarriorTextInfo guifg=#00aaff")
  vim.cmd("highlight NeoWarriorGroup guifg=#00aaff")
  vim.cmd("highlight NeoWarriorVirt guifg=#00aaff guibg=#000000")
  vim.cmd("highlight NeoWarriorHide guifg=#000000 guibg=#000000")

  vim.cmd("highlight NeoWarriorTextDefaultBg guifg=#ffffff guibg=#333333")
  vim.cmd("highlight NeoWarriorTextInfoBg guifg=#ffffff guibg=#005588")
  vim.cmd("highlight NeoWarriorTextDangerBg guifg=#ffffff guibg=#cc0000")
end

local function update_all_tasks()
  Func.all_tasks(NWAllTasks, NWAllTasksByProject, NWProjects, opt)
end

--- Get largest value from table
---@param tasks table
---@param key string Key to use for comparison
---@return number
local function max(tasks, key)
  local max_value = 0
  for _, task in ipairs(tasks) do
    if task[key] and task[key] > max_value then
      max_value = task[key]
    end
  end
  return max_value
end

---Get sum of values from table
---@param tasks table
---@param key string Table key to sum
---@return number
local function sum(tasks, key)
  local total = 0
  for _, task in ipairs(tasks) do
    if task[key] then
      total = total + tonumber(task[key])
    end
  end
  return total
end

---
---@param tree table
---@param parts table
---@param index integer
---@param parent_key string
local function insert_into_tree(tree, parts, index, parent_key)
  if index > #parts then
    return
  end
  local part = parts[index]
  if string.len(part) > pad then
    pad = string.len(part)
  end
  local key = parent_key .. "." .. part
  if parent_key == "" then
    key = part
  end

  if not tree.categories[key] then
    local total_urgency = ""
    local max_urgency_val = 0
    local max_urgency = ""
    local avg_urgency_val = 0
    local avg_urgency = ""
    local task_count = 0
    local total_est_val = 0
    local total_est = ""
    if NWTasksByProject[key] then
      local urgency_val = sum(NWTasksByProject[key].tasks, "urgency")
      max_urgency_val = max(NWTasksByProject[key].tasks, "urgency")
      task_count = Util.table_size(NWTasksByProject[key].tasks)
      total_urgency = string.format("%f", urgency_val)
      max_urgency = string.format("%.1f", max_urgency_val)
      avg_urgency_val = urgency_val / task_count
      avg_urgency = string.format("%.1f", avg_urgency_val)
      total_est_val = sum(NWTasksByProject[key].tasks, "estimate")
      total_est = string.format("%.1f", total_est_val)
      local tasks = NWTasksByProject[key].tasks
      NWTasksByProject[key] = {
        name = key,
        key = key,
        urgency = total_urgency,
        max_urgency = max_urgency,
        max_urgency_val = max_urgency_val,
        avg_urgency = avg_urgency,
        avg_urgency_val = avg_urgency_val,
        total_est_val = total_est_val,
        total_est = total_est,
        task_count = task_count,
        tasks = tasks,
      }
    end
    tree.task_count = tree.task_count + task_count
    tree.categories[key] = {
      name = part,
      key = key,
      urgency = total_urgency,
      max_urgency = max_urgency,
      max_urgency_val = max_urgency_val,
      avg_urgency = avg_urgency,
      avg_urgency_val = avg_urgency_val,
      total_est_val = total_est_val,
      total_est = total_est,
      task_count = task_count,
      categories = {},
    }
  end

  insert_into_tree(tree.categories[key], parts, index + 1, key)
end

local function generate_tree(categories)
  local tree = {
    name = "",
    key = "",
    urgency = "",
    max_urgency = "",
    max_urgency_val = 0.0,
    avg_urgency = "",
    avg_urgency_val = 0.0,
    task_count = 0,
    categories = {},
  }

  for _, category in ipairs(categories) do
    local parts = Util.split_string(category, ".")
    insert_into_tree(tree, parts, 1, "")
  end

  return tree
end

--- Sort tree by key
---@param project_tree table Tree object
---@param key string Key to sort by
---@return table
local function sort_project_tree(project_tree, key)
  local projects_array = {}
  for _, proj in pairs(project_tree.categories) do
    table.insert(projects_array, sort_project_tree(proj, key))
  end
  table.sort(projects_array, function(a, b)
    return a[key] > b[key]
  end)
  project_tree.categories = projects_array
  return project_tree
end


local parse_export = function(exports)
  local tprojs = {}
  NWTasks = {}
  NWTasksByProject = {}
  for _, export in ipairs(exports) do
    table.insert(NWTasks, export)
    local tproj = opt.no_project_name
    if export.project then
      tproj = export.project
    end
    if not NWTasksByProject[tproj] then
      NWTasksByProject[tproj] = {
        name = tproj,
        tasks = {},
      }
    end
    table.insert(NWTasksByProject[tproj].tasks, export)
    table.insert(tprojs, tproj)
  end
  NWProjectTree = generate_tree(tprojs)

  return sort_project_tree(NWProjectTree, "max_urgency_val")
end

local L = {}

L.reset = function()
  NWLines = {}
  NWLineColors = {}
  NWLineCount = 0
end

L.add = function(lines, colors)
  if type(lines) == "string" then
    table.insert(NWLines, lines)
    NWLineCount = NWLineCount + 1
  else
    for _, line in ipairs(lines) do
      table.insert(NWLines, line)
      NWLineCount = NWLineCount + 1
    end
  end
  for _, color in ipairs(colors) do
    table.insert(NWLineColors, color)
  end
end

---@param arg table { data = table, indent = string, disable_meta = boolean, disable_priority = boolean, disable_warning = boolean, disable_due = boolean, disable_description = boolean, disable_recur = boolean, disable_task_icon = boolean, disable_estimate = boolean, disable_annotations = boolean, disable_start = boolean }
---@return table { line = string, colors = table }
L.task = function(arg)
  local data = arg.data
  if not data then
    return { line = "n/a or invalid data", colors = {} }
  end
  local indent = arg.indent or ""
  local disable_meta = arg.disable_meta or false
  local disable_priority = arg.disable_priority or false
  local disable_warning = arg.disable_warning or false
  local disable_due = arg.disable_due or false
  local disable_description = arg.disable_description or false
  local disable_recur = arg.disable_recur or false
  local disable_task_icon = arg.disable_task_icon or false
  local disable_estimate = arg.disable_estimate or false
  local disable_annotations = arg.disable_annotations or false
  local disable_start = arg.disable_start or false
  local project = data.project or opt.no_project_name
  local meta = arg.meta or nil
  local description = ""
  if data.description then
    description = tostring(string.gsub(data.description, "\n", ""))
  end
  local estimate_string = ""
  if data.estimate then
    estimate_string = Func.get_estimate_string(data.estimate)
  end
  local urgency_val = data.urgency or 0.0
  if grouped then
    project = ""
  end
  local priority = data.priority or "-"
  local due = data.due or nil
  if due then
    due = Time.relative(due)
  else
    due = ""
  end
  local task_icon = icons.task
  local task_icon_color = "NeoWarriorTextDim"
  if data.start then
    task_icon_color = "NeoWarriorTextDanger"
  end
  if data.status and data.status == "completed" then
    task_icon = icons.task_completed
    task_icon_color = "NeoWarriorTextSuccess"
  end
  if data.status and data.status == "deleted" then
    task_icon = icons.deleted
    task_icon_color = "NeoWarriorTextWarning"
  end
  if Func.has_pending_dependencies(data.depends, NWAllTasks) then
    task_icon = icons.depends
    task_icon_color = "NeoWarriorTextDanger"
  end
  local meta_table = {
    uuid = data.uuid,
    description = description,
    category = project,
    project = project,
    priority = priority,
    urgency = urgency_val,
    due = due,
    estimate = data.estimate,
  }
  if meta then
    for k, v in pairs(meta) do
      meta_table[k] = v
    end
  end
  local task_line = Buffer.create_line(NWLineCount, {
    {
      text = indent,
    },
    {
      text = task_icon .. " ",
      color = task_icon_color,
      disable = disable_task_icon,
    },
    {
      text = icons.start .. " ",
      color = "NeoWarriorTextDanger",
      disable = not data.start or disable_start,
    },
    {
      text = icons.warning .. " ",
      color = Func.get_urgency_color(urgency_val),
      disable = (urgency_val < 5 or disable_warning),
    },
    {
      text = priority .. " ",
      color = Func.get_priority_color(priority),
      disable = (priority == "-" or disable_priority),
    },
    {
      text = icons.recur .. " ",
      color = "NeoWarriorTextInfo",
      disable = (not data.recur or disable_recur),
    },
    {
      text = icons.due .. "" .. due .. " ",
      color = Func.get_due_color(due),
      disable = (due == "" or disable_due),
    },
    {
      text = icons.est .. "" .. estimate_string .. " ",
      color = Func.get_estimate_color(data.estimate),
      disable = not data.estimate or disable_estimate,
    },
    {
      text = icons.annotated .. " ",
      color = "NeoWarriorTextInfo",
      disable = not data.annotations or disable_annotations,
    },
    {
      text = description,
      disable = disable_description,
    },
    {
      disable = disable_meta,
      meta = meta_table,
    },
  })

  return { line = task_line[1], colors = task_line[2] }
end

L.tasks = function(project, level)
  local indent = ""
  if level > 0 then
    indent = "  " .. string.rep("  ", level)
  end
  local tasks = nil
  if type(project) == "string" and NWTasksByProject[project] and NWTasksByProject[project].tasks then
    tasks = NWTasksByProject[project].tasks
  else
    tasks = project
  end
  if tasks then
    for _, task in ipairs(tasks) do
      local task_line_object = L.task({ data = task, indent = indent })
      L.add(task_line_object.line, task_line_object.colors)
    end
  end
end

L.print = function(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, NWLines)
  for _, color in ipairs(NWLineColors) do
    if color and color.line and color.group and color.from and color.to then
      vim.api.nvim_buf_add_highlight(bufnr, -1, color.group, color.line, color.from, color.to)
    end
  end
  L.reset()
end

L.treeview = function(cs, level)
  local indent = string.rep("  ", level)
  for _, ps in pairs(cs.categories) do
    local max_urgency = ps.max_urgency
    local avg_urgency = ps.avg_urgency
    local count = ps.task_count
    local project_count = Util.table_size(ps.categories)
    local urgency_color = ""
    local project_count_indicator = ""
    if project_count > 0 then
      project_count_indicator = icons.project .. " " .. project_count .. " "
    end
    local count_indicator = ""
    if count > 0 then
      count_indicator = icons.task .. " " .. count .. " "
    end
    if not (max_urgency == "") then
      urgency_color = Func.get_urgency_color(max_urgency + 0.0)
    end
    local avg_urgency_color = ""
    if not (avg_urgency == "") then
      avg_urgency_color = Func.get_urgency_color(avg_urgency + 0.0)
    end

    local total_est_color = ""
    if not (ps.total_est == "") then
      total_est_color = Func.get_estimate_color(ps.total_est_val)
    end

    local project_pad = pad - (level * 2)
    if string.find(ps.name, "ä") or string.find(ps.name, "ö") or string.find(ps.name, "å") then
      project_pad = project_pad + 1
    end

    local prj = Buffer.create_line(NWLineCount, {
      {
        text = indent
          .. icons.project
          .. " "
          .. string.format("%-" .. project_pad .. "s", ps.name)
          .. " "
          .. count_indicator
          .. project_count_indicator,
        color = "NeoWarriorGroup",
      },
      {
        text = max_urgency .. " ",
        color = urgency_color,
      },
      {
        text = "(" .. avg_urgency .. ") ",
        color = avg_urgency_color,
      },
      {
        text = icons.est .. Func.get_estimate_string(ps.total_est_val),
        color = total_est_color,
        disable = ps.total_est_val == 0.0,
      },
      {
        meta = { category = ps.key },
      },
    })
    L.add(prj[1], prj[2])

    local sub_tables = Util.table_size(ps)
    if (sub_tables > 0) and Func.tree_is_toggled(ps.key, NWToggledTrees) then
      L.treeview(ps, level + 1)
      if NWTasksByProject[ps.key] and NWTasksByProject[ps.key].tasks then
        L.tasks(NWTasksByProject[ps.key].tasks, level)
      end
    end
  end
end

M.show_task = function()
  local line = vim.api.nvim_get_current_line()
  local uuid = Func.get_meta_data(line, 'uuid')
  local category = Func.get_category(line)
  if uuid then
    Buffer.save_cursor()
    M.show(uuid)
  elseif category then
    if category == opt.no_project_name then
      category = ""
    end
    M.export("project:" .. category)
    M.render_list()
  end
end

M.show = function(uuid)
  NWCurrentTask = uuid
  local task = Data.task(uuid)
  local annotations = task.annotations
  local used_keys = {}
  local prefix_format = "%-13s | "
  local time_fields = {
    "modified",
    "entry",
    "due",
    "scheduled",
  }

  Buffer.unlock(bufnr)
  Buffer.option(bufnr, "wrap", true)

  if task.status and task.status == "completed" then
    local status = Buffer.create_line(NWLineCount, {
      {
        text = icons.task .. " Completed",
        color = "NeoWarriorTextSuccess",
      },
    })
    L.add(status[1], status[2])
    table.insert(used_keys, "status")
  end

  if task.project then
    local project = Buffer.create_line(NWLineCount, {
      {
        text = icons.project .. " " .. task.project,
        color = "NeoWarriorTextInfo",
      },
      {
        meta = {
          category = task.project,
        },
      },
    })
    L.add(project[1], project[2])
    table.insert(used_keys, "project")
  end

  local task_line = L.task({
    data = task,
    disable_meta = true,
    disable_priority = true,
    disable_due = true,
    disable_recur = true,
    disable_estimate = true,
  })
  L.add(task_line.line, task_line.colors)

  if task.start then
    local start_line = Buffer.create_line(NWLineCount, {
      {
        text = "Task started: ",
      },
      {
        text = Time.format(task.start),
        color = "NeoWarriorTextDanger",
      },
    })
    L.add(start_line[1], start_line[2])
  end
  L.add("", {})

  if annotations then
    local annotations_line = Buffer.create_line(NWLineCount, {
      {
        text = "Annotations",
        color = "NeoWarriorTextInfo",
      },
    })
    L.add(annotations_line[1], annotations_line[2])
    for _, annotation in ipairs(annotations) do
      L.add(Time.format(annotation.entry) .. ": " .. annotation.description, {})
    end
    L.add("", {})
  end

  local urgency = Buffer.create_line(NWLineCount, {
    {
      text = string.format(prefix_format, "Urgency"),
    },
    {
      text = task.urgency,
      color = Func.get_urgency_color(task.urgency),
    },
  })
  L.add(urgency[1], urgency[2])
  table.insert(used_keys, "urgency")

  if task.estimate then
    local estimate_ln = Buffer.create_line(NWLineCount, {
      {
        text = string.format(prefix_format, "Estimate"),
      },
      {
        text = Func.get_estimate_string(task.estimate),
        color = Func.get_estimate_color(task.estimate),
      },
    })
    L.add(estimate_ln[1], estimate_ln[2])
    table.insert(used_keys, "estimate")
  end

  if task.priority then
    local prio_ln = Buffer.create_line(NWLineCount, {
      {
        text = string.format(prefix_format, "Priority"),
      },
      {
        text = task.priority,
        color = Func.get_priority_color(task.priority),
      },
    })
    L.add(prio_ln[1], prio_ln[2])
    table.insert(used_keys, "priority")
  end

  if task.scheduled then
    local scheduled_ln = Buffer.create_line(NWLineCount, {
      {
        text = string.format(prefix_format, "scheduled"),
      },
      {
        text = Time.relative(task.scheduled) .. " (" .. task.scheduled .. ")",
        color = Func.get_due_color(Time.relative(task.scheduled)),
      },
    })
    L.add(scheduled_ln[1], scheduled_ln[2])
    table.insert(used_keys, "scheduled")
  end

  if task.due then
    local due_ln = Buffer.create_line(NWLineCount, {
      {
        text = string.format(prefix_format, "due"),
      },
      {
        text = Time.relative(task.due) .. " (" .. task.due .. ")",
        color = Func.get_due_color(Time.relative(task.due)),
      },
    })
    L.add(due_ln[1], due_ln[2])
    table.insert(used_keys, "due")
  end

  if task.depends then
    table.insert(used_keys, "depends")
  end

  for k, v in pairs(task) do
    local used = false
    for _, u in ipairs(used_keys) do
      if u == k then
        used = true
        break
      end
    end
    if not used then
      local prefix = string.format(prefix_format, k)
      local is_time_field = false
      for _, field in ipairs(time_fields) do
        if field == k then
          is_time_field = true
          break
        end
      end
      if k == "tags" and v then
        local tags = table.unpack(v)
        L.add(string.format("%s%s", prefix, tags), {})
      elseif is_time_field then
        local time_color = nil
        local time_string = Time.relative(v)
        if k == "due" or k == "scheduled" then
          time_color = Func.get_due_color(time_string)
        end
        local time_ln = Buffer.create_line(NWLineCount, {
          {
            text = prefix,
          },
          {
            text = time_string,
            color = time_color,
          },
          {
            text = " (" .. v .. ")",
          },
        })
        L.add(time_ln[1], time_ln[2])
      elseif not (k == "uuid") and not (k == "description") and not (k == "parent") and not (k == "imask") then
        L.add(string.format("%s%s", prefix, tostring(v)), {})
      end
    end
  end -- for

  local parents = {}
  for _, pt in ipairs(NWAllTasks) do
    if pt.depends then
      for _, pd in ipairs(pt.depends) do
        if pd == uuid then
          table.insert(parents, Func.find_task_by_uuid(pt.uuid, NWAllTasks))
        end
      end
    end
  end

  if parents and Util.table_size(parents) > 0 then
    L.add("", {})
    local parents_ln = Buffer.create_line(NWLineCount, {
      {
        text = "Parent tasks",
        color = "NeoWarriorTextWarning",
      },
    })
    L.add(parents_ln[1], parents_ln[2])

    for _, parent_data in ipairs(parents) do
      local parent = L.task({
        data = parent_data,
        meta = { parent = 1 },
      })
      L.add(parent.line, parent.colors)
    end
  end

  if task.depends then
    L.add("", {})
    local depends_ln = Buffer.create_line(NWLineCount, {
      {
        text = "Dependencies",
        color = "NeoWarriorTextDanger",
      },
    })
    L.add(depends_ln[1], depends_ln[2])

    for _, dep_uuid in ipairs(task.depends) do
      local dep_task = Func.find_task_by_uuid(dep_uuid, NWAllTasks)
      if dep_task then
        local dep = L.task({
          data = dep_task,
          meta = { dependency = 1 },
        })
        L.add(dep.line, dep.colors)
      end
    end
  end

  L.print(bufnr)
  Buffer.lock(bufnr)
end

M.modify = function(uuid, mod_string)
  Data.modify(uuid, mod_string)
  update_all_tasks()
end

M.done = function(uuid)
  local task = Func.find_task_by_uuid(uuid, NWAllTasks)
  local desc = ""
  if task and task.description then
    desc = task.description
  end
  local choice = vim.fn.confirm("Are you sure you want to mark this task done?\n" .. desc, "Yes\nNo", 1, "question")

  if choice == 1 then
    Data.complete(uuid)
  end
end

M.delete = function(line)
  local uuid = Func.get_meta_data(line, 'uuid')
  if not uuid then
    return nil
  end
  Data.delete(uuid)
end

M.export = function(filter)
  NWCurrentFilter = filter
  local exported_tasks = Data.tasks(NWCurrentReport, filter)
  parse_export(exported_tasks)
  local data = {}
  NWCurrentData = data
  return exported_tasks
end

M.list = function()
  M.export(NWCurrentFilter)
  M.render_list()
  Buffer.restore_cursor()
  M.close_help()
end

---Print list of tasks in different modes (treeview, list, grouped list)
M.render_list = function()
  NWCurrentTask = nil
  local projs = {
    all = {
      name = "all",
    },
  }

  Buffer.unlock(bufnr)
  Buffer.option(bufnr, "wrap", false)

  if opt.show_current_filter then
    local current_filter_string = ""
    if NWCurrentFilter then
      current_filter_string = NWCurrentFilter .. " "
    end
    local help_line = Buffer.create_line(NWLineCount, {
      {
        text = "(" .. opt.keys.help.key .. ")help | (" .. opt.keys.add.key .. ")add | (" .. opt.keys.done.key .. ")done | (" .. opt.keys.filter.key .. ")filter",
      }
    })
    L.add(help_line[1], help_line[2])
    local line = Buffer.create_line(NWLineCount, {
      {
        text = "(" .. opt.keys.select_report.key .. ")report: ",
      },
      {
        text = NWCurrentReport,
        color = "NeoWarriorTextInfo",
      },
      {
        text = " (Grouped by project)",
        disable = not grouped,
      },
      {
        text = " (Tree view)",
        disable = not treeview,
      },
    })
    L.add(line[1], line[2])
    line = Buffer.create_line(NWLineCount, {
      {
        text = "(" .. opt.keys.select_filter.key .. ")ilter: ",
      },
      {
        text = current_filter_string,
        color = "NeoWarriorTextWarning",
      },
    })
    L.add(line[1], line[2])
    L.add("", {})
  end

  if treeview then
    L.treeview(NWProjectTree, 0)
  else
    if grouped then
      projs = NWProjects
    end
    for _, proj in pairs(projs) do
      if grouped then
        if NWTasksByProject[proj] and NWTasksByProject[proj].tasks then
          local total_est_color = ""
          local project = NWTasksByProject[proj]
          if not (project.total_est == "") then
            total_est_color = Func.get_estimate_color(project.total_est_val)
          end
          local prj = Buffer.create_line(NWLineCount, {
            {
              text = icons.project .. " " .. project.name .. " ",
              color = "NeoWarriorGroup",
            },
            {
              text = project.max_urgency .. " ",
              color = Func.get_urgency_color(project.max_urgency_val),
            },
            {
              text = "(" .. project.avg_urgency .. ") ",
              color = Func.get_urgency_color(project.avg_urgency_val),
            },
            {
              text = icons.est .. Func.get_estimate_string(project.total_est_val),
              color = total_est_color,
              disable = not project.total_est_val == 0.0,
            },
            {
              meta = {
                category = project.name,
              },
            },
          })
          L.add(prj[1], prj[2])
          L.tasks(NWTasksByProject[proj].tasks, 0)
          L.add("", {})
        end
      else
        L.tasks(NWTasks, 0)
      end
    end
  end
  -- Add extra line at the end
  L.add("", {})
  L.print(bufnr)
  Buffer.lock(bufnr)
end

M.open_left = function()
  M.open("left")
end
M.open_right = function()
  M.open("right")
end
M.open_current = function()
  M.open("current")
end
M.open_below = function()
  M.open("below")
end
M.open_above = function()
  M.open("above")
end

local help_float = nil
M.open_help = function()

  local width = 40;
  -- local seperator = string.rep("─", width)

  local lines = {
    -- "NeoWarrior key maps",
    -- seperator,
  }

  local keys_array = {}
  for _, value in pairs(opt.keys) do
    table.insert(keys_array, { key = value.key, desc = value.desc })
  end
  table.sort(keys_array, function(a, b)
    return string.lower(a.key) < string.lower(b.key)
  end)

  for _, key in ipairs(keys_array) do
    local key_string = string.format("%6s | %s", key.key, key.desc)
    table.insert(lines, key_string)
  end

  local win_width = vim.api.nvim_win_get_width(0)

  help_float = Buffer.float(lines, {
    relative = 'editor',
    border = 'rounded',
    title = 'NeoWarrior Help',
    width = width,
    col = math.floor((win_width - 40) / 2),
    row = 5,
  })

  return help_float
end

M.close_help = function()
  if help_float then
    vim.api.nvim_win_close(help_float, true)
  end
end

M.open = function(split)
  update_all_tasks()

  bufnr = vim.api.nvim_create_buf(false, true)
  if split == "current" then
    vim.api.nvim_set_current_buf(bufnr)
  else
    local win = -1
    if split == "below" or split == "above" then
      win = 0
    end
    vim.api.nvim_open_win(bufnr, true, {
      split = split,
      win = win,
    })
  end

  if bufnr then
    vim.api.nvim_buf_set_name(bufnr, "neowarrior")
    vim.api.nvim_set_option_value("buftype", "nofile", { scope = "local" })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { scope = "local" })
    vim.api.nvim_set_option_value("swapfile", false, { scope = "local" })
    vim.api.nvim_set_option_value("conceallevel", 2, { scope = "local" })
    vim.api.nvim_set_option_value("concealcursor", "nc", { scope = "local" })
    vim.api.nvim_set_option_value("wrap", false, { scope = "local" })
    vim.api.nvim_set_option_value("filetype", "neowarrior", { scope = "local" })
    vim.cmd([[
  syntax match Metadata /{{{.*}}}/ conceal
  syntax match MetadataConceal /{{{[^}]*}}}/ contained conceal
]])
    local opts = { noremap = true, silent = true }
    local default_keymap_opts = { buffer = bufnr, noremap = true, silent = false }

    vim.keymap.set("n", opt.keys.help.key, function()
      M.open_help()
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.close_help.key, function()
      M.close_help()
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.done.key, function()
      Buffer.save_cursor()
      local back_uuid = NWCurrentTask
      local line = vim.api.nvim_get_current_line()
      local uuid = Func.get_meta_data(line, 'uuid')
      if not uuid then
        uuid = NWCurrentTask
      end
      local is_dependency = Func.get_meta_data(line, "dependency")
      local is_parent = Func.get_meta_data(line, "parent")
      if not is_parent then
        if is_dependency then
          print("TODO: remove dependency")
        elseif uuid then
          M.done(uuid)
        end
        if NWCurrentTask then
          M.show(back_uuid)
        else
          M.export(NWCurrentFilter)
          M.render_list()
        end
      end
      Buffer.restore_cursor()
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.start.key, function()
      Buffer.save_cursor()
      local line = vim.api.nvim_get_current_line()
      local uuid = Func.get_meta_data(line, 'uuid')
      if NWCurrentTask then
        uuid = NWCurrentTask
      end
      local task = nil
      if uuid then
        task = Data.task(uuid)
      end

      if task and task.start then
        vim.fn.system("task stop " .. uuid)
        if NWCurrentTask then
          M.show(uuid)
        else
          M.export(NWCurrentFilter)
          M.render_list()
        end
        Buffer.restore_cursor()
      else
        vim.fn.system("task start " .. uuid)
        M.show(uuid)
      end
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.select_dependency.key, function()
      update_all_tasks()
      local line = vim.api.nvim_get_current_line()
      local uuid = Func.get_meta_data(line, 'uuid')
      local opts = require("telescope.themes").get_dropdown({})
      pickers
      .new(opts, {
        prompt_title = "Select dependency",
        finder = finders.new_table({
          results = NWAllTasks,
          entry_maker = function(entry)
            local task_icon = icons.task
            if entry.status and entry.status == "completed" then
              task_icon = icons.task_completed
            end
            if entry.status and entry.status == "deleted" then
              task_icon = icons.deleted
            end
            if Func.has_pending_dependencies(entry.depends, NWAllTasks) then
              task_icon = icons.depends
            end
            return {
              value = entry,
              display = task_icon .. ' ' .. entry.description,
              ordinal = entry.description,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if uuid then
              Data.add_dependency(uuid, selection.value.uuid)
              update_all_tasks()
              M.export(NWCurrentFilter)
              M.render_list()
            end
          end)
          return true
        end,
      })
      :find()
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.toggle_tree.key, function()
      Buffer.save_cursor()
      Func.toggle_tree(NWToggledTrees)
      M.render_list()
      Buffer.restore_cursor()
    end, default_keymap_opts)

    vim.keymap.set("n", "<CR>", function()
      M.show_task()
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.enter.key, function()
      M.show_task()
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.modify_select_project.key, function()
      local line = vim.api.nvim_get_current_line()
      local uuid = Func.get_meta_data(line, 'uuid')
      if uuid then
        local opts = require("telescope.themes").get_dropdown({})
        pickers
        .new(opts, {
          prompt_title = "Set task project",
          finder = finders.new_table({
            results = NWProjects,
          }),
          sorter = conf.generic_sorter(opts),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              local mod_project = prompt
              if selection and selection[1] then
                mod_project = selection[1]
              end
              M.modify(uuid, "project:" .. mod_project)
              M.refresh()
            end)
            return true
          end,
        })
        :find()
      end
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.modify_select_priority.key, function()
      local line = vim.api.nvim_get_current_line()
      local uuid = Func.get_meta_data(line, 'uuid')
      if uuid then
        local opts = require("telescope.themes").get_dropdown({})
        pickers
        .new(opts, {
          prompt_title = "Set task priority",
          finder = finders.new_table({
            results = { "H", "M", "L", "None" },
          }),
          sorter = conf.generic_sorter(opts),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              local mod_priority = prompt
              if selection and selection[1] then
                mod_priority = selection[1]
              end
              if (mod_priority == "H") or (mod_priority == "M") or (mod_priority == "L") then
                M.modify(uuid, "priority:" .. mod_priority)
              else
                M.modify(uuid, "priority:")
              end
              M.export(NWCurrentFilter)
              M.render_list()
            end)
            return true
          end,
        })
        :find()
      end
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.modify_due.key, function()
      local line = vim.api.nvim_get_current_line()
      local uuid = Func.get_meta_data(line, 'uuid')
      Buffer.save_cursor()
      local prompt = "Task due date: "
      vim.ui.input({
        prompt = prompt,
        cancelreturn = nil,
      }, function(input)
        if input then
          M.modify(uuid, "due:" .. input)
          M.export(NWCurrentFilter)
          M.render_list()
        end
      end)
      Buffer.restore_cursor()
    end, default_keymap_opts)

    vim.keymap.set("n", opt.keys.modify.key, function()
      local line = vim.api.nvim_get_current_line()
      local uuid = Func.get_meta_data(line, 'uuid')
      if not uuid and NWCurrentTask then
        uuid = NWCurrentTask
      end
      local task = nil
      if uuid then
        task = Data.task(uuid)
        Buffer.save_cursor()
        local prompt = 'Modify task ("description" due:21hours etc): '
        vim.ui.input({
          prompt = prompt,
          default = '"' .. task.description .. '"',
          cancelreturn = nil,
        }, function(input)
          if input then
            M.modify(uuid, input)
            if NWCurrentTask then
              M.show(NWCurrentTask)
            else
              M.export(NWCurrentFilter)
              M.render_list()
            end
          end
        end)
        Buffer.restore_cursor()
      end
    end, default_keymap_opts)

    vim.keymap.set("n", '<Esc>', function() M.list() end, default_keymap_opts)
    vim.keymap.set("n", opt.keys.back.key, function() M.list() end, default_keymap_opts)

    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.add.key, "<Cmd>NeoWarriorAdd<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.filter.key, "<Cmd>NeoWarriorFilter<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.select_filter.key, "<Cmd>NeoWarriorFilterFromCommon<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.toggle_group_view.key, "<Cmd>NeoWarriorToggleGroupView<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.toggle_tree_view.key, "<Cmd>NeoWarriorToggleTreeView<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.select_report.key, "<Cmd>NeoWarriorReport<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.refresh.key, "<Cmd>NeoWarriorRefresh<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.reset.key, "<Cmd>NeoWarriorReset<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.collapse_all.key, "<Cmd>NeoWarriorToggleTreeCollapseAll<CR>", opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", opt.keys.expand_all.key, "<Cmd>NeoWarriorToggleTreeExpandAll<CR>", opts)

    M.export(NWCurrentFilter)
    M.render_list()
    if opt.expanded then
      M.expand_all()
    end
  end
end

M.reset = function()
  update_all_tasks()
  Buffer.save_cursor()
  init()
  M.export(NWCurrentFilter)
  M.render_list()
  Buffer.restore_cursor()
end

M.refresh = function()
  update_all_tasks()
  Buffer.save_cursor()
  M.export(NWCurrentFilter)
  M.render_list()
  Buffer.restore_cursor()
end

M.focus = function()
  local windows = vim.api.nvim_list_wins()
  for _, handle in ipairs(windows) do
    local buf_handle = vim.api.nvim_win_get_buf(handle)
    local buf_name = vim.api.nvim_buf_get_name(buf_handle)
    if string.find(buf_name, "neowarrior") then
      vim.api.nvim_set_current_win(handle)
      return
    end
  end
end

--- Expand all trees
M.expand_all = function()
  Buffer.save_cursor()
  NWToggledTrees = {}
  for _, p in ipairs(NWProjects) do
    table.insert(NWToggledTrees, p)
  end
  M.render_list()
  Buffer.restore_cursor()
end

--- Setup NeoWarrior
---@param set_opt table
---@return nil
M.setup = function(set_opt)

  user_opt = set_opt
  set_opts(user_opt)
  set_colors()
  init()

  if opt.float.enabled then
    local float = nil
    vim.api.nvim_create_autocmd('CursorMoved', {
      group = vim.api.nvim_create_augroup('neowarrior-cursor-move', { clear = true }),
      callback = function()
        if float and vim.api.nvim_win_is_valid(float) then
          vim.api.nvim_win_close(float, true)
        end
        local line = vim.api.nvim_get_current_line()
        local description = Func.get_meta_data(line, 'description')
        local project = Func.get_meta_data(line, 'project')
        local urgency = Func.get_meta_data(line, 'urgency')
        local priority = Func.get_meta_data(line, 'priority')
        local due = Func.get_meta_data(line, 'due')
        local estimate = Func.get_meta_data(line, 'estimate')
        local max_width = opt.float.max_width
        local win_width = vim.api.nvim_win_get_width(0)
        local width = max_width
        if win_width < max_width then
          width = win_width
        end
        if description then
          local lines = {
            description,
            ''
          }
          if project then
            table.insert(lines, icons.project .. ' Project: ' .. project)
          end
          if urgency then
            table.insert(lines, icons.warning .. ' Urgency: ' .. urgency)
          end
          if priority then
            table.insert(lines, 'Priority: ' .. priority)
          end
          if due then
            table.insert(lines, icons.due .. ' Due: ' .. due)
          end
          if estimate then
            table.insert(lines, icons.est .. ' Estimate: ' .. estimate)
          end
          float = Buffer.float(lines, { width = width, border = 'rounded' })
        end
      end,
    })
  end

  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('neowarrior-color-scheme', { clear = true }),
    callback = function()
      set_colors()
    end,
  })

  vim.api.nvim_create_user_command("NeoWarriorFocus", function()
    M.focus()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorAdd", function()
    Buffer.save_cursor()
    local default_add_input = ""
    local prompt = "Task (ex: task name due:tomorrow etc): "
    local line = vim.api.nvim_get_current_line()
    local task_uuid = Func.get_meta_data(line, 'uuid')
    local task = nil
    if task_uuid then
      task = Func.find_task_by_uuid(task_uuid, NWAllTasks)
      if (not task) or (not task.project) then
        task = nil
      end
    end
    if task then
      default_add_input = "project:" .. task.project .. " "
    elseif NWCurrentFilter and string.find(NWCurrentFilter, "project:") then
      for k, _ in string.gmatch(NWCurrentFilter, "project:%w+[%.%w]*") do
        default_add_input = k
        break
      end
    end
    if NWCurrentTask then
      default_add_input = ""
      prompt = "Annotate task"
    end
    vim.ui.input({
      prompt = prompt,
      default = default_add_input,
      cancelreturn = nil,
    }, function(input)
      if input then
        if NWCurrentTask then
          Data.annotate(NWCurrentTask, input)
          M.show(NWCurrentTask)
        else
          Data.add(input)
          M.export(NWCurrentFilter)
          M.render_list()
          Buffer.restore_cursor()
        end
      end
    end)
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorToggleTreeCollapseAll", function()
    Buffer.save_cursor()
    NWToggledTrees = {}
    M.render_list()
    Buffer.restore_cursor()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorToggleTreeExpandAll", function()
    M.expand_all()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorDelete", function()
    M.delete(vim.api.nvim_get_current_line())
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorFilter", function()
    local default_filter_input = NWCurrentFilter or ""
    vim.ui.input({
      prompt = "Filter (ex: next project:neowarrior",
      default = default_filter_input,
      cancelreturn = nil,
    }, function(input)
      if input then
        M.export(input)
        M.render_list()
        local recent_filter_exists = false
        for _, rf in ipairs(NWRecentFilters) do
          if rf == input then
            recent_filter_exists = true
            break
          end
        end
        if not recent_filter_exists then
          table.insert(NWRecentFilters, input)
        end
      end
    end)
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorReport", function()
    local opts = require("telescope.themes").get_dropdown({})
    pickers
      .new(opts, {
        prompt_title = "Select report",
        finder = finders.new_table({
          results = opt.reports,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            NWCurrentReport = selection[1]
            M.export(NWCurrentFilter)
            M.render_list()
          end)
          return true
        end,
      })
      :find()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorFilterFromCommon", function()
    local opts = require("telescope.themes").get_dropdown({})
    pickers
      .new(opts, {
        prompt_title = "Filter",
        finder = finders.new_table({
          results = opt.filters,
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local prompt = action_state.get_current_picker(prompt_bufnr):_get_prompt()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            local new_filter = prompt
            if selection and selection[1] then
              new_filter = selection[1]
            end
            M.export(new_filter)
            M.render_list()
            local recent_filter_exists = false
            for _, rf in ipairs(NWRecentFilters) do
              if rf == new_filter then
                recent_filter_exists = true
                break
              end
            end
            if not recent_filter_exists then
              table.insert(NWRecentFilters, new_filter)
            end
          end)
          return true
        end,
      })
      :find()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorToggleTreeView", function()
    if treeview then
      treeview = false
    else
      treeview = true
      grouped = false
    end
    M.render_list()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorToggleGroupView", function()
    if grouped then
      grouped = false
    else
      grouped = true
      treeview = false
    end
    M.render_list()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorReset", function()
    M.reset()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorRefresh", function()
    M.refresh()
  end, {})

  vim.api.nvim_create_user_command("NeoWarriorCurrent", function()
    M.open_left()
  end, {})
  vim.api.nvim_create_user_command("NeoWarriorLeft", function()
    M.open_left()
  end, {})
  vim.api.nvim_create_user_command("NeoWarriorBelow", function()
    M.open_below()
  end, {})
  vim.api.nvim_create_user_command("NeoWarriorAbove", function()
    M.open_above()
  end, {})
  vim.api.nvim_create_user_command("NeoWarriorRight", function()
    M.open_right()
  end, {})
  vim.api.nvim_create_user_command("NeoWarriorCurrent", function()
    M.open_current()
  end, {})
end

return M
