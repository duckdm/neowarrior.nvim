local Window = require('trambampolin.Window')

---@class Float
---@field tram Trambampolin
---@field window Window
---@field opt table
---@field open fun(float: Float):Float
---@field close fun(float: Float):Float
local Float = {}

function Float:new(tram, opt)
    local float = {}
    setmetatable(float, self)
    self.__index = self

    self.tram = tram
    self.window = nil
    self.opt = opt

    return self
end

--- Open float
---@return Float
function Float:open()

  local buffer = self.tram:get_buffer()

  self.window = Window:new({
    id = -1,
    buffer = buffer,
    enter = self.opt.enter or false,
  }, {
    relative = self.opt.relative or 'editor',
    border = self.opt.border or 'rounded',
    title = self.opt.title or nil,
    width = self.opt.width or 30,
    height = self.opt.height or self.tram:get_line_no(),
    col = self.opt.col or 0,
    row = self.opt.row or 1,
    anchor = self.opt.anchor or 'NW',
    style = self.opt.style or 'minimal'
  })
  buffer:option('wrap', true, { win = self.window.id })
  buffer:option('linebreak', true, { win = self.window.id })

  return self
end

--- Close float
---@return Float
function Float:close()
  local win = self.window and self.window.id or nil
  if win and vim.api.nvim_win_is_valid(win) then
    self.window:close()
  end
  return self
end

return Float
