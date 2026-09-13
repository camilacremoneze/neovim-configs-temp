-- Add Mason to PATH immediately
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. ":" .. vim.env.PATH

require("plugins") -- Loads lua/plugins/init.lua
require("core")    -- Loads lua/core/init.lua
