return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        gopls = {
          settings = {
            gopls = {
              buildFlags = { "-tags=e2e" },
            },
          },
        },
        pyright = {},
      },
      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      setup = {
        gopls = function() end,
      },
    },
  },
}
