local Window = require('neowarrior.Window')

---@class Float
---@field page Page
---@field window Window
---@field opt table
---@field open fun(float: Float):Float
---@field close fun(float: Float):Float
local Float = {}

function Float:new(page, opt)
    local float = {}
    setmetatable(float, self)
    self.__index = self

    float.page = page
    float.window = nil
    float.opt = opt

    return float
end

--- Open float
---@return Float
function Float:open()

  self.window = Window:new({
    id = -1,
    buffer = self.page.buffer,
    enter = self.opt.enter or false,
  }, {
    relative = self.opt.relative or 'editor',
    border = self.opt.border or 'rounded',
    title = self.opt.title or nil,
    width = self.opt.width or 30,
    height = self.opt.height or self.page:get_line_count(),
    col = self.opt.col or 0,
    row = self.opt.row or 1,
    anchor = self.opt.anchor or 'NW',
    style = self.opt.style or 'minimal'
  })
  self.page.buffer:option('wrap', true, { win = self.window.id })
  self.page.buffer:option('linebreak', true, { win = self.window.id })
  self.page:print()

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
