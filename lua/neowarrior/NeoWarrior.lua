---@class NeoWarrior
---@field public new fun(self:NeoWarrior):NeoWarrior
---@field public setup fun(self:NeoWarrior, config:NeoWarrior.Config):NeoWarrior
---@field public open fun(self:NeoWarrior, opt):NeoWarrior
local M = {}

--- Constructor
---@return NeoWarrior
function M:new()
    local taskwarrior = {}
    setmetatable(taskwarrior, self)
    self.__index = self
    return taskwarrior
end

--- Setup
---@param opts NeoWarrior.Config
---@return NeoWarrior
function M:setup(opts)
  self.opts = opts
  return self
end

--- Open
---@param opt table
---@return NeoWarrior
function M:open(opt)
  return self
end
