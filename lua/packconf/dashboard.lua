local M = {}
M.config = function()
  nvim.builtin.dashboard = {
    active = false,
    search_handler = "telescope",
    custom_header = {
  "                                                         ",
  "                                                         ",
  "                                                         ",
  "                                                         ",
  "                                           ▟▙            ",
  "                                           ▝▘            ",
  "   ██▃▅▇█▆▖  ▗▟████▙▖   ▄████▄   ██▄  ▄██  ██  ▗▟█▆▄▄▆█▙▖",
  "   ██▛▔ ▝██  ██▄▄▄▄██  ██▛▔▔▜██  ▝██  ██▘  ██  ██▛▜██▛▜██",
  "   ██    ██  ██▀▀▀▀▀▘  ██▖  ▗██   ▜█▙▟█▛   ██  ██  ██  ██",
  "   ██    ██  ▜█▙▄▄▄▟▊  ▀██▙▟██▀   ▝████▘   ██  ██  ██  ██",
  "   ▀▀    ▀▀   ▝▀▀▀▀▀     ▀▀▀▀       ▀▀     ▀▀  ▀▀  ▀▀  ▀▀",
  "                                                         ",
  "                                                         ",
    },
--     custom_header = {
-- "▄▀▀▄ ▄▀▀▄  ▄▀▀█▀▄    ▄▀▀▄ ▄▀▄      ▄▀▀▄▀▀▀▄  ▄▀▀█▄▄▄▄  ▄▀▀█▄   ▄▀▀▄▀▀▀▄  ▄▀▀█▄▄▄▄  ▄▀▀▄▀▀▀▄ ",
-- "█   █    █ █   █  █  █  █ ▀  █     █   █   █ ▐  ▄▀   ▐ ▐ ▄▀ ▀▄ █   █   █ ▐  ▄▀   ▐ █   █   █ ",
-- "▐  █    █  ▐   █  ▐  ▐  █    █     ▐  █▀▀█▀    █▄▄▄▄▄    █▄▄▄█ ▐  █▀▀▀▀    █▄▄▄▄▄  ▐  █▀▀█▀  ",
-- "  █   ▄▀      █       █    █       ▄▀    █    █    ▌   ▄▀   █    █        █    ▌   ▄▀    █  ",
-- "   ▀▄▀     ▄▀▀▀▀▀▄  ▄▀   ▄▀       █     █    ▄▀▄▄▄▄   █   ▄▀   ▄▀        ▄▀▄▄▄▄   █     █   ",
-- "          █       █ █    █        ▐     ▐    █    ▐   ▐   ▐   █          █    ▐   ▐     ▐   ",
-- "          ▐       ▐ ▐    ▐                   ▐                ▐          ▐                  ",
-- "",
-- "",
-- "                                          ;::::;",
-- "                                        ;::::; :;",
-- "                                      ;:::::'   :;",
-- "                                     ;:::::;     ;.",
-- "                                    ,:::::'       ;           OOO0 ",
-- "                                    ::::::;       ;          OOOOO0 ",
-- "                                    ;:::::;       ;         OOOOOOOO",
-- "                                   ,;::::::;     ;'         / OOOOOOO",
-- "                                 ;:::::::::`. ,,,;.        /  / DOOOOOO",
-- "                               .';:::::::::::::::::;,     /  /     DOOOO",
-- "                              ,::::::;::::::;;;;::::;,   /  /        DOOO",
-- "                             ;`::::::`'::::::;;;::::: ,#/  /          DOOO",
-- "                             :`:::::::`;::::::;;::: ;::#  /            DOOO",
-- "                             ::`:::::::`;:::::::: ;::::# /              DOO",
-- "                             `:`:::::::`;:::::: ;::::::#/               DOO",
-- "                              :::`:::::::`;; ;:::::::::##                OO",
-- "                              ::::`:::::::`;::::::::;:::#                OO",
-- "                              `:::::`::::::::::::;'`:;::#                O",
-- "                               `:::::`::::::::;' /  / `:#",
-- "                                ::::::`:::::;'  /  /   `#",
--     },

    custom_section = {
      a = {
        description = { "  Find File          " },
        command = "Telescope find_files",
      },
      b = {
        description = { "  Recently Used Files" },
        command = "Telescope oldfiles",
      },
      c = {
        description = { "  Load Last Session  " },
        command = "SessionLoad",
      },
      d = {
        description = { "  Find Word          " },
        command = "Telescope live_grep",
      },
      e = {
        description = { "  Settings           " },
        command = ":e " .. USER_CONFIG_PATH,
      },
    },

    footer = { "WITH <3 in SANTIAGO by Marcosito" },
  }
end

M.setup = function()
  vim.g.dashboard_disable_at_vimenter = 0

  vim.g.dashboard_custom_header = nvim.builtin.dashboard.custom_header

  vim.g.dashboard_default_executive = nvim.builtin.dashboard.search_handler

  vim.g.dashboard_custom_section = nvim.builtin.dashboard.custom_section

  nvim.builtin.which_key.mappings[";"] = { "<cmd>Dashboard<CR>", "Dashboard" }

  -- f = {
  --   description = { "  Neovim Config Files" },
  --   command = "Telescope find_files cwd=" .. CONFIG_PATH,
  -- },
  -- e = {description = {'  Marks              '}, command = 'Telescope marks'}
  vim.cmd 'let g:dashboard_session_directory = "~/.config/nvim/.sessions"'
  vim.cmd "let packages = len(globpath('~/.local/share/nvim/plugin/pack/packer/start', '*', 0, 1))"

  vim.api.nvim_exec(
    [[
    let g:dashboard_custom_footer = ['WITH <3 in SANTIAGO by Marcosito']
]],
    false
  )

  -- file_browser = {description = {' File Browser'}, command = 'Telescope find_files'},

  -- vim.g.dashboard_session_directory = CACHE_PATH..'/session'
  -- vim.g.dashboard_custom_footer = nvim.dashboard.footer

  require("packconf.autocmds").define_augroups {
    _dashboard = {
      -- seems to be nobuflisted that makes my stuff disapear will do more testing
      {
        "FileType",
        "dashboard",
        "setlocal nocursorline noswapfile synmaxcol& signcolumn=no norelativenumber nocursorcolumn nospell  nolist  nonumber bufhidden=wipe colorcolumn= foldcolumn=0 matchpairs= ",
      },
      {
        "FileType",
        "dashboard",
        "set showtabline=0 | autocmd BufLeave <buffer> set showtabline=" .. vim.opt.showtabline._value,
      },
      { "FileType", "dashboard", "nnoremap <silent> <buffer> q :q<CR>" },
    },
  }
end

return M
