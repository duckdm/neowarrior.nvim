local NeoWarrior = require('neowarrior.NeoWarrior')
local neowarrior = NeoWarrior:new()

local M = {}

--- Setup
---@param opts table
M.setup = function(opts)

  neowarrior:setup(opts)
  neowarrior:init()

end

M.open = function() neowarrior:open({ split = 'below' }) end
M.open_current = function() neowarrior:open({ split = 'current' }) end
M.open_below = function() neowarrior:open({ split = 'below' }) end
M.open_above = function() neowarrior:open({ split = 'above' }) end
M.open_left = function() neowarrior:open({ split = 'left' }) end
M.open_right = function() neowarrior:open({ split = 'right' }) end

return M
