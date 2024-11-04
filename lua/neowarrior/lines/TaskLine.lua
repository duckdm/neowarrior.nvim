local colors = require "neowarrior.colors"
local TagsComponent = require "neowarrior.components.TagsComponent"

---@class TaskLine
---@field neowarrior NeoWarrior
---@field task Task
local TaskLine = {}

--- Create a new TaskLine
---@param tram Trambampolin
---@param task Task
---@return TaskLine
function TaskLine:new(tram, task)
    local task_component = {}
    setmetatable(task_component, self)
    self.__index = self

    self.tram = tram
    self.task = task

    return self
end

--- Get task line data
---@param arg table
---@return TaskLine
function TaskLine:into_line(arg)

  local conf = _Neowarrior.config
  local line_conf = conf.task_line
  if arg.line_conf then
    line_conf = vim.tbl_extend("force", line_conf, arg.line_conf)
  end
  local indent = arg.indent or ""
  local disable_priority = arg.disable_priority or false
  if line_conf.enable_priority == false then
    disable_priority = true
  end
  local disable_warning = arg.disable_warning or false
  if line_conf.enable_warning_icon == false then
    disable_warning = true
  end
  local disable_due = arg.disable_due or false
  if line_conf.enable_due_date == false then
    disable_due = true
  end
  local disable_description = arg.disable_description or false
  local disable_recur = arg.disable_recur or false
  if line_conf.enable_recur_icon == false then
    disable_recur = true
  end
  local disable_task_icon = arg.disable_task_icon or false
  local disable_tags = arg.disable_tags or false
  if line_conf.enable_tags == false then
    disable_tags = true
  end
  local disable_estimate = arg.disable_estimate or false
  if line_conf.enable_estimate == false then
    disable_estimate = true
  end
  local disable_annotations = arg.disable_annotations or false
  local disable_has_blocking = arg.disable_has_blocking or false
  local project = self.task.project or 'No project'
  local meta = arg.meta or nil
  local description_color = ""
  local description = ""
  if self.task.description then
    description = tostring(string.gsub(self.task.description, "\n", ""))
  end
  local estimate_string = self.task.estimate_string
  local urgency_val = self.task.urgency or 0.0
  if _Neowarrior.current_mode == 'grouped' then
    project = ""
  end
  local priority = self.task.priority or "-"
  local due = nil
  local due_no = 0
  if self.task.due_dt then
    due = self.task.due_dt:relative()
    due_no = self.task.due_dt:relative_hours()
  end
  local task_icon = conf.icons.task
  local task_icon_color = _Neowarrior.config.colors.dim.group
  if self.task.start_dt then
    task_icon_color = _Neowarrior.config.colors.danger.group
    task_icon = _Neowarrior.config.icons.start
    description_color = _Neowarrior.config.colors.warning.group
  end
  if self.task.status and self.task.status == "completed" then
    task_icon = conf.icons.task_completed
    task_icon_color = _Neowarrior.config.colors.success.group
  end
  if self.task.status and self.task.status == "deleted" then
    task_icon = conf.icons.deleted
    task_icon_color = _Neowarrior.config.colors.warning.group
  end

  local has_blocking = false
  if self.task.depends then
    task_icon = conf.icons.depends
    task_icon_color = _Neowarrior.config.colors.danger.group
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
    back = arg.back or nil,
  }

  if meta then
    for k, v in pairs(meta) do
      meta_table[k] = v
    end
  end

  self.tram:col(indent, "")

  if not disable_task_icon then
    self.tram:col(task_icon .. " ", task_icon_color)
  end

  if urgency_val > 5 and (not disable_warning) and line_conf.enable_warning_icon == "left" then
    self.tram:col(
      conf.icons.warning .. " ",
      colors.get_urgency_color(urgency_val)
    )
  end

  if not disable_priority and line_conf.enable_priority == "left" then
    self.tram:col(priority .. " ", colors.get_priority_color(priority))
  end

  if not disable_recur and self.task.recur and line_conf.enable_recur_icon == "left" then
    self.tram:col(conf.icons.recur .. " ", _Neowarrior.config.colors.info.group)
  end

  if due and (due ~= '') and (not disable_due) and line_conf.enable_due_date == "left" then
    self.tram:col(conf.icons.due .. " " .. due, colors.get_due_color(due_no))
    self.tram:col(" ", "")
  end

  if self.task.estimate and type(self.task.estimate) == "number" and (not disable_estimate) and line_conf.enable_estimate == "left" and self.task.estimate and self.task.estimate > 0 then
    self.tram:col(
      conf.icons.est .. "" .. estimate_string .. " ",
      colors.get_estimate_color(self.task.estimate)
    )
  end

  if (not disable_annotations) and self.task.annotations and line_conf.enable_annotations_icon == "left" then
    self.tram:col(conf.icons.annotated .. " ", _Neowarrior.config.colors.annotation.group)
  end

  if has_blocking and (not disable_has_blocking) then
    if (not self.task.tags) or (type(self.task.tags) ~= "table") then
      self.task.tags = { "blocked" }
    elseif not vim.tbl_contains(self.task.tags, "blocked") then
      table.insert(self.task.tags, "blocked")
    end
  end

  if self.task.tags and (not disable_tags) then
    TagsComponent:new(self.tram, self.task.tags):cols()
    self.tram:col(" ", "")
  end

  if not disable_description then
    self.tram:col(description, description_color)
  end

  if (not arg.disable_urgency) and line_conf.enable_urgency == "eol" then
    self.tram:col(
      " " .. string.format("%.1f", urgency_val) .. " ",
      colors.get_urgency_color(urgency_val)
    )
  end

  self.tram:into_line({
    meta = meta_table
  })

  local has_right_aligned_items = false

  if urgency_val > 5 and (not disable_warning) and line_conf.enable_warning_icon == "right" then
    self.tram:col(
      " " .. conf.icons.warning,
      colors.get_urgency_color(urgency_val)
    )
    has_right_aligned_items = true
  end

  if (not arg.disable_urgency) and line_conf.enable_urgency == "right" then
    self.tram:col(
      " " .. string.format("%.1f", urgency_val),
      colors.get_urgency_color(urgency_val)
    )
    has_right_aligned_items = true
  end

  if has_right_aligned_items then
    self.tram:into_virt_line({ pos = "right_align" })
  end

  return self
end

return TaskLine
