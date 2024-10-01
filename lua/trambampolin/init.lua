local Buffer = require("trambampolin.Buffer")
local Line = require("trambampolin.Line")
local Float = require("trambampolin.Float")
local util = require("neowarrior.util")

---@class Trambampolin
---@field version string
---@field lines Line[]
---@field line_no number
---@field buffer Buffer
---@field columns table
---@field print fun(self: Trambampolin): Trambampolin
---@field set_buffer fun(self: Trambampolin, buffer: Buffer): Trambampolin
---@field get_buffer fun(self: Trambampolin): Buffer
---@field line fun(self: Trambampolin, text: string, opts: table): Trambampolin
---@field virt_line fun(self: Trambampolin, text: string, opts: table): Trambampolin
---@field inc fun(self: Trambampolin): Trambampolin
---@field get_line_no fun(self: Trambampolin): number
---@field col fun(self: Trambampolin, text: string|number, color: string|table): Trambampolin
---@field into_line fun(self: Trambampolin, opts: table): Trambampolin
---@field into_virt_line fun(self: Trambampolin, opts: table): Trambampolin
local M = {}

--- Constructor
---@return Trambampolin
function M:new()
    local m = {}
    setmetatable(m, self)
    self.__index = self

    m.version = "v0.0.1"
    m.lines = {}
    m.line_no = 0
    m.buffer = nil
    m.columns = {}

    return m
end

--- Print buffer
---@return Trambampolin
function M:print()

    local buffer = self:get_buffer()
    buffer:print(self.lines, 0)

    return self
end

--- Get meta data.
--- Note! This must not be called before print.
---
---@param line_no number
---@param key string|nil Pass nil to get all meta data for the line.
---@return any
function M:get_meta_data(line_no, key)
    line_no = line_no - 1
    for _, line in ipairs(self.lines) do
        if line.line_no == line_no then
            if key == nil then
                return line.meta_data
            elseif line.meta_data and line.meta_data[key] then
                return line.meta_data[key]
            end
        end
    end
    return nil
end

function M:get_line_meta_data(key)
    local line_no = vim.api.nvim_win_get_cursor(0)[1]
    return self:get_meta_data(line_no, key)
end

--- Open float
---@param opts table 
---@return Float
function M:open_float(opts)

    local float = Float:new(self, vim.tbl_extend('force', {
        title = nil,
        width = 10,
        col = 0,
        row = 1,
        enter = false,
    }, opts))
    float:open()

    return float
end

--- Close float
---@param float Float
---@return Trambampolin
function M:close_float(float) float:close() return self end

--- Create buffer
---@param opt table
---@return Buffer
function M:create_buffer(opt)

    self.buffer = Buffer:new(vim.tbl_extend('force', {
        listed = false,
        scratch = true
    }, opt))

    return self.buffer
end

--- Set buffer
---@param buffer Buffer
---@return Trambampolin
function M:set_buffer(buffer)
    self.buffer = buffer
    return self
end

--- Get buffer
---@return Buffer
function M:get_buffer()
    if self.buffer then return self.buffer end
    return self:create_buffer({})
end

--- Add a line to the buffer
---@param text string|number
---@param opts table
---@return Trambampolin
function M:line(text, opts)

    local wrapped = opts.wrapped or nil
    if wrapped then opts.wrapped = nil end

    self:get_buffer()
    if wrapped then
        wrapped = wrapped - 2
        local words = vim.split(tostring(text), " ")
        local total_line_len = 0
        for _, word in ipairs(words) do
            total_line_len = total_line_len + string.len(word) + 1
            if total_line_len >= wrapped then
                self:into_line(opts)
                self:col(word .. " ", opts.color or "")
                total_line_len = string.len(word) + 1
            else
                self:col(word .. " ", opts.color or "")
            end
        end
    else
        self:col(text, opts.color or "")
    end
    self:into_line(opts)

    return self
end

--- Add a virtual line to the buffer
---@param text string|number
---@param opts table
---@return Trambampolin
function M:virt_line(text, opts)

    self:get_buffer()
    self:col(text, opts.color or "")
    self:into_virt_line(opts)

    return self
end

--- Add a column to the buffer
---@param text string|number
---@param color string|table
---@return Trambampolin
function M:col(text, color)
    self:get_buffer()
    local ns_name = nil
    if type(color) == "table" then
        ns_name = color.ns_name
        color = color.color
    end
    table.insert(self.columns, { text = text, color = color, ns_name = ns_name })
    return self
end

--- Add a line to the buffer
---@param opts table
---@return Trambampolin
function M:into_line(opts)

    local line = Line:new()
    for _, column in ipairs(self.columns) do
        line:col({
            text = column.text,
            color = column.color,
            ns_name = column.ns_name or nil,
            line_no = opts.line_no or self.line_no,
            pos = opts.pos or "overlay",
            col = opts.col or nil,
            meta = opts.meta or nil,
        })
    end
    table.insert(self.lines, line)
    self:inc()
    self.columns = {}

    return self
end

--- Add a virtual line to the buffer
---@param opts table
---@return Trambampolin
function M:into_virt_line(opts)

    local line = Line:new()
    for _, column in ipairs(self.columns) do
        line:col({
            virt_text = column.text,
            color = column.color,
            ns_name = column.ns_name or nil,
            line_no = opts.line_no or nil,
            pos = opts.pos or "overlay",
            col = opts.col or nil,
            strict_col = opts.strict_col or nil,
        })
    end
    table.insert(self.lines, line)
    self.columns = {}

    return self
end

--- Add a new line
---@return Trambampolin
function M:nl()
    self:line("__NL__", "")
    return self
end

--- Get line number
---@return number
function M:get_line_no()
    return self.line_no
end

--- Set line number
---@param line_no number
---@return Trambampolin
function M:from(line_no)
    self.line_no = line_no
    return self
end

--- Increment line number
---@return Trambampolin
function M:inc()
    self.line_no = self.line_no + 1
    return self
end

return M
