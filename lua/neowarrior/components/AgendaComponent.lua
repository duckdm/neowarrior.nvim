local TaskLine = require('neowarrior.lines.TaskLine')
local util = require('neowarrior.util')
local colors = require('neowarrior.colors')

---@class AgendaComponent
local AgendaComponent = {}

--- Create a new AgendaComponent
---@param tram Trambampolin
function AgendaComponent:new(tram)
    local agenda_component = {}
    setmetatable(agenda_component, self)
    self.__index = self

    self.tram = tram

    return self
end

--- Get grouped lines
---@param tasks TaskCollection
---@return AgendaComponent
function AgendaComponent:set(tasks)
  self:_set(tasks)
  return self
end

--- Generate grouped lines
---@param tasks TaskCollection
---@return AgendaComponent
function AgendaComponent:_set(tasks)

  local dates = {}
  local dates_array = {}
  local tasks_without_due = {}

  for _, task in ipairs(tasks:get()) do
    if task.due_dt then
      local date_key = task.due_dt:format('%Y%m%d')
      if not dates[date_key] then
        dates[date_key] = {
          date = task.due_dt,
          ord = task.due_dt:format("%Y%m%d"),
          tasks = {},
        }
      end
      table.insert(dates[date_key].tasks, task)
    else
      table.insert(tasks_without_due, task)
    end
  end

  for _, date in pairs(dates) do
    table.insert(dates_array, date)
  end

  table.sort(dates_array, function(a, b) return a.ord < b.ord end)

  for _, date in ipairs(dates_array) do

    local nice_date = date.date:nice()
    local color = _Neowarrior.config.colors.info.group
    if nice_date:find("days ago") or nice_date:find("Yesterday") then
      color = _Neowarrior.config.colors.danger.group
    end
    self.tram:col(nice_date, { color = color })
    self.tram:col(" (" .. date.date:format('%A, %B %d') .. ")", {
      color = _Neowarrior.config.colors.dim.group
    })
    self.tram:into_line({})

    table.sort(date.tasks, function(a, b) return a.due < b.due end)

    for _, task in ipairs(date.tasks) do

      local time_color = colors.get_due_color(task.due_dt:diff_hours())
      self.tram:col(task.due_dt:format('%H:%M'), { color = time_color })
      self.tram:col(": ", {})
      TaskLine:new(self.tram, task):into_line({
        disable_due = true,
      })

    end

    self.tram:nl()

  end

  if util.table_size(tasks_without_due) > 0 then

    self.tram:line("Tasks without due date", { color = _Neowarrior.config.colors.warning.group })
    for _, task in ipairs(tasks_without_due) do

      TaskLine:new(self.tram, task):into_line({})

    end

  end

  return self
end

return AgendaComponent

