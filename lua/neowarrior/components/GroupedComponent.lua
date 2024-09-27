local ProjectLine = require('neowarrior.lines.ProjectLine')
local TaskLine = require('neowarrior.lines.TaskLine')
local Line = require('neowarrior.Line')

---@class GroupedComponent
---@field neowarrior NeoWarrior
---@field projects ProjectCollection
---@field line_no number
---@field lines Line[]
---@field new fun(self: GroupedComponent, tram: Trambampolin, projects: ProjectCollection): GroupedComponent
---@field get_lines fun(self: GroupedComponent): Line[]
---@field generate_lines fun(self: GroupedComponent, projects: ProjectCollection, line_no: number): number
local GroupedComponent = {}

--- Create a new GroupedComponent
---@param projects ProjectCollection
function GroupedComponent:new(tram, projects)
    local grouped_component = {}
    setmetatable(grouped_component, self)
    self.__index = self

    self.projects = projects
    self.tram = tram

    return self
end

--- Get grouped lines
---@return GroupedComponent
function GroupedComponent:set()
  self:_set(self.projects)
  return self
end

--- Generate grouped lines
---@param projects ProjectCollection
---@return GroupedComponent
function GroupedComponent:_set(projects)

  local nw = _Neowarrior

  for _, project in ipairs(projects:get()) do

    ProjectLine:new(self.tram, project):into_line({
      id_as_name = true,
      enable_task_count = nw.config.project_line.enable_task_count,
      enable_average_urgency = nw.config.project_line.enable_average_urgency,
      enable_total_urgency = nw.config.project_line.enable_total_urgency,
      enable_total_estimate = nw.config.project_line.enable_total_estimate,
    })

    for _, task in ipairs(project.tasks:get()) do
      TaskLine:new(self.tram, task):into_line({})
    end

    self.tram:nl()

  end

  return self
end

return GroupedComponent

