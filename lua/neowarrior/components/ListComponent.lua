local Line = require('neowarrior.Line')
local Component = require('neowarrior.Component')

---@class ListComponent
---@field neowarrior NeoWarrior
local ListComponent = {}

--- Create a new ListComponent
---@param neowarrior NeoWarrior
---@param line_no number
---@return ListComponent
function ListComponent:new(neowarrior, line_no)
    local header_component = {}
    setmetatable(header_component, self)
    self.__index = self

    self.line_no = line_no
    self.neowarrior = neowarrior

    local component = Component:new(line_no)
    component:add(self:get())

    return component
end

--- Get header line data
---@return Line[]
function ListComponent:get()

  local lines = {}

  return lines
end

return ListComponent
