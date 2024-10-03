local TaskLine = require('neowarrior.lines.TaskLine')
local TreeComponent = require('neowarrior.components.TreeComponent')
local GroupedComponent = require('neowarrior.components.GroupedComponent')
local AgendaComponent = require('neowarrior.components.AgendaComponent')

---@class ListComponent
---@field task_collection TaskCollection
---@field line_no number
local ListComponent = {}

--- Create a new ListComponent
---@param tram Trambampolin
---@param task_collection TaskCollection
---@return ListComponent
function ListComponent:new(tram, task_collection)
    local header_component = {}
    setmetatable(header_component, self)
    self.__index = self

    self.task_collection = task_collection
    self.tram = tram

    return self
end

--- Get header line data
---@return ListComponent
function ListComponent:set()

  if _Neowarrior.current_mode == 'tree' then

    TreeComponent:new(self.tram, _Neowarrior.project_tree):set()
    return self

  elseif _Neowarrior.current_mode == 'grouped' then

    GroupedComponent:new(self.tram, _Neowarrior.grouped_projects):set()
    return self

  elseif _Neowarrior.current_mode == "agenda" then

    AgendaComponent:new(self.tram):set(self.task_collection)
    return self

  end

  self:build_task_lines(self.task_collection)

  return self
end

--- Get task lines
--- @return self
function ListComponent:build_task_lines(task_collection)

  for _, task in ipairs(task_collection:get()) do

    TaskLine:new(self.tram, task):into_line({})

  end

  return self
end

return ListComponent
