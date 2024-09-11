local TaskComponent = require('neowarrior.components.TaskComponent')
local Component = require('neowarrior.Component')

---@class ListComponent
---@field neowarrior NeoWarrior
local ListComponent = {}

--- Create a new ListComponent
---@param neowarrior NeoWarrior
---@param line_no number
---@param task_collection TaskCollection
---@return Component
function ListComponent:new(neowarrior, line_no, task_collection)
    local header_component = {}
    setmetatable(header_component, self)
    self.__index = self

    self.neowarrior = neowarrior
    self.line_no = line_no
    self.task_collection = task_collection

    local component = Component:new(line_no)
    component:add(self:get())

    return component
end

--- Get header line data
---@return Line[]
function ListComponent:get()

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

  for _, task in ipairs(task_collection:get()) do

    local task_component = TaskComponent:new(self.neowarrior, self.line_no, task, {})
    task_component:debug()
    table.insert(lines, task_component:get())

  end

  return lines
end

return ListComponent
