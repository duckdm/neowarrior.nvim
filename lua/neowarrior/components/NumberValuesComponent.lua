---@class NumberValuesComponent
---@field tram Trambampolin
---@field label string
local NumberValuesComponent = {}

function NumberValuesComponent:new(tram, label)

  local instance = {
    tram = tram,
    label = label,
    label_color = _Neowarrior.config.colors.dim.group,
    no_decimals = 1,
  }
  setmetatable(instance, self)
  self.__index = self

  instance.tram:col(label .. " ", "")

  return instance
end

function NumberValuesComponent:set_label_color(color)
  self.label_color = color
  return self
end

function NumberValuesComponent:add(label, value, color)

  self.tram:col("[ ", self.label_color)
  self.tram:col(label .. ": ", self.label_color)
  self.tram:col(self:round(value), color)
  self.tram:col(" ]", self.label_color)

  return self
end

function NumberValuesComponent:round(value)
  return string.format("%." .. self.no_decimals .. "f", value)
end

function NumberValuesComponent:decimals(decimals)
  self.no_decimals = decimals
  return self
end

return NumberValuesComponent
