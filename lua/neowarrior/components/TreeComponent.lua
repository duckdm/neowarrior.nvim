local ProjectLine = require('neowarrior.lines.ProjectLine')
local TaskLine = require('neowarrior.lines.TaskLine')

---@class TreeComponent
---@field neowarrior NeoWarrior
---@field project Project
---@field lines Line[]
---@field new fun(self: TreeComponent, neowarrior: NeoWarrior, project: Project): TreeComponent
---@field get_lines fun(self: TreeComponent): Line[]
---@field generate_lines fun(self: TreeComponent, project: Project, indent: string, line_no: number): number
local TreeComponent = {}

--- Create a new TreeComponent
---@param neowarrior NeoWarrior
---@param project Project
function TreeComponent:new(neowarrior, project)
    local tree_component = {}
    setmetatable(tree_component, self)
    self.__index = self

    tree_component.neowarrior = neowarrior
    tree_component.project = project
    tree_component.lines = {}

    return tree_component
end

--- Get tree lines
---@return Line[]
function TreeComponent:get_lines()
  self:generate_lines(self.project, '', 0)
  return self.lines
end

function TreeComponent:generate_lines(project, indent, line_no)

  local config = self.neowarrior.config.project_line

  for _, sub_project in ipairs(project.projects:get()) do

    -- if sub_project.projects:count() > 0 or sub_project.tasks:count() > 0 then

      local project_line = ProjectLine:new(self.neowarrior, line_no, sub_project, {
        indent = indent,
        enable_task_count = config.enable_task_count,
        enable_average_urgency = config.enable_average_urgency,
        enable_total_urgency = config.enable_total_urgency,
        enable_total_estimate = config.enable_total_estimate,
        open = self.neowarrior.toggled_trees[sub_project.id],
      })
      table.insert(self.lines, project_line)
      line_no = line_no + 1

      if self.neowarrior.toggled_trees[sub_project.id] then
        line_no = self:generate_lines(sub_project, indent .. "  ", line_no)
      end

    -- end
  end

  -- if self.neowarrior.toggled_trees[project.id] then
    for _, task in ipairs(project.tasks:get()) do
      local task_line = TaskLine:new(self.neowarrior, line_no, task, { indent = indent })
      table.insert(self.lines, task_line)
      line_no = line_no + 1
    end
  -- end

  return line_no
end

return TreeComponent
