local Util = {}

local function deep_copy(orig, max_depth, depth)

  local orig_type = type(orig)
  local copy = nil

  if orig_type and orig_type == 'table' and depth < 3 then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deep_copy(orig_key, max_depth, depth + 1)] = deep_copy(orig_value, max_depth, depth + 1)
    end
    setmetatable(copy, deep_copy(getmetatable(orig), max_depth, depth + 1))
  else
    copy = orig
  end

  return copy
end

Util.copy = function(orig)
  return deep_copy(orig, 5, 0)
end

Util.table_size = function(table)
  local c = 0
  for _ in pairs(table) do
    c = c + 1
  end
  return c
end

Util.extract = function(key, tbl)

  local values = {}
  for _, value in ipairs(tbl) do
    if value[key] then
      local in_table = false
      for _, v in ipairs(values) do
        if v == value[key] then
          in_table = true
        end
      end
      if not in_table then
        table.insert(values, value[key])
      end
    end
  end

  return values
end

Util.table_map = function(table, fn)
  local new_table = {}
  for key, value in pairs(table) do
    new_table[key] = fn(value)
  end
  return new_table
end

--- Check if item exists in table
---@param table table
---@param cmp table { key = any, value = any }
---@return boolean
Util.in_table = function(table, cmp)
  local key = cmp.key or nil
  local value = cmp.value or nil
  for _, t in ipairs(table) do
    if not key then
      if t == value then
        return true
      end
    else
      if t[key] == value then
        return true
      end
    end
  end
  return false
end

--- Split string
---@param inputstr string
---@param sep string
---@return table
Util.split_string = function(inputstr, sep)
  if sep == nil then
    sep = '%s'
  end
  local t = {}
  for str in string.gmatch(inputstr, '([^' .. sep .. ']+)') do
    table.insert(t, str)
  end
  return t
end

Util.print_tree = function(node, indent)
  indent = indent or ''
  for key, child in pairs(node) do
    print(indent .. key)
    Util.print_tree(child, indent .. '  ')
  end
end

return Util
