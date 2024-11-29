---@class Input
---@field prompt string
local Input = {}

function Input:new(prompt)
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o.prompt = prompt
  return o
end

function Input:text(default, callback)
  vim.ui.input({
    prompt = self.prompt,
    default = default,
    cancelreturn = nil,
  }, function(input)
    callback(input)
  end)
end

function Input:select(items, callback, opts)

  if _Neowarrior.config.ui.select == "telescope" and _Neowarrior.telescope then
    self:_telescope_picker(self.prompt, items, callback, opts)
  else
    self:_vim_picker(self.prompt, items, callback, opts)
  end
end

function Input:_telescope_picker(prompt, items, callback, opts)
  local pickers = nil
  local finders = nil
  local conf = nil
  local actions = nil
  local action_state = nil
  local entry_maker = opts and opts.telescope_entry_maker or nil

  if _Neowarrior.telescope then

    pickers = _Neowarrior.telescope.pickers
    finders = _Neowarrior.telescope.finders
    conf = _Neowarrior.telescope.conf
    actions = _Neowarrior.telescope.actions
    action_state = _Neowarrior.telescope.action_state

    local telescope_opts = require("telescope.themes").get_dropdown({})
    local telescope_setup = {
      prompt_title = prompt,
      finder = finders.new_table({
        results = items,
        entry_maker = entry_maker,
      }),
      sorter = conf.generic_sorter(telescope_opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local p = action_state.get_current_picker(prompt_bufnr):_get_prompt()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          callback(selection, p)
        end)
        return true
      end,
    }
    pickers.new(telescope_opts, telescope_setup):find()
  end

  return nil
end

function Input:_vim_picker(prompt, items, callback, opts)
  local entry_maker = opts and opts.entry_maker or nil
  local i = {}

  if entry_maker then
    for _, item in ipairs(items) do
      table.insert(i, entry_maker(item))
    end
  else
    i = items
  end

  vim.ui.select(i, {
    prompt = prompt,
  }, function(selection)
    callback(selection)
  end)
end

return Input
