local Util = require('neowarrior.util')
local Buffer = {}

Buffer.lock = function(buf)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

Buffer.unlock = function(buf)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
end

Buffer.option = function(buf, key, value)
  vim.api.nvim_buf_set_option(buf, key, value)
end

Buffer.get_cursor = function()
  local win = vim.api.nvim_get_current_win()
  return vim.api.nvim_win_get_cursor(win)
end

Buffer.cursor = nil

Buffer.save_cursor = function()
  local cursor = Buffer.get_cursor()
  Buffer.cursor = cursor

  return cursor
end

Buffer.float = function (lines, opts)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
    Buffer.option(buf, "wrap", true)
    opts = vim.tbl_deep_extend('force', {
      relative = 'cursor',
      width = 30,
      height = Util.table_size(lines),
      col = 0,
      row = 1,
      anchor = 'NW',
      style = 'minimal'
    }, opts)
    local win = vim.api.nvim_open_win(buf, false, opts)
    vim.api.nvim_win_set_option(win, 'wrap', true)
    vim.api.nvim_win_set_option(win, 'linebreak', true)
    return win
end

--- Set buffer virt text
---@param text string
---@param hl_group string
---@param bnr number
---@param ns_name string
---@param o table Extend options
---@return number
Buffer.virt_text = function(text, hl_group, bnr, ns_name, o)

  local line_no = o.line_no or Buffer.get_cursor()[1]
  if o.line_no then
    o.line_no = nil
  end
  local col_num = o.col_num or 0
  local api = vim.api
  local ns_id = api.nvim_create_namespace(ns_name)
  local opts = vim.tbl_deep_extend('force', {
    end_line = line_no + 1,
    id = 1,
    virt_text_pos = 'overlay',
    virt_text = { { text, hl_group } },
  }, o)

  return api.nvim_buf_set_extmark(bnr, ns_id, line_no, col_num, opts)
end

Buffer.restore_cursor = function()
  local cursor = Buffer.cursor
  if not cursor then
    return nil
  end
  local win = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  local target_line = cursor[1]
  if target_line >= total_lines then
    vim.api.nvim_win_set_cursor(win, { total_lines, 0 })
  else
    vim.api.nvim_win_set_cursor(win, cursor)
  end
  Buffer.cursor = nil
end

--- Create line
---@param ln number Current line count
---@param blocks table
---@return table { string, table }
Buffer.create_line = function(ln, blocks)
  local b = 0
  local bf = 0
  local str = ""
  local meta_str = ""
  local colors = {}

  for _, block in ipairs(blocks) do
    if not block.disable then
      if block.text then
        if block.seperator then
          str = str .. block.seperator .. block.text
        else
          str = str .. block.text
        end
      end

      if block.meta then
        meta_str = meta_str .. " "
        for key, value in pairs(block.meta) do
          meta_str = meta_str .. "{{{" .. key .. value .. "}}}"
        end
      end

      if b > 0 then
        bf = b - 1
      else
        bf = 0
      end
      b = string.len(str)

      if block.color then
        table.insert(colors, {
          group = block.color,
          from = bf,
          to = b,
          line = ln,
        })
      end
    end
  end

  return { str .. meta_str, colors }
end

Buffer.apply_colors = function(colors, cta)
  for _, c in ipairs(cta) do
    table.insert(colors, c)
  end
end

return Buffer
