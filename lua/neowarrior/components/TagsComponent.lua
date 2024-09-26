local util = require("neowarrior.util")

---@class TagsComponent
local TagsComponent = {}

--- Create a new TagsComponent
---@return TagsComponent
function TagsComponent:new(tram, tags)
    local tags_component = {}
    setmetatable(tags_component, self)
    self.__index = self

    self.tram = tram
    self.tags = tags

    return self
end

function TagsComponent:line()

  if self.tags then

    self:cols()
    self.tram:into_line({})

  end

  return self
end

function TagsComponent:cols()

  local no_items = util.table_size(self.tags)
  local last = false
  local c = 0
  local tag_colors = _Neowarrior.config.tag_colors
  local colors = _Neowarrior.config.colors
  local pad_start = _Neowarrior.config.tag_padding_start or ""
  local pad_end = _Neowarrior.config.tag_padding_end or ""

  for _, tag in ipairs(self.tags) do

    last = c == no_items - 1
    local hl_group = ""
    local seperator = " "
    if last then seperator = "" end

    if tag_colors then
      for key, value in pairs(tag_colors) do

        if type(value) == 'table' and value.match and tag:find(value.match) then
          hl_group = colors[value.color] and colors[value.color].group or ""
        elseif tag == key then
          hl_group = colors[value] and colors[value].group or ""
        end

      end
    end

    self.tram:col(pad_start .. tag .. pad_end, hl_group)
    if seperator then
      self.tram:col(seperator, "")
    end
    c = c + 1
  end

  return self
end

return TagsComponent
