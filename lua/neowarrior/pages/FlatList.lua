local Page = require('neowarrior.Page')
local TaskComponent = require('neowarrior.components.TaskComponent')
local HeaderComponent = require('neowarrior.components.HeaderComponent')

---@class FlatList
---@field neowarrior NeoWarrior
---@field task_collection TaskCollection
local FlatList = {}

--- Create a new FlatList
---@param neowarrior NeoWarrior
---@param task_collection TaskCollection
---@return FlatList
function FlatList:new(neowarrior, task_collection)
  local flat_list = {}
  setmetatable(flat_list, self)
  self.__index = self

  flat_list.neowarrior = neowarrior
  flat_list.task_collection = task_collection

  return flat_list
end

--- Print the FlatList
---@param buffer Buffer
---@return FlatList
function FlatList:print(buffer)

  local page = Page:new(self.neowarrior)
  local header = HeaderComponent:new(self.neowarrior, 0)
  -- page:add(header:get())

  for _, task in ipairs(self.task_collection:get()) do

    local task_component = TaskComponent:new(self.neowarrior, task, page.line_count)
    page:add(task_component:get({}))

  end

  page:print(buffer)

  return self
end

return FlatList
