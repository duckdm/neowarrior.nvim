local ProjectLine = require('neowarrior.lines.ProjectLine')
local TaskLine = require('neowarrior.lines.TaskLine')

---@class TreeComponent
---@field project Project
---@field lines Line[]
---@field new fun(self: TreeComponent, tram: Trambampolin, project: Project): TreeComponent
---@field get_lines fun(self: TreeComponent): Line[]
---@field generate_lines fun(self: TreeComponent, project: Project, indent: string, line_no: number): number
local TreeComponent = {}

--- Create a new TreeComponent
---@param project Project
function TreeComponent:new(tram, project)
    local tree_component = {}
    setmetatable(tree_component, self)
    self.__index = self

    self.project = project
    self.tram = tram

    return self
end

function TreeComponent:set()
  self:_set(self.project, "")
  return self
end

function TreeComponent:_set(project, indent)

  local config = _Neowarrior.config.project_line

  for _, sub_project in ipairs(project.projects:get()) do

    ProjectLine:new(_Neowarrior, self.tram, sub_project):into_line({
      indent = indent,
      enable_task_count = config.enable_task_count,
      enable_average_urgency = config.enable_average_urgency,
      enable_total_urgency = config.enable_total_urgency,
      enable_total_estimate = config.enable_total_estimate,
      open = _Neowarrior.toggled_trees[sub_project.id],
    })

    if _Neowarrior.toggled_trees[sub_project.id] then
      self:_set(sub_project, indent .. "  ")
    end

  end

  for _, task in ipairs(project.tasks:get()) do
    TaskLine:new(self.tram, task):into_line({
      indent = indent,
    })
  end

  return self
end

return TreeComponent
