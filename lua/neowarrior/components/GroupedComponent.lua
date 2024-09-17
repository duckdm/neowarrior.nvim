local ProjectLine = require('neowarrior.lines.ProjectLine')
local TaskLine = require('neowarrior.lines.TaskLine')
local Line = require('neowarrior.Line')

---@class GroupedComponent
---@field neowarrior NeoWarrior
---@field projects ProjectCollection
---@field lines Line[]
---@field new fun(self: GroupedComponent, neowarrior: NeoWarrior, project: Project): GroupedComponent
---@field get_lines fun(self: GroupedComponent): Line[]
---@field generate_lines fun(self: GroupedComponent, projects: ProjectCollection, line_no: number): number
local GroupedComponent = {}

--- Create a new GroupedComponent
---@param neowarrior NeoWarrior
---@param projects ProjectCollection
function GroupedComponent:new(neowarrior, projects)
    local grouped_component = {}
    setmetatable(grouped_component, self)
    self.__index = self

    grouped_component.neowarrior = neowarrior
    grouped_component.projects = projects
    grouped_component.lines = {}
    grouped_component.line_no = 0

    return grouped_component
end

--- Get grouped lines
---@return Line[]
function GroupedComponent:get_lines()
  self:generate_lines(self.projects, self.line_no)
  return self.lines
end

--- Generate grouped lines
---@param projects ProjectCollection
---@param line_no number 
---@return number Line number
function GroupedComponent:generate_lines(projects, line_no)

  local nw = self.neowarrior

  for _, project in ipairs(projects:get()) do

    local project_line = ProjectLine:new(nw, line_no, project, {
      id_as_name = true,
      enable_task_count = nw.config.project_line.enable_task_count,
      enable_average_urgency = nw.config.project_line.enable_average_urgency,
      enable_total_urgency = nw.config.project_line.enable_total_urgency,
      enable_total_estimate = nw.config.project_line.enable_total_estimate,
    })
    table.insert(self.lines, project_line)
    line_no = line_no + 1
    -- table.insert(self.lines, Line:new(line_no):add({ text = "" }))
    -- line_no = line_no + 1

    for _, task in ipairs(project.tasks:get()) do
      table.insert(self.lines, TaskLine:new(nw, line_no, task, {}))
      line_no = line_no + 1
    end

    table.insert(self.lines, Line:new(line_no):add({ text = "" }))
    line_no = line_no + 1

  end

  return line_no
end

return GroupedComponent

