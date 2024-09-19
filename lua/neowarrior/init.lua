local NeoWarrior = require('neowarrior.NeoWarrior')
_Neowarrior = NeoWarrior:new()

local M = {}

--- Setup
---@param opts table
M.setup = function(opts)

  _Neowarrior:setup(opts)
  _Neowarrior:init()

end

M.open = function() _Neowarrior:open({ split = 'below' }) end
M.open_current = function() _Neowarrior:open({ split = 'current' }) end
M.open_below = function() _Neowarrior:open({ split = 'below' }) end
M.open_above = function() _Neowarrior:open({ split = 'above' }) end
M.open_left = function() _Neowarrior:open({ split = 'left' }) end
M.open_right = function() _Neowarrior:open({ split = 'right' }) end
M.focus = function() _Neowarrior:focus() end

return M
