local Tram = require('trambampolin.init')
local colors = require('neowarrior.colors')
local DateTime = require('neowarrior.DateTime')
local TaskLine = require('neowarrior.lines.TaskLine')
local Project = require('neowarrior.Project')
local ProjectLine = require('neowarrior.lines.ProjectLine')
local HeaderComponent = require('neowarrior.components.HeaderComponent')
local TagsComponent = require('neowarrior.components.TagsComponent')

---@class TaskPage
---@field task Task
---@field private used_keys table
---@field private page Page
---@field private prefix_format string
---@field private time_fields table
---@field public new fun(self: TaskPage, buffer: Buffer, task: Task): TaskPage
---@field public print fun(self: TaskPage, buffer: Buffer): TaskPage
---@field private row fun(self: TaskPage, key: string, lines: table): TaskPage
local TaskPage = {}

--- Create a new TaskPage
---@param buffer Buffer
---@param task Task
---@return TaskPage
function TaskPage:new(buffer, task)
  local task_page = {}
  setmetatable(task_page, self)
  self.__index = self

  self.task = task
  self.used_keys = { "tags" }
  self.prefix_format = "%-13s | "
  self.buffer = buffer
  self.tram = Tram:new()
  self.tram:set_buffer(buffer)
  self.win_width = vim.api.nvim_win_get_width(_Neowarrior.window.id)

  return self
end

function TaskPage:from(from)
  self.tram:from(from)
  return self
end

--- Print the TaskPage
---
---@param buffer Buffer
---@return TaskPage
function TaskPage:print(buffer)

  buffer:option("wrap", false, { win = _Neowarrior.window.id })
  self.tram:set_buffer(buffer)

  HeaderComponent:new(self.tram)
    :disable_meta()
    :disable_report()
    :disable_filter()
    :set_help_item("modify", true)
    :set_help_item("filter", false)
    :set()

  self:completed()
  self:project()
  self:started()
  self.tram:line(self.task.description, {
    wrapped = vim.api.nvim_win_get_width(_Neowarrior.window.id) - 2,
  })

  if self.task.tags then
    self.tram:nl()
    TagsComponent:new(self.tram, self.task.tags):line()
  end

  self.tram:nl()

  self:dependencies()
  self:parents()

  self:annotations()

  self:urgency()
  self:estimate()
  self:priority()
  self:scheduled()
  self:wait()
  self:due()
  self:recur()
  self:ended()

  self.tram:nl()

  self:row('modified', {{
    text = "Modified",
  }, {
    text = self.task.modified_dt:relative() .. " (" .. self.task.modified_dt:default_format() .. ")",
    color = '',
  }})

  self:row('entry', {{ text = "Entry", }, {
    text = self.task.entry_dt:relative() .. " (" .. self.task.entry_dt:default_format() .. ")",
    color = '',
  }})

  for k, v in pairs(self.task:get_attributes()) do

    local used = false

    for _, u in ipairs(self.used_keys) do
      if u == k then
        used = true
        break
      end
    end

    if not used then

      if not (k == "description") and not (k == "parent") and not (k == "imask") and v then

        if type(k) == "table" then
          k = table.concat(k, ", ")
        end
        local value = self.task[k]
        if type(value) == "table" then
          value = table.concat(value, ", ")
        end
        self:row(k, {
          { text = k },
          { text = value, color = '' }
        })
      end

    end
  end -- for

  self.tram:print()

  return self
end

--- Add a row to the TaskPage
---@param cols table
---@return TaskPage
function TaskPage:row(key, cols)

  table.insert(self.used_keys, key)

  local len = 5

  for _, col in ipairs(cols) do
    len = len + string.len(tostring(col.text))
  end

  self.tram:col(cols[1].text, cols[1].color or '')
  self.tram:col(self:get_row_border(len), _Neowarrior.config.colors.dim.group)
  self.tram:into_line({})

  if cols[2] and cols[2].text then
    self.tram:virt_line(cols[2].text, {
      color = cols[2].color or '',
      pos = "right_align",
    })
  end

  return self
end

--- Completed row
function TaskPage:completed()

  if self.task.status and self.task.status == "completed" then
    -- table.insert(self.used_keys, 'status')
    self.tram:col("Task completed", _Neowarrior.config.colors.success.group)
    self.tram:into_line({})
  end

end

--- Project row
function TaskPage:project()

  table.insert(self.used_keys, 'project')
  if self.task.project then
    local project = Project:new({ name = self.task.project })
    ProjectLine:new(self.tram, project):into_line({
      disable_meta = true,
    })
  end

end

--- Started row
function TaskPage:started()

  table.insert(self.used_keys, 'start')

  if self.task.start_dt then
    self:row('start', {{
      text = "Task started: ",
      color = _Neowarrior.config.colors.danger.group,
    }, {
      text = self.task.start_dt:default_format(),
      color = _Neowarrior.config.colors.danger_bg.group,
    }})
  end

