local Trambampolin = require("trambampolin.init")
local DateTime = require("neowarrior.DateTime")

---@class DateTimePicker
---@field tram Trambampolin
---@field float Float
---@field select_date boolean
---@field select_time boolean
---@field on_select_callback nil|function
---@field mark table
---@field title string
---@field row number
---@field col number
---@field on_select fun(self: DateTimePicker, callback: function): self
---@field open fun(self: DateTimePicker, date: string?): self
---@field close fun(self: DateTimePicker, ): self
---@field print_week fun(self: DateTimePicker, header: boolean, from: DateTime|nil, view: DateTime, current: DateTime): self
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
  date_time_picker.mark = opts and opts.mark or {}
  date_time_picker.title = opts and opts.title or nil
  date_time_picker.row = opts and opts.row or 0
  date_time_picker.col = opts and opts.col or 0

  return date_time_picker
end

--- Set on_select callback
---@param callback function
function DateTimePicker:on_select(callback)
  self.on_select_callback = callback
  return self
end

--- Open the DateTimePicker
---@param date? string
---@return self
function DateTimePicker:open(date)

  date = date or nil
  local month_pad = "         "
  local colors = _Neowarrior.config.colors
  local current_date = DateTime:new()
  local view = DateTime:new(date)
  local last_month = view:copy():add("months", -1)
  local next_month = view:copy():add("months", 1)
  local month_start = view:copy():set({
    day = 1,
    hour = 0,
    minute = 0,
    second = 0,
  })
  local first_weekday = month_start:weekday()
  local first_view_day = month_start:add("days", -(first_weekday - 2))

  local last_month_name = last_month:format("%b")
  local view_month_name = view:format("%b")
  local next_month_name = next_month:format("%b")

  self.tram:clear()
  self.tram:col(" " .. last_month_name, colors.dim.group)
  self.tram:col(month_pad .. view_month_name .. month_pad, colors.info.group)
  self.tram:col(next_month_name, colors.dim.group)
  self.tram:into_line({})

  for i = 1, 6 do
    if i == 1 then
      self:print_week(true, nil, nil, nil)
    else
      self:print_week(false, first_view_day, view, current_date)
    end
  end

  if not self.float then
    self.float = self.tram:open_float({
      title = self.title,
      width = 30,
      height = 7,
      relative = "cursor",
      row = self.row,
      col = self.col,
      enter = true,
    })
  else
    self.tram:print()
  end

  self.tram:get_buffer():keymap("n", "q", ":q<CR>", { silent = true })

  self.tram:get_buffer():keymap("n", "<CR>", function()

    local meta_data = self.tram:get_line_meta_data("dates")
    local word = vim.fn.expand("<cword>")

    if word == last_month_name or word == next_month_name then

      self.tram.buffer:save_cursor()

      if word == last_month_name then
        self:open(last_month:default_format())
      else
        self:open(next_month:default_format())
      end

      self.tram.buffer:restore_cursor()

    else

      local date_result = nil

      if meta_data and meta_data[word] then
        date_result = DateTime:new(meta_data[word])
      end

      if date_result and self.select_time then
        vim.ui.input({
          prompt = "Time: ",
          cancelreturn = nil,
        }, function(input)

          if input and input:find(":") == nil then
            input = input:sub(0,2) .. ":00"
          end

          if input then

            local time_parts = vim.split(input, ":")
            local hour = tonumber(time_parts[1] or 0)
            local minute = tonumber(time_parts[2] or 0)
            local second = tonumber(time_parts[3] or 0)

            date_result:set({
              hour = hour,
              minute = minute,
              second = second,
            })

          end

        end)
      end

      if type(self.on_select_callback) == "function" then
        self.on_select_callback(date_result, self)
      end
    end

  end, { silent = true })

  return self
end

function DateTimePicker:close()
  self.tram:close_float(self.float)
  self.float = nil
end

function DateTimePicker:print_week(header, from, view, current)

  local colors = _Neowarrior.config.colors

  if header then
    self.tram:line(" Mon Tue Wed Thu Fri Sat Sun", {})
  else
    local dates = {}
    for _ = 1, 7 do

      local color = ""

      if from.date:getmonth() ~= view.date:getmonth() then
        color = colors.dim.group
      elseif from:format("%Y%m%d") == current:format("%Y%m%d") then
        color = colors.current_date.group
      end

      for _, mark in ipairs(self.mark) do
        if (mark and mark.date) and from:format("%Y%m%d") == mark.date:format("%Y%m%d") then
          color = mark.color or colors.marked_date.group
        end
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
