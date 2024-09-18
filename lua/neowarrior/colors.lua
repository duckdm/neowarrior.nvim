local Colors = {}

Colors.set = function()
  vim.cmd("highlight NeoWarriorTextDim guifg=#666666")
  vim.cmd("highlight NeoWarriorTextDanger guifg=#cc0000")
  vim.cmd("highlight NeoWarriorTextWarning guifg=#ccaa00")
  vim.cmd("highlight NeoWarriorTextSuccess guifg=#00cc00")
  vim.cmd("highlight NeoWarriorTextInfo guifg=#00aaff")
  vim.cmd("highlight NeoWarriorGroup guifg=#00aaff")
  vim.cmd("highlight NeoWarriorVirt guifg=#00aaff guibg=#000000")
  vim.cmd("highlight NeoWarriorHide guifg=#000000 guibg=#000000")

  vim.cmd("highlight NeoWarriorTextDefaultBg guifg=#ffffff guibg=#333333")
  vim.cmd("highlight NeoWarriorTextInfoBg guifg=#ffffff guibg=#005588")
  vim.cmd("highlight NeoWarriorTextDangerBg guifg=#ffffff guibg=#cc0000")
end

Colors.get_urgency_color = function(urgency)
  if not urgency then
    return "NeoWarriorTextDim"
  end
  if (urgency + 0.0) >= 10 then
    return "NeoWarriorTextDanger"
  end
  if (urgency + 0.0) >= 5 then
    return "NeoWarriorTextWarning"
  end
  return "NeoWarriorTextDim"
end

--- Get estimate color
---@param est number
---@return string
Colors.get_estimate_color = function(est)
  if est then
    if est < 1 then
      return "NeoWarriorTextSuccess"
    elseif est < 8 then
      return "NeoWarriorTextInfo"
    end
  end
  return "NeoWarriorTextWarning"
end

--- Get due color
---@param due string
---@return string
Colors.get_due_color = function(due)
  if string.find(due, "-") then
    return "NeoWarriorTextDangerBg"
  end
  if (string.find(due, "m") and not (string.find(due, "mon"))) or string.find(due, "h") then
    return "NeoWarriorTextDanger"
  elseif string.find(due, "d") then
    local no_days = tonumber(string.match(due, "%d+"))
    if no_days <= 7 then
      return "NeoWarriorTextWarning"
    end
  end
  return "NeoWarriorTextInfo"
end

--- Get priority color
---@param priority string|nil
---@return string
Colors.get_priority_color = function(priority)
  if priority == "H" then
    return "NeoWarriorTextDanger"
  end
  if priority == "M" then
    return "NeoWarriorTextWarning"
  end
  if priority == "L" then
    return "NeoWarriorTextSuccess"
  end
  return ""
end

return Colors
