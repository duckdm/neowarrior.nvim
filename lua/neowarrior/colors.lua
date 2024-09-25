local Colors = {}

Colors.set = function(config_colors)

  for _, color in pairs(config_colors) do
    if color.fg and color.bg then
      vim.cmd("highlight " .. color.group .. " guifg=" .. color.fg .. " guibg=" .. color.bg)
    elseif color.fg then
      vim.cmd("highlight " .. color.group .. " guifg=" .. color.fg)
    end
  end

end

Colors.get_urgency_color = function(urgency)

  local a = _Neowarrior.config.breakpoints.urgency[1]
  local b = _Neowarrior.config.breakpoints.urgency[2]
  local c = _Neowarrior.config.breakpoints.urgency[3]

  if (not urgency) or ((urgency + 0.0) < tonumber(c[1])) then
    return _Neowarrior.config.colors[a[2]].group
  end
  if (urgency + 0.0) >= tonumber(c[1]) then return _Neowarrior.config.colors[c[2]].group end
  if (urgency + 0.0) >= tonumber(b[1]) then return _Neowarrior.config.colors[b[2]].group end

  return _Neowarrior.config.colors[a[2]].group
end

--- Get estimate color
---@param est number
---@return string
Colors.get_estimate_color = function(est)

  local a = _Neowarrior.config.breakpoints.estimate[1]
  local b = _Neowarrior.config.breakpoints.estimate[2]
  local c = _Neowarrior.config.breakpoints.estimate[3]

  if est then

    if (est + 0.0) >= tonumber(c[1]) then
      return _Neowarrior.config.colors[c[2]].group
    end

    if (est + 0.0) >= tonumber(b[1]) then
      return _Neowarrior.config.colors[b[2]].group
    end

  end

  return _Neowarrior.config.colors[a[2]].group
end

--- Get due color
---@param due string
---@return string
Colors.get_due_color = function(due)

  if (not due) or (not _Neowarrior.config.breakpoints.due) then
    return ""
  end

  for _, d in ipairs(_Neowarrior.config.breakpoints.due) do

    if not d[1] then
      goto continue
    end

    local cmp_period = d[1][2]
    local cmp_value = d[1][1]
    local due_period = string.match(due, cmp_period)
    local due_value = tonumber(string.match(due, "%d+"))

    if due_period == cmp_period and due_value <= cmp_value then
      return _Neowarrior.config.colors[d[2]].group
    end

    ::continue::

  end

  return ""
end

--- Get priority color
---@param priority string|nil
---@return string
Colors.get_priority_color = function(priority)
  if priority == "H" then
    return _Neowarrior.config.colors.danger.group
  end
  if priority == "M" then
    return _Neowarrior.config.colors.warning.group
  end
  if priority == "L" then
    return _Neowarrior.config.colors.success.group
  end
  return ""
end

return Colors
