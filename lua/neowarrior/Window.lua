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
    window.enter = arg.enter or true

    window.opt = vim.tbl_extend('force', {
        win = window.id,
        split = 'below',
    }, opt or {})

    if window.id == -1 then
      window.id = vim.api.nvim_open_win(window.buffer.id, window.enter, opt)
    end

    return window
end

return Window
