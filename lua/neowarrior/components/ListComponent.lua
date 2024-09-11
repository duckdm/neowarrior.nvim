local TaskLine = require('neowarrior.lines.TaskLine')
local Component = require('neowarrior.Component')

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

    local component = Component:new()
    component.type = 'ListComponent'
    component:add(self:get_lines())

    return component
end

--- Get header line data
---@return Line[]
function ListComponent:get_lines()

  self.neowarrior:refresh()

  if self.neowarrior.current_mode == 'tree' then
  elseif self.neowarrior.current_mode == 'grouped' then
  end

  return self:get_task_lines(self.task_collection)
end

--- Get task lines
---@return Line[]
function ListComponent:get_task_lines(task_collection)

  local lines = {}
  local line_no = 0

  for _, task in ipairs(task_collection:get()) do

    table.insert(lines, TaskLine:new(self.neowarrior, line_no, task, {}))
    line_no = line_no + 1

  end

  return lines
end

return ListComponent
