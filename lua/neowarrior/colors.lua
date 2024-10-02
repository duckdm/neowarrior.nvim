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

Colors.get_geq = function(cmp_value, values, default_value)

  local hl_group = default_value

  for _, val in ipairs(values) do

    if cmp_value >= tonumber(val[1]) then
      hl_group = _Neowarrior.config.colors[val[2]].group
    end

  end

  return hl_group
end

Colors.get_leq = function(cmp_value, values, default_value)

  local hl_group = default_value

  for _, val in ipairs(values) do

    if val[1] == nil then
      hl_group = _Neowarrior.config.colors[val[2]].group
    elseif cmp_value <= tonumber(val[1]) then
      hl_group = _Neowarrior.config.colors[val[2]].group
      break
    end

  end

  return hl_group
end

Colors.get_urgency_color = function(urgency)
  return Colors.get_geq(urgency, _Neowarrior.config.breakpoints.urgency, "")
end

--- Get estimate color
---@param est number
---@return string
Colors.get_estimate_color = function(est)
  if (not est) or (est == 0) then
    return ""
  end
  return Colors.get_geq(est, _Neowarrior.config.breakpoints.estimate, "")
end

--- Get due color
---@param due number Hours
---@return string
Colors.get_due_color = function(due)

  if (not due) or (not _Neowarrior.config.breakpoints.due) then
    return ""
  end

  return Colors.get_leq(due, _Neowarrior.config.breakpoints.due, "")
end

--- Get priority color
---@param priority string|nil
---@return string
Colors.get_priority_color = function(priority)

  local breakpoints = _Neowarrior.config.breakpoints.priority

  if priority == "H" then
    return _Neowarrior.config.colors[breakpoints.H].group
  end
  if priority == "M" then
    return _Neowarrior.config.colors[breakpoints.M].group
  end
  if priority == "L" then
    return _Neowarrior.config.colors[breakpoints.L].group
  end

  return _Neowarrior.config.colors[breakpoints.None].group
end

return Colors
