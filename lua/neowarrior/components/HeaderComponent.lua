---@class HeaderComponent
local HeaderComponent = {}

--- Create a new HeaderComponent
---@return HeaderComponent
function HeaderComponent:new(tram)
    local header_component = {}
    setmetatable(header_component, self)
    self.__index = self

    self.tram = tram
    self.meta_enabled = true
    self.report_enabled = true
    self.filter_enabled = true
    self.help_items = {
      help = true,
      add = true,
      done = true,
      modify = false,
      filter = true,
    }

    return self
end

function HeaderComponent:set_help_item(key, value)
  self.help_items[key] = value
  return self
end

function HeaderComponent:disable_meta()
  self.meta_enabled = false
  return self
end

function HeaderComponent:disable_report()
  self.report_enabled = false
  return self
end

function HeaderComponent:disable_filter()
  self.filter_enabled = false
  return self
end

--- Print header
function HeaderComponent:set()

  local nw = _Neowarrior
  local keys = nw.config.keys

  if nw.config.header.text then

    local dev = _Neowarrior.config.dev or false
    local header_text_color = _Neowarrior.config.colors.neowarrior.group
    local header_text_has_version = string.match(nw.config.header.text, "{version}")

    if header_text_has_version then

      if string.match(nw.version, "dev") then
        header_text_color = _Neowarrior.config.colors.danger.group
      elseif string.match(nw.version, "pre") or string.match(nw.version, "alpha") or string.match(nw.version, "beta") then
        header_text_color = _Neowarrior.config.colors.warning.group
      end

    end

    local header_text = nw.config.header.text:gsub("{version}", nw.version)

    if dev then
      self.tram:col(" LOCAL DEV ", _Neowarrior.config.colors.danger_bg.group)
    end

    self.tram:col(" " .. header_text .. " ", header_text_color)
    self.tram:into_line({})

  end

  if nw.config.header.enable_help_line then

    if self.help_items.help then
      self.tram:col("(" .. keys.help .. ")help | ", "")
    end
    if self.help_items.add then
      self.tram:col("(" .. keys.add .. ")add | ", "")
    end
    if self.help_items.done then
      self.tram:col("(" .. keys.done .. ")done | ", "")
    end
    if self.help_items.modify then
      self.tram:col("(" .. keys.modify .. ")modify | ", "")
    end
    if self.help_items.filter then
      self.tram:col("(" .. keys.filter .. ")filter | ", "")
    end

    if self.meta_enabled then
      self.tram:into_line({
        meta = { action = 'help' }
      })
    else
      self.tram:into_line({})
    end

  end

  if nw.config.header.enable_current_report and self.report_enabled then

    self.tram:col("(" .. keys.select_report .. ")report: ", "")
    self.tram:col("Report: " .. nw.current_report, _Neowarrior.config.colors.info.group)

    if nw.config.header.enable_current_view then
      if nw.current_mode == 'grouped' then
        self.tram:col(" (Grouped by project)", "")
      elseif nw.current_mode == 'tree' then
        self.tram:col(" (Tree view)", "")
      end
    end

    if not self.disable_meta then
      self.tram:into_line({
        meta = { action = 'report' }
      })
    else
      self.tram:into_line({})
    end

  end

  if nw.config.header.enable_current_filter and self.filter_enabled then

    self.tram:col("(" .. keys.select_filter .. ")filter: ", "")
    self.tram:col(nw.current_filter, _Neowarrior.config.colors.warning.group)
    if not self.disable_meta then
      self.tram:into_line({
        meta = { action = 'filter' }
      })
    else
      self.tram:into_line({})
    end

  end

  self.tram:nl()

  return self
end

return HeaderComponent
