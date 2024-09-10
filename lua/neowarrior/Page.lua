---@class Page
---@field neowarrior NeoWarrior
---@field lines table
---@field colors table
---@field line_count number
local Page = {}

function Page:new(neowarrior)
  local page = {}
  setmetatable(page, self)
  self.__index = self

  page.neowarrior = neowarrior
  page.lines = {}
  page.colors = {}
  page.line_count = 0

  return page
end

function Page:reset()
  self.lines = {}
  self.colors = {}
  self.line_count = 0
end

--- Add line to page
---@param lines Line|Line[]
---@return Page
function Page:add(lines)

  if type(lines) ~= 'table' then
    lines = { lines }
  end

  for _, line in ipairs(lines) do
    table.insert(self.lines, line.text .. line.meta_text)
    self.line_count = self.line_count + 1

    for _, color in ipairs(line.colors) do
      table.insert(self.colors, color)
    end
  end

  return self
end

--- Add raw string to page
---@param string string
---@return Page
function Page:add_raw(string)
  table.insert(self.lines, string)
  self.line_count = self.line_count + 1
  return self
end

--- Add empty line to page
---@return Page
function Page:nl()
  table.insert(self.lines, '')
  self.line_count = self.line_count + 1
  return self
end

--- Print page
---@param buffer Buffer
---@return Page
function Page:print(buffer)

  buffer:unlock()
  vim.api.nvim_buf_set_lines(buffer.id, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(buffer.id, 0, -1, false, self.lines)
  for _, color in ipairs(self.colors) do
    if color and color.line and color.group and color.from and color.to then
      vim.api.nvim_buf_add_highlight(buffer.id, -1, color.group, color.line, color.from, color.to)
    end
  end
  buffer:lock()

  self:reset()

  return self
end

--- Get line count
---@return number
function Page:get_line_count()
  return self.line_count
end

return Page
