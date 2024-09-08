---@class DateTime
---@field year number
---@field month number
---@field day number
---@field hour number
---@field minute number
---@field second number
---@field timestamp number
local DateTime = {}

--- Create new datetime
---@param date string
---@return DateTime
function DateTime:new(date)

  local datetime = {}
  setmetatable(datetime, self)

  self.__index = self
  self.year = 0
  self.month = 0
  self.day = 0
  self.hour = 0
  self.minute = 0
  self.second = 0
  self.timestamp = 0

  self.parse(date)

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
  -- FIX: Dirty trick
  self.timestamp = self.timestamp + (60 * 60)

  return self.timestamp
end

--- Format date
---@param format string
---@return string|osdate
function DateTime:format(format)
  return os.date(format, self.timestamp)
end
