# Contributing

Thank you for your interest in improving this config. Contributions are welcome — whether that means adding a new language integration, refining an existing one, fixing a bug, or improving documentation.

---

## Table of Contents

- [How the Config Is Organized](#how-the-config-is-organized)
- [Adding a Language Integration](#adding-a-language-integration)
  - [1. Register the server with Mason](#1-register-the-server-with-mason)
  - [2. Enable the server](#2-enable-the-server)
  - [3. Format on save](#3-format-on-save)
  - [4. Organize imports on save](#4-organize-imports-on-save)
  - [Full example: Rust](#full-example-rust)
- [Adding a Plugin](#adding-a-plugin)
- [Code Style](#code-style)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)

---

## How the Config Is Organized

```
lua/
├── core/
│   ├── init.lua       # vim.opt settings — tabs, numbers, clipboard, etc.
│   └── keymaps.lua    # Global keymaps (explorer, telescope)
└── plugins/
    ├── init.lua       # lazy.nvim setup + every plugin spec
    └── lsp.lua        # Mason, server configuration, on-attach, format-on-save
```

The intentional constraint is **two files own all language logic**:

- `lua/plugins/lsp.lua` — servers, capabilities, format, organize-imports
- `lua/plugins/init.lua` — everything else (completion, UI, git, treesitter)

This makes language additions predictable: you know exactly where to look and what to change.

---

## Adding a Language Integration

All language work lives in `lua/plugins/lsp.lua`. Below is the exact sequence.

### 1. Register the server with Mason

Find the `ensure_installed` table and add the [Mason package name](https://mason-registry.dev/registry/list):

```lua
-- lua/plugins/lsp.lua
require("mason-lspconfig").setup({
    ensure_installed = {
        "lua_ls",
        "gopls",
        "pyright",
        "vtsls",
        -- add here, e.g.:
        "rust_analyzer",
    },
})
```

Mason will auto-install the server on the next Neovim launch.

### 2. Enable the server

Below the `mason-lspconfig.setup()` block, call `vim.lsp.enable()` with any settings the server needs:

```lua
vim.lsp.enable("rust_analyzer", {
    settings = {
        ["rust-analyzer"] = {
            checkOnSave = { command = "clippy" },
            cargo      = { allFeatures = true },
        },
    },
})
```

`vim.lsp.enable()` is the Neovim 0.12 native API. No lspconfig wrapper needed. Capabilities (blink.cmp) are already broadcast to all servers via the `vim.lsp.config("*", …)` call at the top of the file.

### 3. Format on save

The existing `BufWritePre` autocmd covers the listed extensions. Add yours to the `pattern` table:

```lua
-- lua/plugins/lsp.lua  (around line 129)
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = {
        "*.go", "*.py", "*.lua", "*.tf",
        "*.js", "*.jsx", "*.ts", "*.tsx",
        "*.feature", "*.json",
        "*.rs",    -- add your extension here
    },
    callback = function() … end,
})
```

The callback already calls `vim.lsp.buf.format()` for every matched filetype, so no further changes are needed unless you need custom pre-format logic.

### 4. Organize imports on save

If the server supports `source.organizeImports`, add the filetype to the `import_fts` table inside the same callback:

```lua
-- lua/plugins/lsp.lua  (around line 137)
local import_fts = {
    go             = true,
    python         = true,
    javascript     = true,
    typescript     = true,
    javascriptreact = true,
    typescriptreact = true,
    rust           = true,  -- add here
}
```

The code-action call is already wired — adding the key is all that is required.

### Full example: Rust

The complete diff for adding Rust (`rust_analyzer`) is minimal:

```lua
-- 1. mason-lspconfig ensure_installed
"rust_analyzer",

-- 2. vim.lsp.enable
vim.lsp.enable("rust_analyzer", {
    settings = {
        ["rust-analyzer"] = {
            checkOnSave = { command = "clippy" },
        },
    },
})

-- 3. BufWritePre pattern (add "*.rs")
pattern = { …existing…, "*.rs" },

-- 4. import_fts (rust_analyzer does not ship organizeImports, so skip this step)
```

**Treesitter grammar** — if you want syntax highlighting for the new language, add the parser name to `lua/plugins/init.lua`:

```lua
configs.setup({
    ensure_installed = { "go", "lua", "vim", "vimdoc", "markdown", "rust" },
    …
})
```

---

## Adding a Plugin

All plugin specs live in `lua/plugins/init.lua` inside the `require("lazy").setup({ … })` call.

Lazy.nvim accepts any valid spec shape. A minimal example:

```lua
-- Simple plugin with no config
"tpope/vim-fugitive",

-- Plugin with options table
{
    "folke/trouble.nvim",
    opts = { use_diagnostic_signs = true },
},

-- Plugin with a full config function
{
    "someone/something.nvim",
    event = "BufReadPost",        -- lazy-load trigger
    config = function()
        require("something").setup({ … })
        -- keymaps can go here or in lua/core/keymaps.lua
    end,
},
```

If the plugin adds keymaps used globally, put them in `lua/core/keymaps.lua` so they are all in one place. If the keymaps only make sense when the plugin is loaded (e.g. buffer-local LSP maps), keep them inside the plugin's `config` or inside the `LspAttach` callback in `lsp.lua`.

---

## Code Style

- **Indentation:** 4 spaces (matches `opt.shiftwidth = 4` in `core/init.lua`). No tabs.
- **Quotes:** single quotes for strings in Lua unless the string contains a single quote.
- **Line length:** keep lines under ~100 characters where reasonable.
- **Comments:** use `--` line comments. Block comments (`--[[ ]]`) only for temporarily disabling code.
- **Section headers:** use the existing banner style for logical sections in `lsp.lua`:
  ```lua
  -- ============================== --
  -- N. SECTION NAME
  -- ============================== --
  ```
- **No unused variables:** Lua does not warn by default but `lua_ls` will. Keep the config clean.
- **Require at call site:** for plugins that should lazy-load, `require` inside a callback rather than at the top of the file (see the Telescope keymaps in `keymaps.lua` for the pattern).

---

## Submitting Changes

1. Fork the repository and create a branch from `main`:
   ```bash
   git checkout -b feat/rust-integration
   ```

2. Make your changes following the patterns described above.

3. Test locally:
   - Open Neovim fresh (`nvim --clean -u ~/.config/nvim/init.lua` or just `nvim`).
   - Run `:checkhealth` — no errors in the `vim.lsp` or `mason` sections.
   - Verify the server starts for a file of the relevant type (`:LspInfo`).
   - Verify format-on-save fires (save a dirty file and check it changes).

4. Open a pull request with a short description of what was added and why.

**Pull request checklist:**

- [ ] Server added to `ensure_installed`
- [ ] `vim.lsp.enable()` call added with any required settings
- [ ] Format-on-save pattern updated (if applicable)
- [ ] Organize-imports filetype added (if the server supports it)
- [ ] Treesitter grammar added (if applicable)
- [ ] README language table updated
- [ ] No leftover debug prints or commented-out code

---

## Reporting Issues

Open a [GitHub issue](https://github.com/camilacremoneze/neovim-configs/issues) and include:

- Neovim version (`nvim --version`)
- OS and terminal
- Output of `:checkhealth vim.lsp` and `:LspInfo`
- Steps to reproduce
