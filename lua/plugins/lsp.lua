-- lua/plugins/lsp.lua

-- ========================================================================== --
-- 0. BLINK.CMP CAPABILITIES (must run before any server is started)
-- ========================================================================== --
local capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
    capabilities = blink.get_lsp_capabilities(capabilities)
end

-- Broadcast enhanced capabilities to every server via the global config wildcard
vim.lsp.config("*", { capabilities = capabilities })

require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        "lua_ls",
        "gopls",
        "jsonls",
        "pyright",
        "terraformls",
        "vtsls",                    -- Optimized JS/TS/React (replaces tsserver)
        "cucumber_language_server", -- Cucumber/Gherkin
        "golangci_lint_ls",         -- Go linter LSP wrapper
    },
})

-- Ensure the golangci-lint binary itself is installed (golangci_lint_ls only
-- provides the LSP wrapper, not the linter binary it shells out to).
do
    local registry_ok, registry = pcall(require, "mason-registry")
    if registry_ok then
        registry.refresh(function()
            if registry.has_package("golangci-lint") then
                local pkg = registry.get_package("golangci-lint")
                if not pkg:is_installed() then
                    pkg:install()
                end
            end
        end)
    end
end

-- ========================================================================== --
-- 1. GLOBAL LSP ATTACH (Keymaps & Lag Fix)
-- ========================================================================== --
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        local bufnr = ev.buf
        local client = vim.lsp.get_client_by_id(ev.data.client_id)

        -- FIX LAG: Disable Semantic Tokens
        if client then
            client.server_capabilities.semanticTokensProvider = nil
        end

        local opts = function(desc) return { silent = true, buffer = bufnr, desc = desc } end
        local m = vim.keymap.set

        m("n", "gD", vim.lsp.buf.declaration, opts("Go to Declaration"))
        m("n", "gd", vim.lsp.buf.definition, opts("Go to Definition"))
        m("n", "K",  require("hover").hover,         opts("Hover Docs"))
        m("n", "gK", require("hover").hover_select,   opts("Hover Select Provider"))
        m("n", "gI", vim.lsp.buf.implementation, opts("Go to Implementation"))
        m("n", "gr", function()
            vim.lsp.buf.references()
            -- After references populate the quickfix, close it on jump
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "qf",
                once = true,
                callback = function(e)
                    vim.keymap.set("n", "<CR>", function()
                        local line = vim.api.nvim_win_get_cursor(0)
                        local entry = vim.fn.getqflist()[line[1]]
                        vim.cmd("cclose")
                        if entry and entry.bufnr and entry.bufnr > 0 then
                            vim.api.nvim_set_current_buf(entry.bufnr)
                            vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col - 1 })
                        end
                    end, { buffer = e.buf, silent = true })
                end,
            })
        end, opts("References"))
        m("n", "gl", vim.diagnostic.open_float, opts("Line Diagnostics"))
        m("n", "<leader>la", vim.lsp.buf.code_action, opts("Code Action"))
        m("n", "<leader>lr", vim.lsp.buf.rename, opts("Rename"))
        m("n", "<leader>lf", function() vim.lsp.buf.format({ async = true }) end, opts("Format"))
    end,
})

-- ========================================================================== --
-- 2. NATIVE LSP ENABLE (The 0.12 Way)
-- ========================================================================== --
if vim.lsp.config then
    vim.lsp.enable("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim" } } } } })
    vim.lsp.enable("gopls", { settings = { gopls = { gofumpt = true } } })
    vim.lsp.enable("pyright")
    vim.lsp.enable("terraformls")
    vim.lsp.enable("jsonls", {
        settings = {
            json = {
                schemas = require("schemastore").json.schemas(),
                validate = { enable = true },
            },
        },
    })
    vim.lsp.enable("vtsls", {
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    })

    vim.lsp.enable("cucumber_language_server", {
        filetypes = { "feature" },
        settings = {
            cucumber = {
                features = { "**/*.feature" },
                glue     = { "**/*.js", "**/*.ts" },
            },
        },
    })
end

-- ========================================================================== --
-- 3. CLEAN GOPLS HOVER (strip type signature, show only doc text)
-- ========================================================================== --
local orig_hover = vim.lsp.handlers["textDocument/hover"]
vim.lsp.handlers["textDocument/hover"] = function(err, result, ctx, config)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    if client and client.name == "gopls" and result and result.contents then
        local content = result.contents
        local raw = type(content) == "table" and (content.value or "") or tostring(content)
        -- Drop the type signature block; keep only the doc comment after the first blank line
        local doc = raw:match("\n\n(.*)")
        if doc and doc ~= "" then
            result.contents = { kind = "markdown", value = doc }
        end
    end
    orig_hover(err, result, ctx, config)
end

-- ========================================================================== --
-- 4. MULTI-LANGUAGE AUTO-FORMAT (With Cursor Pinning)
-- ========================================================================== --
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.go", "*.py", "*.lua", "*.tf", "*.js", "*.jsx", "*.ts", "*.tsx", "*.feature", "*.json" },
    callback = function()
        local view  = vim.fn.winsaveview()
        local bufnr = vim.api.nvim_get_current_buf()
        local ft    = vim.bo.filetype

        -- A. ORGANIZE IMPORTS (Go, Python, JS/TS/React)
        if vim.lsp.config then
            local import_fts = { go = true, python = true, javascript = true, typescript = true, javascriptreact = true, typescriptreact = true }

            if import_fts[ft] then
                local params = vim.lsp.util.make_range_params()
                params.context = { only = { "source.organizeImports" } }
                local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 500)
                for _, res in pairs(result or {}) do
                    for _, r in pairs(res.result or {}) do
                        if r.edit then
                            vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
                        elseif r.command then
                            vim.lsp.buf.execute_command(r.command)
                        end
                    end
                end
            end
        end

        -- B. UNIVERSAL FORMAT
        vim.lsp.buf.format({ async = false, timeout_ms = 500 })
        vim.fn.winrestview(view)
    end,
})
