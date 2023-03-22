local opt, api, fn, fmt = vim.opt, vim.api, vim.fn, string.format
local ui, border, highlight = vim6.ui, vim6.ui.current.border, vim6.highlight

return {
  -----------------------------------------------------------------------------//
  -- Core {{{3
  -----------------------------------------------------------------------------//
  "nvim-lua/plenary.nvim", -- THE LIBRARY
  "nvim-tree/nvim-web-devicons",
  {
    "olimorris/persisted.nvim",
    lazy = false,
    init = function()
      vim6.command("ListSessions", "Telescope persisted")
      vim6.augroup("PersistedEvents", {
        event = "User",
        pattern = "PersistedTelescopeLoadPre",
        command = function()
          vim.schedule(function() vim.cmd("%bd") end)
        end,
      })
    end,
    opts = {
      autoload = true,
      use_git_branch = true,
      allowed_dirs = { vim.g.dotfiles, vim.g.work_dir, vim.g.projects_dir .. "/personal" },
      ignored_dirs = { fn.stdpath("data") },
      on_autoload_no_session = function() vim.cmd.Alpha() end,
      should_autosave = function() return vim.bo.filetype ~= "alpha" end,
    },
  },
  -----------------------------------------------------------------------------//
  -- LSP,Completion & Debugger {{{1
  -----------------------------------------------------------------------------//
  {
    {
      "williamboman/mason.nvim",
      cmd = "Mason",
      opts = { ui = { border = border, height = 0.8 } },
    },
    {
      "williamboman/mason-lspconfig.nvim",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = {
        "mason.nvim",
        {
          "neovim/nvim-lspconfig",
          dependencies = {
            {
              "folke/neodev.nvim",
              ft = "lua",
              opts = { library = { plugins = { "nvim-dap-ui" } } },
            },
            {
              "folke/neoconf.nvim",
              cmd = { "Neoconf" },
              opts = { local_settings = ".nvim.json", global_settings = "nvim.json" },
            },
          },
          config = function()
            highlight.plugin("lspconfig", { { LspInfoBorder = { link = "FloatBorder" } } })
            require("lspconfig.ui.windows").default_options.border = border
            require("lspconfig").ccls.setup(require("vim6.servers")("ccls"))
          end,
        },
      },
      config = function()
        require("mason-lspconfig").setup({ automatic_installation = true })
        require("mason-lspconfig").setup_handlers({
          function(name)
            local config = require("vim6.servers")(name)
            if config then require("lspconfig")[name].setup(config) end
          end,
        })
      end,
    },
  },
  -- just like peek in vscode
  {
    "DNLHC/glance.nvim",
    opts = {
      preview_win_opts = { relativenumber = false },
      theme = { enable = true, mode = "darken" },
    },
    keys = {
      { "gD", "<Cmd>Glance definitions<CR>", desc = "lsp: glance definitions" },
      { "gR", "<Cmd>Glance references<CR>", desc = "lsp: glance references" },
      { "gY", "<Cmd>Glance type_definitions<CR>", desc = "lsp: glance type definitions" },
      { "gM", "<Cmd>Glance implementations<CR>", desc = "lsp: glance implementations" },
    },
  },
  {
    "smjonas/inc-rename.nvim",
    opts = { hl_group = "Visual" },
    keys = {
      {
        "<leader>rn",
        function() return ":IncRename " .. fn.expand("<cword>") end,
        expr = true,
        silent = false,
        desc = "lsp: incremental rename",
      },
    },
  },
  {
    "lvimuser/lsp-inlayhints.nvim",
    opts = {
      inlay_hints = {
        highlight = "Comment",
        labels_separator = " ⏐ ",
        parameter_hints = { prefix = "" },
        type_hints = { prefix = "=> ", remove_colon_start = true },
      },
    },
  },
  {
    "simrat39/rust-tools.nvim",
    dependencies = { "nvim-lspconfig" },
  },
  {
    "saecki/crates.nvim",
    version = "*",
    event = "BufRead Cargo.toml",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      popup = { border = border },
      null_ls = { enabled = true },
    },
    config = function(_, opts)
      vim6.augroup("CmpSourceCargo", {
        event = "BufRead",
        pattern = "Cargo.toml",
        command = function() require("cmp").setup.buffer({ sources = { { name = "crates" } } }) end,
      })
      require("crates").setup(opts)
    end,
  },
  -- }}}

  -- UI {{{1
  -- create colors
  {
    "uga-rosa/ccc.nvim",
    ft = { "lua", "vim", "typescript", "typescriptreact", "javascriptreact" },
    cmd = { "CccHighlighterToggle" },
    opts = {
      win_opts = { border = border },
      highlighter = { auto_enable = true, excludes = { "dart", "lazy", "orgagenda", "org" } },
    },
  },
  -- win bar
  {
    "SmiteshP/nvim-navic",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      vim.g.navic_silence = true
      local misc = ui.icons.misc

      highlight.plugin("navic", {
        { NavicText = { bold = true } },
        { NavicSeparator = { link = "Directory" } },
      })
      local icons = vim6.map(function(icon, key)
        highlight.set(fmt("NavicIcons%s", key), { link = ui.lsp.highlights[key] })
        return icon .. " "
      end, ui.current.lsp_icons)

      require("nvim-navic").setup({
        icons = icons,
        highlight = true,
        depth_limit_indicator = misc.ellipsis,
        separator = (" %s "):format(misc.arrow_right),
      })
    end,
  },
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("todo-comments").setup()
      vim6.command("TodoDots", ("TodoQuickFix cwd=%s keywords=TODO,FIXME"):format(vim.g.vim_dir))
    end,
  },
  {
    "cbochs/portal.nvim",
    cmd = { "Portal" },
    keys = {
      { "<leader>jb", "<cmd>Portal jumplist backward<cr>", desc = "jump: backwards" },
      { "<leader>jf", "<cmd>Portal jumplist forward<cr>", desc = "jump: forwards" },
      { "<leader>jg", "<cmd>Portal grapple<cr>", desc = "jump: grapple" },
    },
    dependencies = { "cbochs/grapple.nvim" },
    opts = {
      filter = function(v)
        local file_path = api.nvim_buf_get_name(v.buffer)
        return vim.startswith(file_path, fn.getcwd())
      end,
      window_options = {
        -- TODO: this grapple/portal.nvim should allow customising the border highlights
        border = {
          { "┌", "Label" },
          { "─", "Label" },
          { "┐", "Label" },
          { "│", "Label" },
          { "┘", "Label" },
          { "─", "Label" },
          { "└", "Label" },
          { "│", "Label" },
        },
      },
    },
  },
  {
    "cbochs/grapple.nvim",
    cmd = { "Grapple", "GrapplePopup" },
    keys = {
      { "<leader>mt", function() require("grapple").toggle() end, desc = "grapple: toggle mark" },
      { "<leader>mm", "<Cmd>GrapplePopup tags<CR>", desc = "grapple: menu" },
    },
    opts = { popup_options = { border = border } },
  },
  -- }}}
  --------------------------------------------------------------------------------
  -- Utilities {{{1
  --------------------------------------------------------------------------------
  {
    "mg979/vim-visual-multi",
    keys = { { "<C-E>", mode = { "n", "x" } }, "\\j", "\\k" },
    init = function()
      vim.g.VM_highlight_matches = "underline"
      vim.g.VM_theme = "codedark"
      vim.g.VM_maps = {
        ["Find Word"] = "<C-E>",
        ["Find Under"] = "<C-E>",
        ["Find Subword Under"] = "<C-E>",
        ["Select Cursor Down"] = "\\j",
        ["Select Cursor Up"] = "\\k",
      }
    end,
  },
  {
    "chaoren/vim-wordmotion",
    lazy = false,
    init = function() vim.g.wordmotion_spaces = { "-", "_", "\\/", "\\." } end,
  },
  {
    "kylechui/nvim-surround",
    keys = { { "s", mode = "v" }, "<C-g>s", "<C-g>S", "ys", "yss", "yS", "cs", "ds" },
    opts = { move_cursor = true, keymaps = { visual = "s" } },
  },
  {
    "andrewferrier/debugprint.nvim",
    opts = { create_keymaps = false },
    keys = {
      {
        "<leader>dp",
        function() return require("debugprint").debugprint({ variable = true }) end,
        desc = "debugprint: cursor",
        expr = true,
      },
      {
        "<leader>do",
        function() return require("debugprint").debugprint({ motion = true }) end,
        desc = "debugprint: operator",
        expr = true,
      },
      { "<leader>dC", "<Cmd>DeleteDebugPrints<CR>", desc = "debugprint: clear all" },
    },
  },
  -- prevent select and visual mode from overwriting the clipboard
  {
    "kevinhwang91/nvim-hclipboard",
    event = "InsertCharPre",
    config = function() require("hclipboard").start() end,
  },
  {
    "jghauser/fold-cycle.nvim",
    config = true,
    keys = {
      { "<BS>", function() require("fold-cycle").open() end, desc = "fold-cycle: toggle" },
    },
  },
  -- Diff arbitrary blocks of text with each other
  { "AndrewRadev/linediff.vim", cmd = "Linediff" },
  {
    "rainbowhxch/beacon.nvim",
    event = "VeryLazy",
    config = function()
      local beacon = require("beacon")
      beacon.setup({
        minimal_jump = 20,
        ignore_buffers = { "terminal", "nofile", "neorg://Quick Actions" },
        ignore_filetypes = {
          "qf",
          "neo-tree",
          "NeogitCommitMessage",
          "NeogitPopup",
          "NeogitStatus",
          "trouble",
        },
      })
      vim6.augroup("BeaconCmds", {
        event = "BufReadPre",
        pattern = "*.norg",
        command = function() beacon.beacon_off() end,
      })
    end,
  },
  {
    "mfussenegger/nvim-treehopper",
    keys = {
      {
        "u",
        function() require("tsht").nodes() end,
        desc = "treehopper: toggle",
        mode = "o",
        noremap = false,
        silent = true,
      },
      {
        "u",
        ":lua require('tsht').nodes()<CR>",
        desc = "treehopper: toggle",
        mode = "x",
        silent = true,
      },
    },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = { "hrsh7th/nvim-cmp" },
    config = function()
      local autopairs = require("nvim-autopairs")
      local Rule = require("nvim-autopairs.rule")
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
      autopairs.setup({
        close_triple_quotes = true,
        check_ts = true,
        fast_wrap = { map = "<c-e>" },
        ts_config = {
          lua = { "string" },
          dart = { "string" },
          javascript = { "template_string" },
        },
      })
      -- credit: https://github.com/JoosepAlviste
      -- Typing = when () -> () => {|}
      autopairs.add_rules({
        Rule("%(.*%)%s*%=$", "> {}", { "typescript", "typescriptreact", "javascript", "vue" })
          :use_regex(true)
          :set_end_pair_length(1),
        -- Typing n when the| -> then|end
        Rule("then", "end", "lua"):end_wise(function(opts) return string.match(opts.line, "^%s*if") ~= nil end),
      })
    end,
  },
  -- {
  --   "karb94/neoscroll.nvim", -- NOTE: alternative: 'declancm/cinnamon.nvim'
  --   event = "VeryLazy",
  --   opts = {
  --     mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "zt", "zz", "zb" },
  --     hide_cursor = true,
  --   },
  -- },
  {
    "itchyny/vim-highlighturl",
    event = "VeryLazy",
    config = function() vim.g.highlighturl_guifg = highlight.get("URL", "fg") end,
  },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = { { "<leader>u", "<Cmd>UndotreeToggle<CR>", desc = "undotree: toggle" } },
    config = function()
      vim.g.undotree_TreeNodeShape = "◦" -- Alternative: '◉'
      vim.g.undotree_SetFocusWhenToggle = 1
    end,
  },
  {
    "moll/vim-bbye",
    cmd = "Bwipeout",
    keys = { { "<leader>qq", "<Cmd>Bwipeout<CR>", desc = "bbye: quit" } },
  },
  { "nacro90/numb.nvim", event = "CmdlineEnter", config = true },
  -----------------------------------------------------------------------------//
  -- Quickfix
  -----------------------------------------------------------------------------//
  {
    url = "https://gitlab.com/yorickpeterse/nvim-pqf",
    event = "VeryLazy",
    config = function()
      highlight.plugin("pqf", {
        theme = {
          ["doom-one"] = { { qfPosition = { link = "Todo" } } },
          ["horizon"] = { { qfPosition = { link = "String" } } },
        },
      })
      require("pqf").setup()
    end,
  },
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    config = function() highlight.plugin("bqf", { { BqfPreviewBorder = { fg = { from = "Comment" } } } }) end,
  },
  -- }}}
  --------------------------------------------------------------------------------
  -- Profiling & Startup {{{1
  --------------------------------------------------------------------------------
  {
    "dstein64/vim-startuptime",
    cmd = "StartupTime",
    config = function()
      vim.g.startuptime_tries = 15
      vim.g.startuptime_exe_args = { "+let g:auto_session_enabled = 0" }
    end,
  },
  -- }}}
  --------------------------------------------------------------------------------
  -- TPOPE {{{1
  --------------------------------------------------------------------------------
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = "tpope/vim-dadbod",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      map("n", "<leader>db", "<cmd>DBUIToggle<CR>", { desc = "dadbod: toggle" })
    end,
  },
  { "tpope/vim-eunuch", cmd = { "Move", "Rename", "Remove", "Delete", "Mkdir" } },
  { "tpope/vim-sleuth", event = "VeryLazy" },
  { "tpope/vim-repeat", event = "VeryLazy" },
  {
    "tpope/vim-abolish",
    event = "CmdlineEnter",
    keys = {
      {
        "<localleader>[",
        ":S/<C-R><C-W>//<LEFT>",
        mode = "n",
        silent = false,
        desc = "abolish: replace word under the cursor (line)",
      },
      {
        "<localleader>]",
        ":%S/<C-r><C-w>//c<left><left>",
        mode = "n",
        silent = false,
        desc = "abolish: replace word under the cursor (file)",
      },
      {
        "<localleader>[",
        [["zy:'<'>S/<C-r><C-o>"//c<left><left>]],
        mode = "x",
        silent = false,
        desc = "abolish: replace word under the cursor (visual)",
      },
    },
  },
  -- }}}
  -----------------------------------------------------------------------------//
  -- Filetype Plugins {{{1
  -----------------------------------------------------------------------------//
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
  },
  "nanotee/sqls.nvim",
  {
    "iamcco/markdown-preview.nvim",
    build = function() fn["mkdp#util#install"]() end,
    ft = { "markdown" },
    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
    end,
  },
  {
    "jose-elias-alvarez/typescript.nvim",
    ft = { "typescript", "typescriptreact" },
    dependencies = { "jose-elias-alvarez/null-ls.nvim" },
    config = function()
      require("typescript").setup({ server = require("vim6.servers")("tsserver") })
      require("null-ls").register({
        sources = { require("typescript.extensions.null-ls.code-actions") },
      })
    end,
  },
  { "fladson/vim-kitty", lazy = false },
  { "mtdl9/vim-log-highlighting", lazy = false },
  -- }}}
  --------------------------------------------------------------------------------
  -- Syntax {{{1
  --------------------------------------------------------------------------------
  {
    "m-demare/hlargs.nvim",
    event = "VeryLazy",
    config = function()
      highlight.plugin("hlargs", {
        theme = {
          ["*"] = { { Hlargs = { italic = true, foreground = "#A5D6FF" } } },
          ["horizon"] = { { Hlargs = { italic = true, foreground = { from = "Normal" } } } },
        },
      })
      require("hlargs").setup({
        excluded_argnames = {
          declarations = { "use", "_" },
          usages = { go = { "_" }, lua = { "self", "use", "_" } },
        },
      })
    end,
  },
  {
    "psliwka/vim-dirtytalk",
    lazy = false,
    build = ":DirtytalkUpdate",
    config = function() opt.spelllang:append("programming") end,
  },
  ---}}}
  --------------------------------------------------------------------------------
  -- Editing {{{1
  --------------------------------------------------------------------------------
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter" },
    opts = { use_default_keymaps = false },
    keys = {
      { "gS", "<Cmd>TSJSplit<CR>", desc = "split expression to multiple lines" },
      { "gJ", "<Cmd>TSJJoin<CR>", desc = "join expression to single line" },
    },
  },
  {
    "Wansmer/sibling-swap.nvim",
    keys = { "]w", "[w" },
    dependencies = { "nvim-treesitter" },
    opts = {
      use_default_keymaps = true,
      keymaps = {
        ["]w"] = "swap_with_left",
        ["[w"] = "swap_with_right",
      },
    },
  },
  {
    "cshuaimin/ssr.nvim",
    opts = { border = border },
    keys = {
      {
        "<leader>sr",
        function() require("ssr").open() end,
        mode = { "n", "x" },
        desc = "structured search and replace",
      },
    },
  },
  {
    "numToStr/Comment.nvim",
    keys = { "gcc", { "gc", mode = { "x", "n", "o" } } },
    opts = function(_, opts)
      local ok, integration = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
      if ok then opts.pre_hook = integration.create_pre_hook() end
    end,
  },
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    config = function() require("mini.ai").setup({ mappings = { around_last = "", inside_last = "" } }) end,
  },
  {
    "glts/vim-textobj-comment",
    dependencies = { { "kana/vim-textobj-user", dependencies = { "kana/vim-operator-user" } } },
    init = function() vim.g.textobj_comment_no_default_key_mappings = 1 end,
    keys = {
      { "ax", "<Plug>(textobj-comment-a)", mode = { "x", "o" } },
      { "ix", "<Plug>(textobj-comment-i)", mode = { "x", "o" } },
    },
  },
  {
    "linty-org/readline.nvim",
    keys = {
      { "<M-f>", function() require("readline").forward_word() end, mode = "!" },
      { "<M-b>", function() require("readline").backward_word() end, mode = "!" },
      { "<C-a>", function() require("readline").beginning_of_line() end, mode = "!" },
      { "<C-e>", function() require("readline").end_of_line() end, mode = "!" },
      { "<M-d>", function() require("readline").kill_word() end, mode = "!" },
      { "<M-BS>", function() require("readline").backward_kill_word() end, mode = "!" },
      { "<C-w>", function() require("readline").unix_word_rubout() end, mode = "!" },
      { "<C-k>", function() require("readline").kill_line() end, mode = "!" },
      { "<C-u>", function() require("readline").backward_kill_line() end, mode = "!" },
    },
  },
  -- }}}

  -- { "tweekmonster/helpful.vim", cmd = "HelpfulVersion", ft = "help" },
  -- { "rafcamlet/nvim-luapad", cmd = "Luapad" },
  -- }}}
  {
    "akinsho/git-conflict.nvim",
    event = "VeryLazy",
    dev = true,
    opts = { disable_diagnostics = true },
  },
}
--}}}
---------------------------------------------------------------------------------
-- vim:foldmethod=marker nospell
