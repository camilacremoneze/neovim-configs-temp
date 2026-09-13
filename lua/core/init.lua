vim.g.mapleader = " "

local opt = vim.opt
vim.opt.mouse = "a"
vim.opt.mousemodel = "extend"
opt.clipboard = "unnamedplus"
vim.opt.showmode = true


opt.number = true
opt.relativenumber = false
opt.shiftwidth = 4
opt.tabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.termguicolors = true

require("core.keymaps")
