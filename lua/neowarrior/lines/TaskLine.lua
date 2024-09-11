local colors = require "neowarrior.colors"
local Line = require "neowarrior.Line"

---@class TaskLine
---@field neowarrior NeoWarrior
---@field line_no number
---@field task Task
---@field arg table
local TaskLine = {}

--- Create a new TaskLine
---@param task Task
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

  local line = Line:new(self.line_no)
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
  if self.task:has_pending_dependencies() then
    task_icon = self.neowarrior.config.icons.depends
    task_icon_color = "NeoWarriorTextDanger"
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

  if due then
    line:add({
      text = self.neowarrior.config.icons.due .. "" .. due .. " ",
      disable = (due == "" or disable_due),
      color = colors.get_due_color(due),
    })
  end

  if not disable_estimate and self.task.estimate then
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
