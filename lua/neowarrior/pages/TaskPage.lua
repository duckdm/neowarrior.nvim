local Page = require('neowarrior.Page')
local colors = require('neowarrior.colors')
local Line = require('neowarrior.Line')
local DateTime = require('neowarrior.DateTime')
local TaskLine = require('neowarrior.lines.TaskLine')
local Project = require('neowarrior.Project')
local ProjectLine = require('neowarrior.lines.ProjectLine')

---@class TaskPage
---@field neowarrior NeoWarrior
---@field task Task
---@field private used_keys table
---@field private page Page
---@field private prefix_format string
---@field private time_fields table
---@field public new fun(self: TaskPage, neowarrior: NeoWarrior, task: Task): TaskPage
---@field public print fun(self: TaskPage, buffer: Buffer): TaskPage
---@field private row fun(self: TaskPage, key: string, lines: table): TaskPage
local TaskPage = {}

--- Create a new TaskPage
---
---@param neowarrior NeoWarrior
---@param task Task
---@return TaskPage
function TaskPage:new(neowarrior, task)
  local task_page = {}
  setmetatable(task_page, self)
  self.__index = self

  task_page.neowarrior = neowarrior
  task_page.task = task
  task_page.used_keys = {}
  task_page.page = Page:new(neowarrior.buffer)
  task_page.prefix_format = "%-13s | "
  task_page.time_fields = {
    "modified",
    "entry",
    "due",
    "scheduled",
  }
  task_page.line_no = 0

  return task_page
end

--- Print the TaskPage
---
---@param buffer Buffer
---@return TaskPage
function TaskPage:print(buffer)

  buffer:unlock()
  buffer:option("wrap", true, { win = self.neowarrior.window.id })

  self:completed()
  self:project()
  self:started()
  self:task_line({
    disable_meta = true,
    disable_description = true,
  })
  self:task_line({
    disable_meta = true,
    disable_task_icon = true,
    disable_priority = true,
    disable_warning = true,
    disable_due = true,
    disable_recur = true,
    disable_estimate = true,
    disable_annotations = true,
    disable_start = true,
  })

  self.page:nl()
  self.line_no = self.page:get_line_count()

  self:annotations()

  --  FIX: colors don't work for urgency
  self:urgency()
  self:estimate()
  self:priority()
  self:scheduled()
  self:due()

  if self.task.depends then
    table.insert(self.used_keys, "depends")
  end

  for k, v in pairs(self.task:get_attributes()) do

    local used = false

    for _, u in ipairs(self.used_keys) do
      if u == k then
        used = true
        break
      end
    end

    if not used then
      local prefix = string.format(self.prefix_format, k)
      local is_time_field = false
      for _, field in ipairs(self.time_fields) do
        if field == k then
          is_time_field = true
          break
        end
      end
      -- FIX:Show tags
      if k == "tags" and v then
        local tags = table.unpack(v)
        self.page:add_raw(string.format("%s%s", prefix, tags), '')
      elseif is_time_field then
        local time_color = nil
        local time_string = v:relative()
        if k == "due" or k == "scheduled" then
          time_color = colors.get_due_color(time_string)
        end
        local time_ln = Line:new(0)
        time_ln:add({
          text = prefix,
        })
        time_ln:add({
          text = time_string,
          color = time_color,
        })
        time_ln:add({
          text = " (" .. v:default_format() .. ")",
        })
        self.page:add_line(time_ln)
      elseif not (k == "uuid") and not (k == "description") and not (k == "parent") and not (k == "imask") and v then
        self:row(k, {
          { text = string.format(self.prefix_format, k) },
          { text = self.task[k], color = '' }
        })
      end
    end
  end -- for

  self.page:print()

  return self
end

--- Add a row to the TaskPage
---@param cols table
---@return TaskPage
function TaskPage:row(key, cols)

  table.insert(self.used_keys, key)

  local line = Line:new(self.line_no)

  for _, col in ipairs(cols) do
    line:add({
      text = col.text,
      color = col.color or '',
    })
  end
  self.page:add_line(line)
  self.line_no = self.line_no + 1

  return self
end

--- Completed row
function TaskPage:completed()

  if self.task.status and self.task.status == "completed" then
    table.insert(self.used_keys, 'status')
    self.page:add_raw("Task completed", "NeoWarriorTextSuccess")
  end

end

--- Project row
function TaskPage:project()

  table.insert(self.used_keys, 'project')
  if self.task.project then
    local project = Project:new({ name = self.task.project })
    local project_line = ProjectLine:new(self.neowarrior, self.line_no, project, {})
    self.page:add_line(project_line)
  end

end

--- Task line
function TaskPage:task_line(arg)

  table.insert(self.used_keys, 'description')
  local task_line = TaskLine:new(self.neowarrior, self.line_no, self.task, arg)
  self.page:add_line(task_line)

end

--- Started row
function TaskPage:started()

  if self.task.start then
    self:row('start', {{
      text = "Task started: ",
    }, {
      text = self.task.start:default_format(),
      color = "NeoWarriorTextDangerBg",
    }})
  end

end

--- Annotation rows
function TaskPage:annotations()

  local annotations = self.task.annotations
  if annotations then

    self:row('annotations', {{
      text = "Annotations",
      color = "NeoWarriorTextInfo",
    }})

    for _, annotation in ipairs(annotations) do

      local anno_entry = ''
      local anno_ln = Line:new(0)

      if annotation.entry then
        local anno_entry_dt = DateTime:new(annotation.entry)
        anno_entry = " " .. anno_entry_dt:default_format()
        anno_ln:add({
          text = self.neowarrior.config.icons.annotated .. anno_entry,
          color = "NeoWarriorTextInfo",
        })
      end

      anno_ln:add({
        text = " " .. annotation.description,
      })

      self.page:add_line(anno_ln)
    end

    self.page:nl()
  end

end

--- Urgency row
function TaskPage:urgency()

  self:row('urgency', {
    { text = string.format(self.prefix_format, "Urgency") },
    { text = self.task.urgency, color = colors.get_urgency_color(self.task.urgency) }
  })

end

--- Estimate row
function TaskPage:estimate()

  self:row('estimate', {{
    text = string.format(self.prefix_format, "Estimate"),
  }, {
    text = self.task.estimate_string,
    color = colors.get_estimate_color(self.task.estimate),
  }})

end

--- Priority row
function TaskPage:priority()

  self:row('priority', {{
    text = string.format(self.prefix_format, "Priority"),
  }, {
    text = self.task.priority,
    color = colors.get_priority_color(self.task.priority),
  }})

end

--- Scheduled row
function TaskPage:scheduled()

  if self.task.scheduled then
    self:row('scheduled', {{
      text = string.format(self.prefix_format, "Scheduled"),
    }, {
      text = self.task.scheduled:relative() .. " (" .. self.task.scheduled:default_format() .. ")",
      color = colors.get_due_color(self.task.scheduled:relative()),
    }})
  end

end

--- Due row
function TaskPage:due()

  if self.task.due then
    self:row('due', {{
      text = string.format(self.prefix_format, "Due"),
    }, {
      text = self.task.due:relative() .. " (" .. self.task.due:default_format() .. ")",
      color = colors.get_due_color(self.task.due:relative()),
    }})
  end

end

return TaskPage
