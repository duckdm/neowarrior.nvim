local Util = {}

Util.table_size = function(table)
  local c = 0
  for _ in pairs(table) do
    c = c + 1
  end
  return c
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

Util.printr = function(data)
  -- cache of tables already printed, to avoid infinite recursive loops
  local tablecache = {}
  local buffer = ''
  local padder = '    '

  local function _dumpvar(d, depth)
    local t = type(d)
    local str = tostring(d)
    if t == 'table' then
      if tablecache[str] then
        -- table already dumped before, so we dont
        -- dump it again, just mention it
        buffer = buffer .. '<' .. str .. '>\n'
      else
        tablecache[str] = (tablecache[str] or 0) + 1
        buffer = buffer .. '(' .. str .. ') {\n'
        for k, v in pairs(d) do
          buffer = buffer .. string.rep(padder, depth + 1) .. '[' .. k .. '] => '
          _dumpvar(v, depth + 1)
        end
        buffer = buffer .. string.rep(padder, depth) .. '}\n'
      end
    elseif t == 'number' then
      buffer = buffer .. '(' .. t .. ') ' .. str .. '\n'
    else
      buffer = buffer .. '(' .. t .. ') "' .. str .. '"\n'
    end
  end
  _dumpvar(data, 0)
  return buffer
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
