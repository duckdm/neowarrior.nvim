local colors = require "neowarrior.colors"
local Line = require "neowarrior.Line"

---@class ProjectLine
---@field neowarrior NeoWarrior
---@field line_no number
---@field project Project
---@field arg table
local ProjectLine = {}

--- Create a new ProjectLine
---@param neowarrior NeoWarrior
---@param line_no number
---@param project Project
---@param arg table
---@return Line
function ProjectLine:new(neowarrior, line_no, project, arg)
    local project_component = {}
    setmetatable(project_component, self)
    self.__index = self

    self.neowarrior = neowarrior
    self.line_no = line_no
    self.project = project

    return self:get_project_line(arg)
end

--- Get project line data
---@param arg table
---@return Line[]
function ProjectLine:get_project_line(arg)

  local conf = self.neowarrior.config
  local line = Line:new(self.line_no)
  local indent = arg.indent or ""
  local open = arg.open or false
  local icon = open and conf.icons.project_open or conf.icons.project
  line:add({
    text = indent .. icon .. " " .. self.project.name,
    color = "NeoWarriorTextInfo",
  })

  local task_count = self.project.task_count
  if arg.enable_task_count and task_count > 0 then
    line:add({
      text = " " .. conf.icons.task .. " " .. task_count,
      color = "NeoWarriorTextDefault",
    })
  end

  if arg.enable_average_urgency then
    line:add({
      text = " " .. string.format("%.2f", self.project.urgency.average),
      color = colors.get_urgency_color(self.project.urgency.average),
    })
  end

  if arg.enable_total_urgency then
    line:add({
      text = " " .. string.format("%.2f", self.project.urgency.total),
      color = colors.get_urgency_color(self.project.urgency.total),
    })
  end

  line:add({
    meta = {
      project = self.project.id,
    },
  })

  return line
end

return ProjectLine
