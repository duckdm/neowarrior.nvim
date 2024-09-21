---@class Window
---@field public id number
---@field public buffer Buffer
---@field public win number
---@field public split string
---@field public enter boolean
local Window = {}

--- Constructor
---@param arg table { buffer: Buffer, enter: boolean }
---@param opt table
---@return Window
function Window:new(arg, opt)
    local window = {}
    setmetatable(window, self)
    self.__index = self

    self.id = arg.id or -1
    self.buffer = arg.buffer
    self.enter = arg.enter or false

    self.opt = vim.tbl_extend('force', {
        win = self.id,
        split = 'below',
    }, opt or {})

    if self.id == -1 then
      self.id = vim.api.nvim_open_win(self.buffer.id, self.enter, opt)
    end

    return self
end

--- Get window width
---@return number
function Window:get_width()
    return vim.api.nvim_win_get_width(self.id)
end

--- Close window
function Window:close()
  vim.api.nvim_win_close(self.id, true)
end

return Window
