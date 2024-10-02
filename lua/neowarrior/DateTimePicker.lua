local Trambampolin = require("trambampolin.init")
local DateTime = require("neowarrior.DateTime")

---@class DateTimePicker
---@field tram Trambampolin
---@field float number
---@field select_date boolean
---@field select_time boolean
---@field on_select_callback nil|function
---@field on_select fun(self: DateTimePicker, callback: function): self
---@field open fun(self: DateTimePicker, ): self
---@field close fun(self: DateTimePicker, ): self
---@field print_week fun(self: DateTimePicker, header: boolean, from: DateTime|nil): self
---@field new fun(self: DateTimePicker, opts: table|nil): DateTimePicker
local DateTimePicker = {}

--- Create a new DateTimePicker
---@param opts? table|nil
function DateTimePicker:new(opts)
  local date_time_picker = {}
  setmetatable(date_time_picker, self)
  self.__index = self

  date_time_picker.float = nil
  date_time_picker.tram = Trambampolin:new()
  date_time_picker.on_select_callback = opts and opts.on_select or nil
  date_time_picker.select_date = opts and opts.select_date or true
  date_time_picker.select_time = opts and opts.select_time or false

  return date_time_picker
end

--- Set on_select callback
---@param callback function
function DateTimePicker:on_select(callback)
  self.on_select_callback = callback
  return self
end

function DateTimePicker:open()

  local month_pad = "         "
  local colors = _Neowarrior.config.colors
  local current_date = DateTime:new()
  local last_month = current_date:copy():add("months", -1)
  local next_month = current_date:copy():add("months", 1)
  local month_start = DateTime:new():set({
    day = 1,
    hour = 0,
    minute = 0,
    second = 0,
  })
  local first_weekday = month_start:weekday()
  local first_view_day = month_start:add("days", -(first_weekday - 2))

  self.tram:col(" " .. last_month:format("%b"), colors.dim.group)
  self.tram:col(month_pad .. current_date:format("%b") .. month_pad, colors.info.group)
  self.tram:col(next_month:format("%b"), colors.dim.group)
  self.tram:into_line({})

  for i = 1, 6 do
    if i == 1 then
      self:print_week(true, nil)
    else
      self:print_week(false, first_view_day)
    end
  end

  self.float = self.tram:open_float({
    width = 30,
    height = 7,
    relative = "editor",
    row = 2,
    col = 2,
    enter = true,
  })

  self.tram:get_buffer():keymap("n", "<CR>", function()
    local meta_data = self.tram:get_line_meta_data("dates")
    local word = vim.fn.expand("<cword>")
    local result = nil

    if meta_data and meta_data[word] then
      result = DateTime:new(meta_data[word])
    end

    if self.select_time then
      vim.ui.input({
        prompt = "Time: ",
        cancelreturn = nil,
      }, function(input)

        if input:find(":") == nil then
          input = input:sub(0,2) .. ":00"
        end

        local time_parts = vim.split(input, ":")
        local hour = tonumber(time_parts[1] or 0)
        local minute = tonumber(time_parts[2] or 0)
        local second = tonumber(time_parts[3] or 0)

        if result then
          result:set({
            hour = hour,
            minute = minute,
            second = second,
          })
        end

      end)

    end

    if self.on_select_callback then
      self.on_select_callback(result, self)
    end

  end, { silent = true })

  return self
end

function DateTimePicker:close()
  self.tram:close_float(self.float)
  self.float = nil
end

function DateTimePicker:print_week(header, from)

  local colors = _Neowarrior.config.colors

  if header then
    self.tram:line(" Mon Tue Wed Thu Fri Sat Sun", {})
  else
    local dates = {}
    for _ = 1, 7 do
      local color = ""
      if from.date:getmonth() ~= DateTime:new().date:getmonth() then
        color = colors.dim.group
      elseif from.date:getday() == DateTime:new().date:getday() then
        color = colors.info.group
      end
      local date_string = from:format("%d")
      dates[date_string] = from:default_format()
      self.tram:col(" " .. date_string .. " ", color)
      from:add("days", 1)
    end
    self.tram:into_line({
      meta = {
        dates = dates
      }
    })
  end
end

return DateTimePicker
