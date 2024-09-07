local Time = {}
local os_time = os.time
local os_date = os.date

-- Helper function to parse dates in the format YYYYMMDDTHHMMSSZ
Time.parse = function(str)
  local year, month, day, hour, min, sec = str:match '(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)Z'
  return os_time { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end

Time.format = function(str)
  local year, month, day, hour, min, sec = str:match '(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)Z'
  local utc_time = os.time {
    year = year,
    month = month,
    day = day,
    hour = hour,
    min = min,
    sec = sec,
    isdst = false, -- Explicitly state that this is not daylight saving time
  }

  -- Get the local time offset by comparing the UTC time and local time
  local local_time = os.date('*t', utc_time)
  local_time.isdst = os.date('*t').isdst -- Adjust for daylight saving if necessary

  -- Convert the adjusted local time back to a timestamp
  local timestamp = os.time(local_time)
  -- FIX: Dirty trick
  timestamp = timestamp + (60 * 60)

  -- timestamp = timestamp + (2 * 60 * 60)
  return os.date('%Y-%m-%d, %H:%M', timestamp)
end

-- Function to calculate the relative time difference
Time.relative = function(date)
  local target_time = Time.parse(date)
  target_time = target_time + (2 * 60 * 60)
  local now = os_time()
  local diff = os.difftime(target_time, now)
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

return Time
