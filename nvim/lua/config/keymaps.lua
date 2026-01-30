-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Terminal helpers (built-in :terminal, no extra plugin)
vim.keymap.set("n", "<leader>tt", function()
  vim.cmd("split | terminal")
end, { desc = "Terminal (split)" })
vim.keymap.set("n", "<leader>tv", function()
  vim.cmd("vsplit | terminal")
end, { desc = "Terminal (vsplit)" })

-- Make it easy to leave terminal-mode and move between splits
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "Go to left split" })
vim.keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "Go to lower split" })
vim.keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "Go to upper split" })
vim.keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "Go to right split" })

-- Resize splits with <C-w><C-h/j/k/l> (direction-consistent)
local function resize_dir(dir, amount)
  local cur = vim.fn.winnr()
  local target = cur
  if dir == "left" then
    local left = vim.fn.winnr("h")
    if left ~= cur then
      target = left
    end
    local win = vim.fn.win_getid(target)
    local width = vim.api.nvim_win_get_width(win)
    vim.api.nvim_win_set_width(win, math.max(1, width - amount))
    return
  end
  if dir == "right" then
    local right = vim.fn.winnr("l")
    if right ~= cur then
      target = right
    end
    local win = vim.fn.win_getid(target)
    local width = vim.api.nvim_win_get_width(win)
    vim.api.nvim_win_set_width(win, math.max(1, width - amount))
    return
  end
  if dir == "up" then
    local up = vim.fn.winnr("k")
    if up ~= cur then
      target = up
    end
    local win = vim.fn.win_getid(target)
    local height = vim.api.nvim_win_get_height(win)
    vim.api.nvim_win_set_height(win, math.max(1, height - amount))
    return
  end
  if dir == "down" then
    local down = vim.fn.winnr("j")
    if down ~= cur then
      target = down
    end
    local win = vim.fn.win_getid(target)
    local height = vim.api.nvim_win_get_height(win)
    vim.api.nvim_win_set_height(win, math.max(1, height - amount))
  end
end

vim.keymap.set("n", "<C-w><C-h>", function()
  resize_dir("left", 5)
end, { desc = "Resize split left" })
vim.keymap.set("n", "<C-w><C-l>", function()
  resize_dir("right", 5)
end, { desc = "Resize split right" })
vim.keymap.set("n", "<C-w><C-j>", function()
  resize_dir("down", 5)
end, { desc = "Resize split down" })
vim.keymap.set("n", "<C-w><C-k>", function()
  resize_dir("up", 5)
end, { desc = "Resize split up" })

-- Neotest (Go)
vim.keymap.set("n", "<leader>tr", function()
  require("neotest").run.run()
end, { desc = "Test: Run nearest" })
vim.keymap.set("n", "<leader>tf", function()
  require("neotest").run.run(vim.fn.expand("%"))
end, { desc = "Test: Run file" })
vim.keymap.set("n", "<leader>tS", function()
  require("neotest").summary.toggle()
end, { desc = "Test: Summary" })
vim.keymap.set("n", "<leader>to", function()
  require("neotest").output.open({ enter = true, auto_close = true })
end, { desc = "Test: Output" })
vim.keymap.set("n", "<leader>tO", function()
  require("neotest").output_panel.toggle()
end, { desc = "Test: Output panel" })
vim.keymap.set("n", "<leader>ts", function()
  require("neotest").run.stop()
end, { desc = "Test: Stop" })
