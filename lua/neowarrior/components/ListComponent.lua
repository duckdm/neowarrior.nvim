local TaskLine = require('neowarrior.lines.TaskLine')
local Component = require('neowarrior.Component')
local TreeComponent = require('neowarrior.components.TreeComponent')
local GroupedComponent = require('neowarrior.components.GroupedComponent')

---@class ListComponent
---@field neowarrior NeoWarrior
local ListComponent = {}

--- Create a new ListComponent
---@param neowarrior NeoWarrior
---@param task_collection TaskCollection
---@return Component
function ListComponent:new(neowarrior, task_collection)
    local header_component = {}
    setmetatable(header_component, self)
    self.__index = self

    self.neowarrior = neowarrior
    self.task_collection = task_collection
    self.line_no = 0

    local component = Component:new()
    component.type = 'ListComponent'
    component:add(self:get_lines())

    return component
end

--- Get header line data
---@return Line[]
function ListComponent:get_lines()

  local nw = self.neowarrior
  nw:refresh()

  if nw.current_mode == 'tree' then

    local tree = TreeComponent:new(nw, nw.project_tree)
    return tree:get_lines()

  elseif nw.current_mode == 'grouped' then

    local grouped = GroupedComponent:new(nw.projects)
    return grouped:get_lines()

  end

  return self:get_task_lines(self.task_collection, {})
end

--- Get task lines
---@return Line[]
function ListComponent:get_task_lines(task_collection, lines)

  for _, task in ipairs(task_collection:get()) do

    table.insert(lines, TaskLine:new(self.neowarrior, self.line_no, task, {}))
    self.line_no = self.line_no + 1

  end

  return lines
end

return ListComponent
