local date = require('tieske.date')

---@class DateTime
---@field date string
---@field year number?
---@field month number?
---@field day number?
---@field hour number?
---@field minute number?
---@field second number?
---@field timestamp number?
---@field offset number
---@field new fun(self: DateTime, date: string|nil): DateTime
---@field parse fun(self: DateTime, str: string|nil): number
---@field format fun(self: DateTime, format: string): string|osdate
---@field default_format fun(self: DateTime): string|osdate
---@field relative fun(self: DateTime): string
local DateTime = {}

--- Create new datetime
---@param input string|nil
---@return DateTime
function DateTime:new(input)

  local datetime = {}
  setmetatable(datetime, self)

  self.__index = self

  datetime.date = date(input)

  return datetime
end

--- Format date
---@param format string
---@return string|osdate
function DateTime:format(format)
  return self.date:fmt(format)
end

--- Get default formatted date
---@return string|osdate
function DateTime:default_format()
  return self:format('%Y-%m-%d, %H:%M')
end

--- Function to calculate the time difference
---@return number Diff in seconds
function DateTime:diff()
  local now = DateTime:new(nil)
  return date.diff(self.date, now.date):spanseconds()
end

--- Function to calculate the time difference
---@return dateObject
function DateTime:diff_object()
  local now = DateTime:new(nil)
  return date.diff(self.date, now.date)
end

-- Function to calculate the relative time difference
---@return string
function DateTime:relative()

  local diff = self:diff_object()
  local years = math.ceil(diff:spandays()) and math.ceil(diff:spandays() / 365) or 0
  local months = math.ceil(diff:spandays()) and math.ceil(diff:spandays() / 30) or 0
  local days = math.ceil(diff:spandays()) and math.ceil(diff:spandays()) or 0
  local hours = math.ceil(diff:spanhours()) and math.ceil(diff:spanhours()) or 0
  local minutes = math.ceil(diff:spanminutes()) and math.ceil(diff:spanminutes()) or 0
  local seconds = diff:spanseconds()

  if years > 1 or years < 0 then
    return years .. "y"
  end

  if months > 1 or months < 0 then
    return months .. "mon"
  end

  if days > 1 or days < 0 then
    return days .. "d"
  end

  if hours > 1 or hours < 0 then
    return hours .. "h"
  end

  if minutes > 1 or minutes < 0 then
    return minutes .. "m"
  end

  return seconds .. "s"

end

--- Get relative hours
--- @return number
function DateTime:relative_hours()
  local diff = self:diff_object()
  return diff:spanhours()
end

return DateTime
