local api, fn = vim.api, vim.fn
local strwidth = api.nvim_strwidth
local highlight, ui, falsy, augroup =
  pde.highlight, pde.ui, pde.falsy, pde.augroup
local icons, border, rect = ui.icons.lsp, ui.current.border, ui.border.rectangle

return {
  {
    'lukas-reineke/virt-column.nvim',
    event = 'VimEnter',
    opts = { char = '▕' },
    init = function()
      augroup('VirtCol', {
        event = { 'VimEnter', 'BufEnter', 'WinEnter' },
        command = function(args)
          ui.decorations.set_colorcolumn(
            args.buf,
            function(virtcolumn)
              require('virt-column').setup_buffer({ virtcolumn = virtcolumn })
            end
          )
        end,
      })
    end,
  },
  {
    'lukas-reineke/indent-blankline.nvim',
    event = 'UIEnter',
    opts = {
      char = '│', -- ┆ ┊ 
      show_foldtext = false,
      context_char = '▎',
      char_priority = 12,
      show_current_context = true,
      show_current_context_start = true,
      show_current_context_start_on_current_line = false,
      show_first_indent_level = true,
      -- stylua: ignore
      filetype_exclude = {
        'dbout', 'neo-tree-popup', 'log', 'gitcommit',
        'txt', 'help', 'NvimTree', 'git', 'flutterToolsOutline',
        'undotree', 'markdown', 'norg', 'org', 'orgagenda',
        '', -- for all buffers without a file type
      },
    },
  },
  {
    'stevearc/dressing.nvim',
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require('lazy').load({ plugins = { 'dressing.nvim' } })
        return vim.ui.select(...)
      end
    end,
    opts = {
      input = { enabled = false },
      select = {
        backend = { 'fzf_lua', 'builtin' },
        builtin = {
          border = border,
          min_height = 10,
          win_options = { winblend = 10 },
          mappings = { n = { ['q'] = 'Close' } },
        },
        get_config = function(opts)
          opts.prompt = opts.prompt and opts.prompt:gsub(':', '')
          if opts.kind == 'codeaction' then
            return {
              backend = 'fzf_lua',
              fzf_lua = pde.fzf.cursor_dropdown({
                winopts = { title = opts.prompt },
              }),
            }
          end
          if opts.kind == 'orgmode' then
            return {
              backend = 'nui',
              nui = {
                position = '97%',
                border = { style = rect },
                min_width = vim.o.columns - 2,
              },
            }
          end
          return {
            backend = 'fzf_lua',
            fzf_lua = pde.fzf.dropdown({
              winopts = { title = opts.prompt, height = 0.33, row = 0.5 },
            }),
          }
        end,
        nui = {
          min_height = 10,
          win_options = {
            winhighlight = table.concat({
              'Normal:Italic',
              'FloatBorder:PickerBorder',
              'FloatTitle:Title',
              'CursorLine:Visual',
            }, ','),
          },
        },
      },
    },
  },
  {
    'rcarriga/nvim-notify',
    config = function()
      highlight.plugin('notify', {
        { NotifyERRORBorder = { bg = { from = 'NormalFloat' } } },
        { NotifyWARNBorder = { bg = { from = 'NormalFloat' } } },
        { NotifyINFOBorder = { bg = { from = 'NormalFloat' } } },
        { NotifyDEBUGBorder = { bg = { from = 'NormalFloat' } } },
        { NotifyTRACEBorder = { bg = { from = 'NormalFloat' } } },
        { NotifyERRORBody = { link = 'NormalFloat' } },
        { NotifyWARNBody = { link = 'NormalFloat' } },
        { NotifyINFOBody = { link = 'NormalFloat' } },
        { NotifyDEBUGBody = { link = 'NormalFloat' } },
        { NotifyTRACEBody = { link = 'NormalFloat' } },
      })

      local notify = require('notify')

      notify.setup({
        timeout = 5000,
        stages = 'fade_in_slide_out',
        top_down = false,
        background_colour = 'NormalFloat',
        max_width = function() return math.floor(vim.o.columns * 0.6) end,
        max_height = function() return math.floor(vim.o.lines * 0.8) end,
        on_open = function(win)
          if not api.nvim_win_is_valid(win) then return end
          api.nvim_win_set_config(win, { border = border })
        end,
        render = function(...)
          local notification = select(2, ...)
          local style = falsy(notification.title[1]) and 'minimal' or 'default'
          require('notify.render')[style](...)
        end,
      })
      map(
        'n',
        '<leader>nd',
        function() notify.dismiss({ silent = true, pending = true }) end,
        {
          desc = 'dismiss notifications',
        }
      )
    end,
  },
  {
    'levouh/tint.nvim',
    event = 'UIEnter',
    enabled = true,
    opts = {
      tint = -15,
      highlight_ignore_patterns = {
        'WinSeparator',
        'St.*',
        'Comment',
        'Panel.*',
        'Telescope.*',
        'IndentBlankline.*',
        'Bqf.*',
        'VirtColumn',
        'Headline.*',
        'NeoTree.*',
        'LineNr',
        'NeoTree.*',
        'Telescope.*',
        'VisibleTab',
      },
      window_ignore_function = function(win_id)
        local win, buf =
          vim.wo[win_id], vim.bo[vim.api.nvim_win_get_buf(win_id)]
        if win.diff or not falsy(fn.win_gettype(win_id)) then return true end
        local ignore_bt =
          pde.p_table({ terminal = true, prompt = true, nofile = false })
        local ignore_ft = pde.p_table({
          ['Neogit.*'] = true,
          ['flutterTools.*'] = true,
          ['qf'] = true,
        })
        return ignore_bt[buf.buftype] or ignore_ft[buf.filetype]
      end,
    },
  },
  {
    'kevinhwang91/nvim-ufo',
    event = 'VeryLazy',
    dependencies = { 'kevinhwang91/promise-async' },
    keys = {
      { 'zR', function() require('ufo').openAllFolds() end, 'open all folds' },
      {
        'zM',
        function() require('ufo').closeAllFolds() end,
        'close all folds',
      },
      {
        'zP',
        function() require('ufo').peekFoldedLinesUnderCursor() end,
        'preview fold',
      },
    },
    opts = function()
      local ft_map = { rust = 'lsp' }
      require('ufo').setup({
        open_fold_hl_timeout = 0,
        preview = {
          win_config = { winhighlight = 'Normal:Normal,FloatBorder:Normal' },
        },
        enable_get_fold_virt_text = true,
        close_fold_kinds = { 'imports', 'comment' },
        provider_selector = function(_, ft)
          return ft_map[ft] or { 'treesitter', 'indent' }
        end,
        fold_virt_text_handler = function(
          virt_text,
          _,
          end_lnum,
          width,
          truncate,
          ctx
        )
          local result, cur_width, padding = {}, 0, ''
          local suffix_width = strwidth(ctx.text)
          local target_width = width - suffix_width

          for _, chunk in ipairs(virt_text) do
            local chunk_text = chunk[1]
            local chunk_width = strwidth(chunk_text)
            if target_width > cur_width + chunk_width then
              table.insert(result, chunk)
            else
              chunk_text = truncate(chunk_text, target_width - cur_width)
              local hl_group = chunk[2]
              table.insert(result, { chunk_text, hl_group })
              chunk_width = strwidth(chunk_text)
              if cur_width + chunk_width < target_width then
                padding = padding
                  .. (' '):rep(target_width - cur_width - chunk_width)
              end
              break
            end
            cur_width = cur_width + chunk_width
          end

          if ft_map[vim.bo[ctx.bufnr].ft] == 'lsp' then
            table.insert(result, { ' ⋯ ', 'UfoFoldedEllipsis' })
            return result
          end

          local end_text = ctx.get_fold_virt_text(end_lnum)
          -- reformat the end text to trim excess whitespace from
          -- indentation usually the first item is indentation
          if end_text[1] and end_text[1][1] then
            end_text[1][1] = end_text[1][1]:gsub('[%s\t]+', '')
          end

          vim.list_extend(
            result,
            { { ' ⋯ ', 'UfoFoldedEllipsis' }, unpack(end_text) }
          )
          table.insert(result, { padding, '' })
          return result
        end,
      })
    end,
  },
  {
    'akinsho/bufferline.nvim',
    dev = true,
    event = 'UIEnter',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local bufferline = require('bufferline')
      bufferline.setup({
        options = {
          debug = { logging = true },
          style_preset = { bufferline.style_preset.minimal },
          mode = 'buffers',
          sort_by = 'insert_after_current',
          right_mouse_command = 'vert sbuffer %d',
          show_close_icon = false,
          show_buffer_close_icons = true,
          indicator = { style = 'underline' },
          diagnostics = 'nvim_lsp',
          diagnostics_indicator = function(count, level)
            level = level:match('warn') and 'warn' or level
            return (icons[level] or '?') .. ' ' .. count
          end,
          diagnostics_update_in_insert = false,
          hover = { enabled = true, reveal = { 'close' } },
          offsets = {
            {
              text = 'EXPLORER',
              filetype = 'neo-tree',
              highlight = 'PanelHeading',
              text_align = 'left',
              separator = true,
            },
            {
              text = 'UNDOTREE',
              filetype = 'undotree',
              highlight = 'PanelHeading',
              separator = true,
            },
            {
              text = ' DIFF VIEW',
              filetype = 'DiffviewFiles',
              highlight = 'PanelHeading',
              separator = true,
            },
          },
          groups = {
            options = { toggle_hidden_on_enter = true },
            items = {
              bufferline.groups.builtin.pinned:with({ icon = '' }),
              bufferline.groups.builtin.ungrouped,
              {
                name = 'Dependencies',
                icon = '',
                highlight = { fg = '#ECBE7B' },
                matcher = function(buf)
                  return vim.startswith(buf.path, vim.env.VIMRUNTIME)
                end,
              },
              {
                name = 'Terraform',
                matcher = function(buf) return buf.name:match('%.tf') ~= nil end,
              },
              {
                name = 'Kubernetes',
                matcher = function(buf)
                  return buf.name:match('kubernetes')
                    and buf.name:match('%.yaml')
                end,
              },
              {
                name = 'SQL',
                matcher = function(buf) return buf.name:match('%.sql$') end,
              },
              {
                name = 'tests',
                icon = '',
                matcher = function(buf)
                  local name = buf.name
                  return name:match('[_%.]spec') or name:match('[_%.]test')
                end,
              },
              {
                name = 'docs',
                icon = '',
                matcher = function(buf)
                  if
                    vim.bo[buf.id].filetype == 'man' or buf.path:match('man://')
                  then
                    return true
                  end
                  for _, ext in ipairs({ 'md', 'txt', 'org', 'norg', 'wiki' }) do
                    if ext == fn.fnamemodify(buf.path, ':e') then
                      return true
                    end
                  end
                end,
              },
            },
          },
        },
      })

      map(
        'n',
        '[b',
        '<Cmd>BufferLineMoveNext<CR>',
        { desc = 'bufferline: move next' }
      )
      map(
        'n',
        ']b',
        '<Cmd>BufferLineMovePrev<CR>',
        { desc = 'bufferline: move prev' }
      )
      map(
        'n',
        'gbb',
        '<Cmd>BufferLinePick<CR>',
        { desc = 'bufferline: pick buffer' }
      )
      map(
        'n',
        'gbd',
        '<Cmd>BufferLinePickClose<CR>',
        { desc = 'bufferline: delete buffer' }
      )
      map(
        'n',
        '<S-tab>',
        '<Cmd>BufferLineCyclePrev<CR>',
        { desc = 'bufferline: prev' }
      )
      map(
        'n',
        '<leader><tab>',
        '<Cmd>BufferLineCycleNext<CR>',
        { desc = 'bufferline: next' }
      )
    end,
  },
}
