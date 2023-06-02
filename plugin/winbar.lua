if not pde or not pde.ui.winbar.enable then return end
local navic_loaded, navic = pcall(require, 'nvim-navic')

local str = require('pde.strings')
local section, spacer, display = str.section, str.spacer, str.display

local fn, api, falsy, lsp_hl = vim.fn, vim.api, pde.falsy, pde.ui.lsp.highlights
local icons, decorations, highlight =
  pde.ui.icons.misc, pde.ui.decorations, pde.highlight
local space, dir_separator, separator, ellipsis =
  ' ', '/', icons.arrow_right, icons.ellipsis

--- A mapping of each winbar items ID to its path
---@type table<integer, (string|{start: {line: integer, character: integer}})>
local state = {}

local hls = {
  separator = 'WinbarDirectory',
  inactive = 'NonText',
  normal = 'Winbar',
  crumb = 'WinbarCrumb',
}

highlight.plugin('winbar', {
  { [hls.normal] = { bold = false } },
  { [hls.crumb] = { bold = true } },
  { [hls.separator] = { inherit = 'Directory' } },
})

---@param id number
function pde.ui.winbar.click(id)
  if not id then return end
  local item = state[id]
  if type(item) == 'string' then vim.cmd.edit(item) end
  if type(item) == 'table' and item.start then
    api.nvim_win_set_cursor(
      fn.getmousepos().winid,
      { item.start.line, item.start.character }
    )
  end
end

local function breadcrumbs()
  local empty_state = {
    { { separator, hls.separator }, { space }, { ellipsis, hls.inactive } },
    priority = 0,
  }
  if not navic_loaded or not navic.is_available() then
    return { empty_state }
  end
  local ok, data = pcall(navic.get_data)
  if not ok or falsy(data) then return { empty_state } end
  return pde.map(function(crumb, index)
    local priority = #state + #data - index
    state[priority] = crumb.scope
    return {
      {
        { separator, hls.separator },
        { space },
        { crumb.icon, lsp_hl[crumb.type] or hls.inactive },
        { space },
        { crumb.name, hls.crumb, max_size = 35 },
      },
      priority = priority,
      id = priority,
      click = 'v:lua.pde.ui.winbar.click',
    }
  end, data)
end

---@param current_win integer
---@return string
function pde.ui.winbar.render(current_win)
  state = {}

  local w1 = section:new(spacer(1))

  local bufname = api.nvim_buf_get_name(api.nvim_get_current_buf())
  if falsy(bufname) then
    return w1 + section:new({ { { '[No name]', hls.normal } }, priority = 0 })
  end

  local parts = vim.split(fn.fnamemodify(bufname, ':.'), '/')

  local wn = pde.map(function(part, index)
    local priority = (#parts - (index - 1)) * 2
    local is_last = index == #parts
    local hl = is_last and hls.normal or hls.inactive
    state[priority] = table.concat(vim.list_slice(parts, 1, index), '/')
    return {
      {
        { part, hl },
        not is_last and { ' ' .. dir_separator, hls.inactive } or nil,
      },
      id = priority,
      priority = priority,
      click = 'v:lua.pde.ui.winbar.click',
    }
  end, parts)
  local win = api.nvim_get_current_win()
  local winbar = w1 + section:new(unpack(wn))
  if win == current_win then
    winbar = section:new(unpack(winbar)) + section:new(unpack(breadcrumbs()))
  end
  return display({ winbar }, api.nvim_win_get_width(win))
end

--- The reason for this wrapper function that decides whether to set the winbar
--- is that the winbar cannot be cleared by returning a null or empty value
--- so the extra line taken by the winbar will be set even in windows where this is not desirable
--- see: https://github.com/neovim/neovim/issues/18660
local function set_winbar()
  local current_win = api.nvim_get_current_win()
  pde.foreach(function(w)
    local buf, win = vim.bo[api.nvim_win_get_buf(w)], vim.wo[w]

    if vim.t[0].diff_view_initialized then return end

    local bt, ft, is_diff = buf.buftype, buf.filetype, win.diff
    local decor = decorations.get({ ft = ft, bt = bt, setting = 'winbar' })
    if decor.ft == 'ignore' or decor.bt == 'ignore' then return end

    local normal_win = falsy(fn.win_gettype(api.nvim_win_get_number(w)))

    if
      normal_win
      and not decor.ft
      and bt == ''
      and ft ~= ''
      and not is_diff
    then
      win.winbar = ('%%{%%v:lua.pde.ui.winbar.render(%d)%%}'):format(
        current_win
      )
    elseif is_diff then
      win.winbar = nil
    end
  end, api.nvim_tabpage_list_wins(0))
end

pde.augroup('AttachWinbar', {
  event = { 'TabEnter', 'BufEnter', 'WinClosed' },
  desc = 'Toggle winbar',
  command = set_winbar,
})
