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

    window.id = arg.id or -1
    window.buffer = arg.buffer
    window.enter = arg.enter or false

    window.opt = vim.tbl_extend('force', {
        win = window.id,
        split = 'below',
    }, opt or {})

    if window.id == -1 then
      window.id = vim.api.nvim_open_win(window.buffer.id, window.enter, opt)
    end

    return window
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
