local date = require('tieske.date')
local Trambampolin = require("trambampolin.init")
local DateTime = require("neowarrior.DateTime")

---@class DateTimePicker
---@field tram Trambampolin
local DateTimePicker = {}

--- Create a new DateTimePicker
function DateTimePicker:new()
  local date_time_picker = {}
  setmetatable(date_time_picker, self)
  self.__index = self

  date_time_picker.tram = Trambampolin:new()

  return date_time_picker
end

function DateTimePicker:open()

  local current_date = DateTime:new("2024-10-03T14:00:00")
  print(current_date:default_format())
  print(vim.inspect(current_date:diff()))

  -- self.tram:open_float({
  --   width = 30,
  --   height = 10,
  --   relative = "editor",
  --   row = 2,
  --   col = 2,
  --   enter = true,
  -- })

end

function DateTimePicker:print_week(header)
  if header then
    self.tram:line("Mon Tue Wed Thu Fri Sat Sun", {})
  else
    self.tram:line(" 1   2   3   4   5   6   7", {})
  end
end

return DateTimePicker
