local ProjectLine = require "neowarrior.lines.ProjectLine"
local TaskLine = require "neowarrior.lines.TaskLine"
local colors = require "neowarrior.colors"
local NumberValuesComponent = require "neowarrior.components.NumberValuesComponent"

local Trambampolin = require "trambampolin.init"
---@class ProjectPage
---@field tram Trambampolin
---@field project Project
---@field group_key string
---@field win_width number
local ProjectPage = {}

function ProjectPage:new(buffer, project, group_key)
  local project_page = {}
  setmetatable(project_page, self)

  self.__index = self

  project_page.tram = Trambampolin:new()
  project_page.tram:set_buffer(buffer)
  project_page.project = _Neowarrior.all_projects:find(project)
  project_page.group_key = group_key
  project_page.win_width = vim.api.nvim_win_get_width(_Neowarrior.window.id)

  return project_page
end

function ProjectPage:lines(group_key)

  self.tram:clear()

  local project = self.project
  ProjectLine:new(self.tram, project):into_line({
    id_as_name = true,
  })

  self.tram:nl()

  NumberValuesComponent:new(self.tram, "Urgency")
    :add("avg", project.urgency.average, colors.get_urgency_color(project.urgency.average))
    :add("total", project.urgency.total, colors.get_urgency_color(project.urgency.total))
    :add("max", project.urgency.max, colors.get_urgency_color(project.urgency.max))
    :add("min", project.urgency.min, colors.get_urgency_color(project.urgency.min))
  self.tram:into_line({})

  NumberValuesComponent:new(self.tram, "Estimate")
    :decimals(2)
    :add("avg", project.estimate.average, colors.get_estimate_color(project.estimate.average))
    :add("total", project.estimate.total, colors.get_estimate_color(project.estimate.total))
    :add("max", project.estimate.max, colors.get_estimate_color(project.estimate.max))
    :add("min", project.estimate.min, colors.get_estimate_color(project.estimate.min))
  self.tram:into_line({})

  self.tram:nl()

  local disabled_args = {
    disable_due = true,
    disable_estimate = true,
    disable_has_blocking = true,
  }

  local groups = {
    {
      name = "Pending",
      filter = "status:pending",
      next = "Waiting",
      prev = "Deleted",
    },
    {
      name = "Waiting",
      filter = "status:waiting",
      next = "Completed",
      prev = "Pending",
    },
    {
      name = "Completed",
      filter = "status:completed",
      next = "Deleted",
      prev = "Waiting",
      args = disabled_args
    },
    {
      name = "Deleted",
      filter = "status:deleted",
      next = "Pending",
      prev = "Completed",
      args = disabled_args
    },
  }

  local group = groups[1]

  for _, group_data in ipairs(groups) do

    local filter = group_data.filter .. " project:" .. project.name
    local cache_key = "all_" .. filter

    if _Neowarrior.task_cache[cache_key] then

      group_data.tasks = _Neowarrior.task_cache[cache_key]

    else

      local tasks = _Neowarrior.tw:tasks("all", filter)
      tasks:sort(_Neowarrior.current_sort, _Neowarrior.current_sort_direction)
      group_data.tasks = tasks
      _Neowarrior.task_cache[cache_key] = tasks

    end

    if group_key == group_data.name:lower() then
      group = group_data
    end

  end

  self.tram.buffer:keymap("n", _Neowarrior.config.keys.next_tab, function()
    self.tram.buffer:save_cursor()
    self:print(group.next:lower())
    self.tram.buffer:restore_cursor()
  end, { noremap = true, silent = true })

  self.tram.buffer:keymap("n", _Neowarrior.config.keys.prev_tab, function()
    self.tram.buffer:save_cursor()
    self:print(group.prev:lower())
    self.tram.buffer:restore_cursor()
  end, { noremap = true, silent = true })

  local active_group_color = _Neowarrior.config.colors.info.group

  for _, group_data in pairs(groups) do

    local count = ""
    local group_color = ""

    if group_data.tasks and group_data.tasks:count() > 0 then
      count = " (" .. group_data.tasks:count() .. ")"
    else
      group_color = _Neowarrior.config.colors.dim.group
    end

    group_color = group_key == group_data.name:lower() and active_group_color or group_color

    self.tram:col(group_data.name .. count, group_color)
    self.tram:col(" | ", "")

  end

  self.tram:into_line({})
  self.tram:nl()

  local task_args = group.args or {}
  for _, task in ipairs(group.tasks:get()) do

    task_args = vim.tbl_extend("force", task_args, {
      meta = {
        project = project,
        back = {
          type = "project",
          project = project.id,
        }
      },
    })
    TaskLine:new(self.tram, task):into_line(task_args)

  end


end

function ProjectPage:print(group_key)

  self:lines(group_key)
  self.tram:print()

end

--- Add a row to the TaskPage
---@param cols table
---@return ProjectPage
function ProjectPage:row(cols)

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

--- Get row border
function ProjectPage:get_row_border(offset)
  return string.rep("_", self.win_width - offset - 1)
end

return ProjectPage
