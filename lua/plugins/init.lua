local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
        lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- ---------------------------------------------------------------------------
-- Workaround for https://github.com/nvim-treesitter/nvim-treesitter/issues/8618
-- Neovim 0.12's injection parsing can call vim.treesitter.get_node_text() on a
-- node whose range() is nil (markdown fenced code blocks trigger this via the
-- `set-lang-from-info-string!` directive), crashing the `conceal_line`
-- decoration provider on every redraw. Upstream closed it as "not planned",
-- so make get_node_text tolerate bad nodes instead of throwing.
-- Remove once fixed in Neovim core.
-- ---------------------------------------------------------------------------
do
    local orig_get_node_text = vim.treesitter.get_node_text
    vim.treesitter.get_node_text = function(node, source, opts)
        local ok, res = pcall(orig_get_node_text, node, source, opts)
        if ok then return res end
        return ""
    end
end

require("lazy").setup({
    -- Essentials
    "nvim-lua/plenary.nvim",

    { "folke/which-key.nvim",    config = true },
    { "nvim-tree/nvim-tree.lua", config = true },

    "nvim-telescope/telescope.nvim",

    -- Completion
    {
        "saghen/blink.cmp",
        version = "*",
        dependencies = { "rafamadriz/friendly-snippets" },
        opts = {
            keymap = { preset = "default" },
            appearance = {
                use_nvim_cmp_as_default = false,
                nerd_font_variant = "mono",
            },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 200 },
                menu = { draw = { treesitter = { "lsp" } } },
            },
            signature = { enabled = true },
        },
    },

    -- LSP Logic
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "saghen/blink.cmp",
            "b0o/schemastore.nvim",
        },
        config = function() require("plugins.lsp") end
    },

    -- Hover UI
    {
        "lewis6991/hover.nvim",
        config = function()
            require("hover").setup({
                init = function()
                    require("hover.providers.lsp")  -- LSP hover (main source)
                    require("hover.providers.man")  -- :Man pages
                end,
                preview_opts = {
                    border = "rounded",
                },
                preview_window = false, -- show inline float, not a split
                title = false,
                mouse_providers = { "LSP" },
                mouse_delay = 1000,
            })
        end,
    },

    -- Git
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                current_line_blame = false, -- toggle with <leader>gb
                current_line_blame_opts = {
                    delay = 300,
                    virt_text_pos = "eol",
                },
                signs = {
                    add          = { text = "▎" },
                    change       = { text = "▎" },
                    delete       = { text = "" },
                    topdelete    = { text = "" },
                    changedelete = { text = "▎" },
                },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local m = function(mode, l, r, desc)
                        vim.keymap.set(mode, l, r, { buffer = bufnr, silent = true, desc = desc })
                    end

                    -- Navigation
                    m("n", "]h", gs.next_hunk,  "Next Hunk")
                    m("n", "[h", gs.prev_hunk,  "Prev Hunk")

                    -- Actions
                    m("n", "<leader>gb", gs.toggle_current_line_blame, "Toggle Line Blame")
                    m("n", "<leader>gB", function() gs.blame_line({ full = true }) end, "Full Blame Popup")
                    m("n", "<leader>gp", gs.preview_hunk,              "Preview Hunk")
                    m("n", "<leader>gs", gs.stage_hunk,                "Stage Hunk")
                    m("n", "<leader>gr", gs.reset_hunk,                "Reset Hunk")
                    m("n", "<leader>gd", gs.diffthis,                  "Diff This")
                end,
            })
        end,
    },

    -- AI
    "github/copilot.vim",

    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "frappe",
                auto_integrations = true,
                integrations = {
                    native_lsp = {
                        enabled = true,
                        underlines = {
                            errors = { "undercurl" },
                            hints = { "undercurl" },
                            warnings = { "undercurl" },
                            information = { "undercurl" },
                        },
                    },
                },
            })
            vim.cmd.colorscheme("catppuccin-frappe")
            vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { fg = "#ff6b6b", italic = true })
            -- Hover float: distinct background so it stands out from the editor
            vim.api.nvim_set_hl(0, "NormalFloat",  { bg = "#51576d", fg = "#c6d0f5" })
            vim.api.nvim_set_hl(0, "FloatBorder",  { bg = "#51576d", fg = "#8caaee" })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        build = ":TSUpdate",
        config = function()
            local status_ok, configs = pcall(require, "nvim-treesitter.configs")
            if not status_ok then return end

            configs.setup({
                ensure_installed = { "go", "lua", "vim", "vimdoc", "markdown" },
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
            })
        end,
    },
})
