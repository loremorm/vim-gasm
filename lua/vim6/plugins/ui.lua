local r, api, fn = vim.regex, vim.api, vim.fn
local strwidth = api.nvim_strwidth
local highlight, ui = vim6.highlight, vim6.ui
local icons = ui.icons.lsp

return {
  {
    "marromlam/sailor.vim",
    event = "VimEnter",
    run = "./install.sh",
  },
  {
    "lukas-reineke/virt-column.nvim",
    event = "VimEnter",
    opts = { char = "▕" },
    init = function()
      highlight.plugin("virt_column", { { VirtColumn = { fg = { from = "Comment", alter = 10 } } } })
      vim6.augroup("VirtCol", {
        event = { "BufEnter", "WinEnter" },
        command = function(args)
          ui.decorations.set_colorcolumn(
            args.buf,
            function(virtcolumn) require("virt-column").setup_buffer({ virtcolumn = virtcolumn }) end
          )
        end,
      })
    end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    lazy = false,
    init = function()
      highlight.plugin("indentline", {
        theme = {
          horizon = {
            { IndentBlanklineContextChar = { fg = { from = "Directory" } } },
            { IndentBlanklineContextStart = { sp = { from = "Directory", attr = "fg" } } },
          },
        },
      })
    end,
    opts = {
      char = "│", -- ┆ ┊ 
      show_foldtext = false,
      context_char = "▎",
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
    "stevearc/dressing.nvim",
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
    end,
    opts = {
      input = { enabled = false },
      select = {
        telescope = vim6.telescope.adaptive_dropdown(),
        get_config = function(opts)
          if opts.kind == "codeaction" then return { backend = "telescope", telescope = vim6.telescope.cursor() } end
        end,
      },
    },
  },
  {
    "rcarriga/nvim-notify",
    init = function()
      highlight.plugin("notify", {
        { NotifyERRORBorder = { bg = { from = "NormalFloat" } } },
        { NotifyWARNBorder = { bg = { from = "NormalFloat" } } },
        { NotifyINFOBorder = { bg = { from = "NormalFloat" } } },
        { NotifyDEBUGBorder = { bg = { from = "NormalFloat" } } },
        { NotifyTRACEBorder = { bg = { from = "NormalFloat" } } },
        { NotifyERRORBody = { link = "NormalFloat" } },
        { NotifyWARNBody = { link = "NormalFloat" } },
        { NotifyINFOBody = { link = "NormalFloat" } },
        { NotifyDEBUGBody = { link = "NormalFloat" } },
        { NotifyTRACEBody = { link = "NormalFloat" } },
      })

      local notify = require("notify")

      notify.setup({
        timeout = 3000,
        stages = "fade_in_slide_out",
        top_down = false,
        background_colour = "NormalFloat",
        max_width = function() return math.floor(vim.o.columns * 0.6) end,
        max_height = function() return math.floor(vim.o.lines * 0.8) end,
        on_open = function(win)
          if api.nvim_win_is_valid(win) then api.nvim_win_set_config(win, { border = vim6.ui.current.border }) end
        end,
        render = function(...)
          local notif = select(2, ...)
          local style = notif.title[1] == "" and "minimal" or "default"
          require("notify.render")[style](...)
        end,
      })
      -- this is actually take over by Noice
      vim.notify = notify
      map(
        "n",
        "<leader>nd",
        function() notify.dismiss({ silent = true, pending = true }) end,
        { desc = "dismiss notifications" }
      )
    end,
  },
  {
    "levouh/tint.nvim",
    event = "WinNew",
    branch = "untint-forcibly-closed-windows",
    opts = {
      tint = -30,
      -- stylua: ignore
      highlight_ignore_patterns = {
        'WinSeparator', 'St.*', 'Comment', 'Panel.*', 'Telescope.*',
        'Bqf.*', 'VirtColumn', 'Headline.*', 'NeoTree.*',
      },
      window_ignore_function = function(win_id)
        local win, buf = vim.wo[win_id], vim.bo[vim.api.nvim_win_get_buf(win_id)]
        -- TODO: ideally tint should just ignore all buffers with a special type other than maybe "acwrite"
        -- since if there is a custom buftype it's probably a special buffer we always want to pay
        -- attention to whilst its open.
        -- BUG: neo-tree cannot be ignore as either nofile or by filetype as this causes tinting bugs
        if win.diff or not vim6.empty(fn.win_gettype(win_id)) then return true end
        local ignore_bt = vim6.p_table({ terminal = true, prompt = true, nofile = false })
        local ignore_ft = vim6.p_table({ ["Telescope.*"] = true, ["Neogit.*"] = true, ["qf"] = true })
        local has_bt, has_ft = ignore_bt[buf.buftype], ignore_ft[buf.filetype]
        return has_bt or has_ft
      end,
    },
  },
  {
    "kevinhwang91/nvim-ufo",
    event = "VeryLazy",
    dependencies = { "kevinhwang91/promise-async" },
    keys = {
      { "zR", function() require("ufo").openAllFolds() end, "open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, "close all folds" },
      { "zP", function() require("ufo").peekFoldedLinesUnderCursor() end, "preview fold" },
    },
    opts = {
      open_fold_hl_timeout = 0,
      preview = { win_config = { winhighlight = "Normal:Normal,FloatBorder:Normal" } },
      enable_get_fold_virt_text = true,
      fold_virt_text_handler = function(virt_text, _, end_lnum, width, truncate, ctx)
        local result = {}
        local padding = ""
        local cur_width = 0
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
              padding = padding .. (" "):rep(target_width - cur_width - chunk_width)
            end
            break
          end
          cur_width = cur_width + chunk_width
        end

        local end_text = ctx.get_fold_virt_text(end_lnum)
        -- reformat the end text to trim excess whitespace from
        -- indentation usually the first item is indentation
        if end_text[1] and end_text[1][1] then end_text[1][1] = end_text[1][1]:gsub("[%s\t]+", "") end

        table.insert(result, { " ⋯ ", "UfoFoldedEllipsis" })
        vim.list_extend(result, end_text)
        table.insert(result, { padding, "" })

        return result
      end,
      provider_selector = function() return { "treesitter", "indent" } end,
    },
  },
  {
    "akinsho/bufferline.nvim",
    dev = true,
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local groups = require("bufferline.groups")
      require("bufferline").setup({
        highlights = function(defaults)
          local visible_tab = { highlight = "VisibleTab", attribute = "bg" }

          local data, err = vim6.highlight.get("Normal")
          if vim6.empty(data) or err then return defaults.highlights end

          local normal_bg, normal_fg = data.background, data.foreground
          local visible = vim6.highlight.alter_color(normal_fg, -40)
          local diagnostic = r([[\(error_selected\|warning_selected\|info_selected\|hint_selected\)]])

          local hl = vim6.fold(function(accum, attrs, name)
            local formatted = name:lower()
            local is_group = formatted:match("group")
            local is_offset = formatted:match("offset")
            local is_separator = formatted:match("separator")
            if diagnostic and diagnostic:match_str(formatted) then attrs.fg = normal_fg end
            if not is_group or (is_group and is_separator) then attrs.bg = normal_bg end
            if not is_group and not is_offset and is_separator then attrs.fg = normal_bg end
            accum[name] = attrs
            return accum
          end, defaults.highlights)

          -- Make the visible buffers and selected tab more "visible"
          hl.buffer_visible.bold = true
          hl.buffer_visible.italic = true
          hl.buffer_visible.fg = visible
          hl.tab_selected.bold = true
          hl.tab_selected.bg = visible_tab
          hl.tab_separator_selected.bg = visible_tab
          return hl
        end,
        options = {
          debug = { logging = true },
          mode = "buffers",
          sort_by = "insert_after_current",
          right_mouse_command = "vert sbuffer %d",
          show_close_icon = false,
          show_buffer_close_icons = true,
          -- indicator = { style = "underline" },
          -- diagnostics = "nvim_lsp",
          -- diagnostics_indicator = function(count, level)
          --   level = level:match("warn") and "warn" or level
          --   return (icons[level] or "?") .. " " .. count
          -- end,
          -- diagnostics_update_in_insert = false,
          hover = { enabled = true, reveal = { "close" } },
          offsets = {
            {
              text = "EXPLORER",
              filetype = "neo-tree",
              highlight = "PanelHeading",
              text_align = "left",
              separator = true,
            },
            {
              text = " FLUTTER OUTLINE",
              filetype = "flutterToolsOutline",
              highlight = "PanelHeading",
              separator = true,
            },
            {
              text = "UNDOTREE",
              filetype = "undotree",
              highlight = "PanelHeading",
              separator = true,
            },
            {
              text = " DATABASE VIEWER",
              filetype = "dbui",
              highlight = "PanelHeading",
              separator = true,
            },
            {
              text = " DIFF VIEW",
              filetype = "DiffviewFiles",
              highlight = "PanelHeading",
              separator = true,
            },
          },
          groups = {
            options = { toggle_hidden_on_enter = true },
            items = {
              groups.builtin.pinned:with({ icon = "" }),
              groups.builtin.ungrouped,
              {
                name = "Dependencies",
                icon = "",
                highlight = { fg = "#ECBE7B" },
                matcher = function(buf) return vim.startswith(buf.path, vim.env.VIMRUNTIME) end,
              },
              {
                name = "Terraform",
                matcher = function(buf) return buf.name:match("%.tf") ~= nil end,
              },
              {
                name = "Kubernetes",
                matcher = function(buf) return buf.name:match("kubernetes") and buf.name:match("%.yaml") end,
              },
              {
                name = "SQL",
                matcher = function(buf) return buf.filename:match("%.sql$") end,
              },
              {
                name = "tests",
                icon = "",
                matcher = function(buf)
                  local name = buf.filename
                  if name:match("%.sql$") == nil then return false end
                  return name:match("_spec") or name:match("_test")
                end,
              },
              {
                name = "docs",
                icon = "",
                matcher = function(buf)
                  if vim.bo[buf.id].filetype == "man" or buf.path:match("man://") then return true end
                  for _, ext in ipairs({ "md", "txt", "org", "norg", "wiki" }) do
                    if ext == fn.fnamemodify(buf.path, ":e") then return true end
                  end
                end,
              },
            },
          },
        },
      })

      map("n", "[b", "<Cmd>BufferLineMoveNext<CR>", { desc = "bufferline: move next" })
      map("n", "]b", "<Cmd>BufferLineMovePrev<CR>", { desc = "bufferline: move prev" })
      map("n", "gbb", "<Cmd>BufferLinePick<CR>", { desc = "bufferline: pick buffer" })
      map("n", "gbd", "<Cmd>BufferLinePickClose<CR>", { desc = "bufferline: delete buffer" })
      map("n", "<S-tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "bufferline: prev" })
      map("n", "<tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "bufferline: next" })
    end,
  },
}
