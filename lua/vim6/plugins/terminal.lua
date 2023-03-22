local fn = vim.fn

return {
  "akinsho/toggleterm.nvim",
  event = "VeryLazy",
  dev = true,
  opts = {
    open_mapping = [[<c-\>]],
    shade_filetypes = { "none" },
    direction = "horizontal",
    autochdir = true,
    persist_mode = true,
    insert_mappings = false,
    start_in_insert = true,
    winbar = { enabled = vim6.ui.winbar.enable },
    highlights = {
      FloatBorder = { link = "FloatBorder" },
      NormalFloat = { link = "NormalFloat" },
    },
    float_opts = {
      border = vim6.ui.current.border,
      winblend = 3,
    },
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return math.floor(vim.o.columns * 0.4)
      end
    end,
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)

    local float_handler = function(term)
      vim.wo.sidescrolloff = 0
      if not vim6.empty(fn.mapcheck("jk", "t")) then
        vim.keymap.del("t", "jk", { buffer = term.bufnr })
        vim.keymap.del("t", "<esc>", { buffer = term.bufnr })
      end
    end

    local Terminal = require("toggleterm.terminal").Terminal

    local lazygit = Terminal:new({
      cmd = "lazygit",
      dir = "git_dir",
      hidden = true,
      direction = "float",
      on_open = float_handler,
    })

    local btop = Terminal:new({
      cmd = "btop",
      hidden = true,
      direction = "float",
      on_open = float_handler,
      highlights = {
        FloatBorder = { guibg = "Black", guifg = "DarkGray" },
        NormalFloat = { guibg = "Black" },
      },
    })

    local gh_dash = Terminal:new({
      cmd = "gh dash",
      hidden = true,
      direction = "float",
      on_open = float_handler,
      float_opts = {
        height = function() return math.floor(vim.o.lines * 0.8) end,
        width = function() return math.floor(vim.o.columns * 0.95) end,
      },
    })

    map("n", "<leader>gD", function() gh_dash:toggle() end, {
      desc = "toggleterm: toggle github dashboard",
    })
    map("n", "<leader>gg", function() lazygit:toggle() end, {
      desc = "toggleterm: toggle lazygit",
    })
    map("n", "<leader>lt", function() btop:toggle() end, {
      desc = "toggleterm: toggle btop",
    })

    vim6.command("Btop", function() btop:toggle() end)
    vim6.command("Lazygit", function() lazygit:toggle() end)
    vim6.command("Gdash", function() gh_dash:toggle() end)
  end,
}
