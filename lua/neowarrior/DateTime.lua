---@class DateTime
---@field date string
---@field year number
---@field month number
---@field day number
---@field hour number
---@field minute number
---@field second number
---@field timestamp number
---@field offset number
---@field new fun(self: DateTime, date: string): DateTime
---@field parse fun(self: DateTime, str: string): number
---@field format fun(self: DateTime, format: string): string|osdate
---@field default_format fun(self: DateTime): string|osdate
---@field relative fun(self: DateTime): string
local DateTime = {}

--- Create new datetime
---@param date string
---@return DateTime
function DateTime:new(date)

  local datetime = {}
  setmetatable(datetime, self)

  self.__index = self

  datetime.date = date
  datetime.year = 0
  datetime.month = 0
  datetime.day = 0
  datetime.hour = 0
  datetime.minute = 0
  datetime.second = 0
  datetime.timestamp = self:parse(date)
  datetime.offset = 0

  return datetime
end

--- Parse date
---@param str string
---@return number Timestamp
function DateTime:parse(str)

  local year, month, day, hour, min, sec = str:match '(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)Z'
  self.year = year
  self.month = month
  self.day = day
  self.hour = hour
  self.minute = min
  self.second = sec
  self.offset = ((60 * 60) * _Neowarrior.config.time_offset)

  local utc_time = os.time {
    year = self.year,
    month = self.month,
    day = self.day,
    hour = self.hour,
    min = self.minute,
    sec = self.second,
    isdst = false, -- Explicitly state that this is not daylight saving time
  }

  local local_time = os.date('*t', utc_time)
  local_time.isdst = os.date('*t').isdst

  self.timestamp = os.time(local_time)
  -- FIX: need a better solution for this
  self.timestamp = self.timestamp + self.offset

  return self.timestamp
end

--- Format date
---@param format string
---@return string|osdate
function DateTime:format(format)
  return os.date(format, self.timestamp)
end

--- Get default formatted date
---@return string|osdate
function DateTime:default_format()
  if self.timestamp == 0 then
    return ''
  end
  return os.date('%Y-%m-%d, %H:%M', self.timestamp)
end

--- Function to calculate the time difference
---@return number
function DateTime:diff()
  local target_time = self:parse(self.date)
  local now = os.time()
  local diff = os.difftime(target_time, now)
  return diff
end

-- Function to calculate the relative time difference
---@return string
function DateTime:relative()

  local diff = self:diff()
  local negative = false

  if diff < 0 then
    negative = true
    diff = diff * -1
  end

  local days = math.floor(diff / (24 * 60 * 60))
  local hours = math.floor((diff % (24 * 60 * 60)) / (60 * 60))
  local minutes = math.floor((diff % (60 * 60)) / 60)

  local value = ''

  if days > 0 or days < -1 then
    if days >= 30 or days <= -30 then
      local months = math.floor(days / 30)
      value = string.format('~%dmon', months)
    else
      value = string.format('%dd', days)
    end
  elseif hours > 0 or hours < -1 then
    value = string.format('%dh', hours)
  elseif minutes > 0 or minutes < 0 then
    value = string.format('%dm', minutes)
  else
    value = 'now'
  end
  if negative then
    value = '-' .. value
  end

  return value
end

--- Get relative hours
--- @return number
function DateTime:relative_hours()

  local diff = self:diff()
  local negative = false

  if diff < 0 then
    negative = true
    diff = diff * -1
  end

  local value = diff / (60 * 60)
  return (not negative) and value or value * -1
end

return DateTime
