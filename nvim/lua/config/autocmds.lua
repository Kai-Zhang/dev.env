-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-check for external file changes (e.g. gofmt/goimports run in terminal)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = vim.api.nvim_create_augroup("user_autoread", { clear = true }),
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_lsp_tsserver_keymaps", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "tsserver" then
      return
    end
    if vim.fn.exists(":TypescriptOrganizeImports") == 2 then
      vim.keymap.set(
        "n",
        "<leader>co",
        "<cmd>TypescriptOrganizeImports<CR>",
        { buffer = args.buf, desc = "Organize Imports" }
      )
    end
    if vim.fn.exists(":TypescriptRenameFile") == 2 then
      vim.keymap.set(
        "n",
        "<leader>cR",
        "<cmd>TypescriptRenameFile<CR>",
        { buffer = args.buf, desc = "Rename File" }
      )
    end
  end,
})
