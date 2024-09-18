local colors = require "neowarrior.colors"
local Line = require "neowarrior.Line"
local TaskUtil = require "neowarrior.TaskUtil"

---@class TaskLine
---@field neowarrior NeoWarrior
---@field line_no number
---@field task Task
---@field arg table
local TaskLine = {}

--- Create a new TaskLine
---@param neowarrior NeoWarrior
---@param line_no number
---@param task Task
---@param arg table
---@return Line
function TaskLine:new(neowarrior, line_no, task, arg)
    local task_component = {}
    setmetatable(task_component, self)
    self.__index = self

    self.neowarrior = neowarrior
    self.line_no = line_no
    self.task = task

    return self:get_task_line(arg)
end

--- Get task line data
---@param arg table
---@return Line[]
function TaskLine:get_task_line(arg)

  local conf = self.neowarrior.config.task_line
  local line = Line:new(self.line_no)
  local indent = arg.indent or ""
  local disable_meta = arg.disable_meta or false
  local disable_priority = arg.disable_priority or false
  if conf.enable_priority == false then
    disable_priority = true
  end
  local disable_warning = arg.disable_warning or false
  if conf.enable_warning_icon == false then
    disable_warning = true
  end
  local disable_due = arg.disable_due or false
  if conf.enable_due_date == false then
    disable_due = true
  end
  local disable_description = arg.disable_description or false
  local disable_recur = arg.disable_recur or false
  if conf.enable_recur_icon == false then
    disable_recur = true
  end
  local disable_task_icon = arg.disable_task_icon or false
  local disable_estimate = arg.disable_estimate or false
  if conf.enable_estimate == false then
    disable_estimate = true
  end
  local disable_annotations = arg.disable_annotations or false
  local disable_start = arg.disable_start or false
  local project = self.task.project or 'No project'
  local meta = arg.meta or nil
  local description = ""
  if self.task.description then
    description = tostring(string.gsub(self.task.description, "\n", ""))
  end
  local estimate_string = self.task.estimate_string
  local urgency_val = self.task.urgency or 0.0
  if self.neowarrior.current_mode == 'grouped' then
    project = ""
  end
  local priority = self.task.priority or "-"
  local due = self.task.due or nil
  if due then
    due = due:relative()
  end
  local task_icon = self.neowarrior.config.icons.task
  local task_icon_color = "NeoWarriorTextDim"
  if self.task.start then
    task_icon_color = "NeoWarriorTextDanger"
  end
  if self.task.status and self.task.status == "completed" then
    task_icon = self.neowarrior.config.icons.task_completed
    task_icon_color = "NeoWarriorTextSuccess"
  end
  if self.task.status and self.task.status == "deleted" then
    task_icon = self.neowarrior.config.icons.deleted
    task_icon_color = "NeoWarriorTextWarning"
  end
  local has_blocking = false
  if self.task.depends and TaskUtil.has_dependencies(self.task, self.neowarrior.all_pending_tasks) then
    task_icon = self.neowarrior.config.icons.depends
    task_icon_color = "NeoWarriorTextDanger"
    has_blocking = true
  end

  local meta_table = {
    uuid = self.task.uuid,
    description = description,
    category = project,
    project = project,
    priority = priority,
    urgency = urgency_val,
    due = due,
    estimate = self.task.estimate,
    status = self.task.status or "pending",
  }

  if meta then
    for k, v in pairs(meta) do
      meta_table[k] = v
    end
  end

  line:add({
    text = indent
  })

  if not disable_task_icon then
    line:add({
      text = task_icon .. " ",
      color = task_icon_color,
    })
  end

  if self.task.start and (not disable_start) then
    line:add({
      text = self.neowarrior.config.icons.start .. " ",
      color = "NeoWarriorTextDanger",
    })
  end

  if urgency_val > 5 and (not disable_warning) then
    line:add({
      text = self.neowarrior.config.icons.warning .. " ",
      color = colors.get_urgency_color(urgency_val),
      disable = (urgency_val < 5 or disable_warning),
    })
  end

  if not disable_priority then
    line:add({
      text = priority .. " ",
      color = colors.get_priority_color(priority),
    })
  end

  if not disable_recur and self.task.recur then
    line:add({
      text = self.neowarrior.config.icons.recur .. " ",
      color = "NeoWarriorTextInfo",
    })
  end

  if due and (due ~= '') and (not disable_due) then
    line:add({
      text = self.neowarrior.config.icons.due .. "" .. due .. " ",
      color = colors.get_due_color(due),
    })
  end

  if not disable_estimate and self.task.estimate and self.task.estimate > 0 then
    line:add({
      text = self.neowarrior.config.icons.est .. "" .. estimate_string .. " ",
      color = colors.get_estimate_color(self.task.estimate),
    })
  end

  if (not disable_annotations) and self.task.annotations then
    line:add({
      text = self.neowarrior.config.icons.annotated .. " ",
      color = "NeoWarriorTextInfo",
    })
  end

  if not disable_description then
    line:add({
      text = description,
      color = has_blocking and "NeoWarriorTextDanger" or nil,
    })
    if has_blocking then
      line:add({
        text = " [has blocking tasks]",
        color = "NeoWarriorTextDanger",
      })
    end
  end

  if not disable_urgency and self.neowarrior.config.task_line.enable_urgency then
    line:add({
      text = " " .. string.format("%.1f", urgency_val) .. " ",
      color = colors.get_urgency_color(urgency_val),
    })
  end

  if meta_table and not (disable_meta) then
    line:add({
      meta = meta_table,
    })
  end

  return line
end

return TaskLine
