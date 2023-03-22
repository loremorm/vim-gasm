return {
  -- FIXME: https://github.com/L3MON4D3/LuaSnip/issues/129
  -- causes formatting bugs on save when update events are TextChanged{I}
  {
    "L3MON4D3/LuaSnip",
    event = "InsertEnter",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      local ls = require("luasnip")
      local types = require("luasnip.util.types")
      local extras = require("luasnip.extras")
      local fmt = require("luasnip.extras.fmt").fmt

      ls.config.set_config({
        history = false,
        region_check_events = "CursorMoved,CursorHold,InsertEnter",
        delete_check_events = "InsertLeave",
        ext_opts = {
          [types.choiceNode] = {
            active = {
              hl_mode = "combine",
              virt_text = { { "●", "Operator" } },
            },
          },
          [types.insertNode] = {
            active = {
              hl_mode = "combine",
              virt_text = { { "●", "Type" } },
            },
          },
        },
        enable_autosnippets = true,
        snip_env = {
          fmt = fmt,
          m = extras.match,
          t = ls.text_node,
          f = ls.function_node,
          c = ls.choice_node,
          d = ls.dynamic_node,
          i = ls.insert_node,
          l = extras.lamda,
          snippet = ls.snippet,
        },
      })

      vim6.command("LuaSnipEdit", function() require("luasnip.loaders.from_lua").edit_snippet_files() end)

      -- <c-l> is selecting within a list of options.
      map({ "s", "i" }, "<c-l>", function()
        if ls.choice_active() then ls.change_choice(1) end
      end)

      map({ "s", "i" }, "<c-j>", function()
        if ls.expand_or_jumpable() then ls.expand_or_jump() end
      end)

      -- <C-K> is easier to hit but swallows the digraph key
      map({ "s", "i" }, "<c-b>", function()
        if ls.jumpable(-1) then ls.jump(-1) end
      end)

      require("luasnip.loaders.from_lua").lazy_load()
      -- NOTE: the loader is called twice so it picks up the defaults first then my custom textmate
      -- snippets.
      -- see: https://github.com/L3MON4D3/LuaSnip/issues/364
      require("luasnip.loaders.from_vscode").lazy_load()
      require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets/textmate" })

      ls.filetype_extend("typescriptreact", { "javascript", "typescript" })
      ls.filetype_extend("dart", { "flutter" })
    end,
  },
  {
    "benfowler/telescope-luasnip.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function() require("telescope").load_extension("luasnip") end,
  },
}
