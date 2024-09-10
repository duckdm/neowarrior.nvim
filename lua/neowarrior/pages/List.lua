local FlatList = require('neowarrior.pages.FlatList')

---@class List
---@field neowarrior NeoWarrior
---@field task_collection TaskCollection
local List = {}

--- Create a new FlatList
---@param neowarrior NeoWarrior
---@param task_collection TaskCollection
---@return FlatList
function List:new(neowarrior, task_collection)
  local list = {}
  setmetatable(list, self)
  self.__index = self

  list.neowarrior = neowarrior
  list.task_collection = task_collection

  return list
end

--- Print the List
---@param buffer Buffer
---@return List
function List:print(buffer)

  self.neowarrior:refresh()

  if self.neowarrior.current_mode == 'tree' then
  elseif self.neowarrior.current_mode == 'grouped' then
  else
    local flat_list = FlatList:new(self.neowarrior, self.task_collection)
    flat_list:print(buffer)
  end

  return self
end

return FlatList