end

--- Ended row
function TaskPage:ended()

  table.insert(self.used_keys, 'end')

  if self.task.end_dt then
    self:row('end', {{
      text = "Task ended: ",
      color = _Neowarrior.config.colors.success.group,
    }, {
      text = self.task.end_dt:default_format(),
      color = _Neowarrior.config.colors.success.group,
    }})
  end

end

--- Annotation rows
function TaskPage:annotations()

  local annotations = self.task.annotations
  if annotations then

    self:row('annotations', {{
      text = _Neowarrior.config.icons.annotated .. " Annotations",
      color = _Neowarrior.config.colors.annotation.group,
    }})

    for _, annotation in ipairs(annotations) do

      local anno_entry = ''

      if annotation.entry then
        local anno_entry_dt = DateTime:new(annotation.entry)
        anno_entry = "" .. anno_entry_dt:default_format()
        self.tram:col(anno_entry, _Neowarrior.config.colors.annotation.group)
        self.tram:into_line({})
      end

      self.tram:line(annotation.description, {
        wrapped = vim.api.nvim_win_get_width(_Neowarrior.window.id) - 2,
      })

    end

    self.tram:nl()
  end

end

--- Get row border
function TaskPage:get_row_border(offset)
  return string.rep("_", self.win_width - offset - 1)
end

--- Urgency row
function TaskPage:urgency()

  self:row('urgency', {{
    text = "Urgency",
  }, {
    text = self.task.urgency,
    color = colors.get_urgency_color(self.task.urgency),
  }})

end

--- Estimate row
function TaskPage:estimate()

  if not self.task.estimate then
    return self
  end

  self:row('estimate', {{
    text = "Estimate",
  }, {
    text = self.task.estimate_string,
    color = colors.get_estimate_color(self.task.estimate),
  }})

  return self
end

--- Priority row
function TaskPage:priority()

  if not self.task.priority then
    return self
  end

  self:row('priority', {{
    text = "Priority",
  }, {
    text = self.task.priority,
    color = colors.get_priority_color(self.task.priority),
  }})

  return self
end

--- Scheduled row
function TaskPage:scheduled()

  table.insert(self.used_keys, 'scheduled')

  if self.task.scheduled_dt then
    self:row('scheduled', {{
      text = "Scheduled",
    }, {
      text = self.task.scheduled_dt:relative() .. " (" .. self.task.scheduled_dt:default_format() .. ")",
      color = colors.get_due_color(self.task.scheduled_dt:relative_hours()),
    }})
  end

end

--- Wait row
function TaskPage:wait()

  table.insert(self.used_keys, 'wait')

  if self.task.wait_dt then
    self:row('wait', {{
      text = "wait",
    }, {
      text = self.task.wait_dt:relative() .. " (" .. self.task.wait_dt:default_format() .. ")",
      color = colors.get_due_color(self.task.wait_dt:relative_hours()),
    }})
  end

end

--- Due row
function TaskPage:due()

  if self.task.due_dt then

    self:row('due', {{
      text = "Due",
    }, {
      text = _Neowarrior.config.icons.due .. " " .. self.task.due_dt:relative() .. " (" .. self.task.due_dt:default_format() .. ")",
      color = colors.get_due_color(self.task.due_dt:relative_hours()),
    }})
  end

end

--- Recur row
function TaskPage:recur()

  if self.task.recur then

    self:row('recur', {{
      text = "Recur",
    }, {
      text = _Neowarrior.config.icons.recur .. " " .. self.task.recur,
      color = _Neowarrior.config.colors.info.group,
    }})
  end

end

--- Show task dependencies
---@return TaskPage
function TaskPage:dependencies()

  if self.task.depends and self.task.depends:count() > 0 then

    self:row('depends', {{
      text = "Dependencies",
      color = _Neowarrior.config.colors.danger.group,
    }})

    for _, task in ipairs(self.task.depends:get()) do
      TaskLine:new(self.tram, task):into_line({
        back = { type = "task", uuid = self.task.uuid },
      })
    end

    self.tram:nl()

  end

  return self
end

--- Show task parents
function TaskPage:parents()

  local parents = self.task:create_parent_collection()

  if parents then

    self:row('parents', {{
      text = "Blocking these tasks",
      color = _Neowarrior.config.colors.warning.group,
    }})

    for _, task in ipairs(parents:get()) do
      TaskLine:new(self.tram, task):into_line({
        disable_meta = true,
        disable_has_blocking = true,
        back = { type = "task", uuid = self.task.uuid },
      })
    end

    self.tram:nl()

  end

  return self
end

return TaskPage
