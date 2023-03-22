local highlight = vim6.highlight
local icons = vim6.ui.icons

return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v2.x",
    -- cmd = { "Neotree" },
    keys = { { "<C-N>", "<Cmd>Neotree toggle reveal<CR>", desc = "NeoTree" } },
    config = function()
      highlight.plugin("NeoTree", {
        -- stylua: ignore
        theme = {
          ['*'] = {
            { NeoTreeNormal = { link = 'PanelBackground' } },
            { NeoTreeNormalNC = { link = 'PanelBackground' } },
            { NeoTreeRootName = { underline = true } },
            { NeoTreeCursorLine = { link = 'Visual' } },
            { NeoTreeStatusLine = { link = 'PanelSt' } },
            { NeoTreeTabActive = { bg = { from = 'PanelBackground' }, bold = true } },
            { NeoTreeTabInactive = { bg = { from = 'PanelDarkBackground', alter = 15 }, fg = { from = 'Comment' } } },
            { NeoTreeTabSeparatorInactive = { inherit = 'NeoTreeTabInactive', fg = { from = 'PanelDarkBackground', attr = 'bg' } } },
            { NeoTreeTabSeparatorActive = { inherit = 'PanelBackground', fg = { from = 'Comment' } } },
          },
          horizon = {
            { NeoTreeDirectoryIcon = { fg = '#C09553' } },
            { NeoTreeWinSeparator = { link = 'WinSeparator' } },
            { NeoTreeTabInactive = { bg = { from = 'PanelBackground' }, fg = { from = 'Comment' } } },
            { NeoTreeTabActive = { link = 'VisibleTab' } },
            { NeoTreeTabSeparatorActive = { link = 'VisibleTab' } },
            { NeoTreeTabSeparatorInactive = { inherit = 'NeoTreeTabInactive', fg = { from = 'PanelBackground', attr = 'bg' } },
            },
          },
        },
      })

      vim.g.neo_tree_remove_legacy_commands = 1

      require("neo-tree").setup({
        sources = { "filesystem", "buffers", "git_status", "diagnostics" },
        source_selector = { winbar = true, separator_active = " " },
        enable_git_status = true,
        git_status_async = true,
        nesting_rules = {
          ["dart"] = { "freezed.dart", "g.dart" },
        },
        event_handlers = {
          {
            event = "neo_tree_buffer_enter",
            handler = function() highlight.set("Cursor", { blend = 100 }) end,
          },
          {
            event = "neo_tree_buffer_leave",
            handler = function() highlight.set("Cursor", { blend = 0 }) end,
          },
          {
            event = "neo_tree_window_after_close",
            handler = function() highlight.set("Cursor", { blend = 0 }) end,
          },
        },
        filesystem = {
          hijack_netrw_behavior = "open_current",
          use_libuv_file_watcher = true,
          group_empty_dirs = true,
          follow_current_file = false,
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = true,
            never_show = { ".DS_Store" },
          },
          window = {
            mappings = {
              ["/"] = "noop",
              ["g/"] = "fuzzy_finder",
            },
          },
        },
        default_component_configs = {
          icon = {
            folder_empty = "",
          },
          diagnostics = {
            highlights = {
              hint = "DiagnosticHint",
              info = "DiagnosticInfo",
              warn = "DiagnosticWarn",
              error = "DiagnosticError",
            },
          },
          modified = {
            symbol = icons.misc.circle .. " ",
          },
          git_status = {
            symbols = {
              added = icons.git.add,
              deleted = icons.git.remove,
              modified = icons.git.mod,
              renamed = icons.git.rename,
              untracked = "",
              ignored = "",
              unstaged = "",
              staged = "",
              conflict = "",
            },
          },
        },
        window = {
          mappings = {
            ["o"] = "toggle_node",
            ["l"] = "open_with_window_picker",
            ["<CR>"] = "open_with_window_picker",
            ["<c-s>"] = "split_with_window_picker",
            ["<c-v>"] = "vsplit_with_window_picker",
            ["<esc>"] = "revert_preview",
            ["P"] = { "toggle_preview", config = { use_float = true } },
          },
        },
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      { "mrbjarksen/neo-tree-diagnostics.nvim" },
      {
        "s1n7ax/nvim-window-picker",
        version = "*",
        opts = {
          use_winbar = "smart",
          autoselect_one = true,
          include_current = false,
          other_win_hl_color = highlight.get("Visual", "bg"),
          filter_rules = {
            bo = {
              filetype = { "neo-tree-popup", "quickfix" },
              buftype = { "terminal", "quickfix", "nofile" },
            },
          },
        },
      },
    },
  },
}
