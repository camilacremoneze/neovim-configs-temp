# neovim-configs

Minimal, modern Neovim configuration targeting **Neovim 0.12+**. Built around the native LSP API (no lspconfig wrapper), [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management, [Mason](https://github.com/williamboman/mason.nvim) for automatic server installation, and [blink.cmp](https://github.com/saghen/blink.cmp) for completion.

Designed to be a clean, merchandisable base: batteries-included for Python, Go, JavaScript/React, and Lua — and straightforward to extend with new languages.

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Nerd Font Setup](#nerd-font-setup)
- [Language Integrations](#language-integrations)
  - [Python](#python)
  - [Go](#go)
  - [JavaScript & React](#javascript--react)
  - [Lua](#lua)
  - [Adding a New Language](#adding-a-new-language)
- [Code Formatting](#code-formatting)
- [Plugins](#plugins)
- [Keymaps](#keymaps)
- [Contributing](#contributing)
- [License](#license)

---

## Requirements

| Dependency | Version | Notes |
|---|---|---|
| Neovim | >= 0.12 | Native LSP API (`vim.lsp.enable`) required |
| [Nerd Font](https://www.nerdfonts.com/) | any | Icons in nvim-tree, gitsigns, blink.cmp |
| Node.js | >= 18 | `vtsls`, `cucumber_language_server` |
| Go toolchain | >= 1.21 | `gopls` |
| Python | >= 3.9 | `pyright` |
| git | any | lazy.nvim bootstrap |

---

## Installation

```bash
# Back up existing config (if any)
mv ~/.config/nvim ~/.config/nvim.bak

# Clone
git clone https://github.com/camilacremoneze/neovim-configs.git ~/.config/nvim

# Open Neovim — lazy.nvim bootstraps itself, then installs all plugins
nvim
```

On first launch Mason auto-installs every LSP server listed in `ensure_installed`. You can watch progress with `:Mason`.

---

## Nerd Font Setup

Icons in nvim-tree, gitsigns, blink.cmp, and the statusline require a [Nerd Font](https://www.nerdfonts.com/) installed **and** configured in your terminal emulator — Neovim itself cannot render glyphs your terminal font doesn't have.

1. **Install a Nerd Font**

   ```bash
   # macOS
   brew tap homebrew/cask-fonts
   brew install --cask font-jetbrains-mono-nerd-font

   # or download manually from https://www.nerdfonts.com/font-downloads
   ```

2. **Set it as your terminal's font**

   | Terminal | How |
   |---|---|
   | iTerm2 | Preferences → Profiles → Text → Font → select `JetBrainsMono Nerd Font` |
   | Alacritty | `font.normal.family = "JetBrainsMono Nerd Font"` in `alacritty.toml` |
   | Kitty | `font_family JetBrainsMono Nerd Font` in `kitty.conf` |
   | WezTerm | `config.font = wezterm.font("JetBrainsMono Nerd Font")` in `wezterm.lua` |
   | VS Code integrated terminal | `"terminal.integrated.fontFamily": "JetBrainsMono Nerd Font"` in `settings.json` |

3. **Restart the terminal** and reopen Neovim — icons should render correctly in nvim-tree, gitsigns, and completion menus.

If icons still show as boxes/question marks, verify the font is actually applied (not just installed) and that your terminal isn't overriding it per-profile.

---

## Language Integrations

All language servers are installed automatically by Mason on first launch.

### Python

| Item | Detail |
|---|---|
| Server | `pyright` |
| Formatter | `pyright` (via LSP format) |
| Organize imports | `source.organizeImports` on save |
| Format on save | yes — `*.py` |

`pyright` is enabled with zero extra settings. Override in `lua/plugins/lsp.lua`:

```lua
vim.lsp.enable("pyright", {
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "strict",   -- "off" | "basic" | "strict"
                autoImportCompletions = true,
            },
        },
    },
})
```

### Go

| Item | Detail |
|---|---|
| Server | `gopls` |
| Formatter | `gofumpt` (stricter gofmt, via gopls) |
| Organize imports | `source.organizeImports` on save |
| Format on save | yes — `*.go` |

Current settings in `lua/plugins/lsp.lua:81`:

```lua
vim.lsp.enable("gopls", {
    settings = {
        gopls = {
            gofumpt = true,   -- stricter formatting
        },
    },
})
```

`gofumpt` must be installed: `go install mvdan.cc/gofumpt@latest`.

### JavaScript & React

| Item | Detail |
|---|---|
| Server | `vtsls` (replaces `tsserver`) |
| Filetypes | `javascript`, `javascriptreact`, `typescript`, `typescriptreact` |
| Formatter | vtsls built-in |
| Organize imports | `source.organizeImports` on save |
| Format on save | yes — `*.js` `*.jsx` `*.ts` `*.tsx` |
| Gherkin/Cucumber | `cucumber_language_server` for `*.feature` files |

`vtsls` requires a `tsconfig.json` or `jsconfig.json` at the project root for full accuracy.

### Lua

| Item | Detail |
|---|---|
| Server | `lua_ls` |
| Formatter | `lua_ls` built-in |
| Format on save | yes — `*.lua` |
| Neovim globals | `vim` recognized — no false diagnostics |

Settings in `lua/plugins/lsp.lua:80`:

```lua
vim.lsp.enable("lua_ls", {
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
        },
    },
})
```

### Adding a New Language

Three steps, all in `lua/plugins/lsp.lua`:

**Step 1 — register the server with Mason**

```lua
require("mason-lspconfig").setup({
    ensure_installed = {
        -- existing servers …
        "rust_analyzer",   -- add the Mason server name
    },
})
```

**Step 2 — enable the server**

```lua
vim.lsp.enable("rust_analyzer", {
    settings = {
        ["rust-analyzer"] = {
            checkOnSave = { command = "clippy" },
        },
    },
})
```

**Step 3 — opt in to format-on-save** (if you want it)

```lua
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.rs" },   -- add your file extension
    -- the existing callback already calls vim.lsp.buf.format()
    -- so extending the pattern table in the existing autocmd is enough:
})
```

In practice just add `"*.rs"` to the existing `pattern` table in the `BufWritePre` autocmd at `lua/plugins/lsp.lua:129`.

For **organize-imports** support add your filetype to the `import_fts` table at `lua/plugins/lsp.lua:137`:

```lua
local import_fts = {
    go = true, python = true,
    javascript = true, typescript = true,
    javascriptreact = true, typescriptreact = true,
    rust = true,   -- add here
}
```

That's it. No other files need to be modified.

---

## Code Formatting

Format on save is active for every supported language. It runs two steps in order:

1. **Organize imports** — fires a `source.organizeImports` code-action synchronously (Go, Python, JS, TS, JSX, TSX).
2. **LSP format** — calls `vim.lsp.buf.format()` synchronously before the buffer is written.

The cursor position is pinned with `winsaveview` / `winrestview` so it does not jump after formatting.

**Covered file types:**

| Extension | Formatter | Organize Imports |
|---|---|---|
| `*.go` | gopls / gofumpt | yes |
| `*.py` | pyright | yes |
| `*.lua` | lua_ls | no |
| `*.js` `*.jsx` | vtsls | yes |
| `*.ts` `*.tsx` | vtsls | yes |
| `*.json` | jsonls + SchemaStore | no |
| `*.tf` | terraformls | no |
| `*.feature` | cucumber_language_server | no |

**Manual format:** `<leader>lf` — formats the current buffer on demand.

**Disable format-on-save** for a single filetype by removing its pattern from the `BufWritePre` autocmd in `lua/plugins/lsp.lua:129`.

---

## Plugins

| Plugin | Purpose |
|---|---|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager with lock file |
| [mason.nvim](https://github.com/williamboman/mason.nvim) | LSP / linter / formatter installer |
| [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) | Bridges Mason with Neovim LSP |
| [blink.cmp](https://github.com/saghen/blink.cmp) | Completion + signature help |
| [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | Community snippet collection |
| [schemastore.nvim](https://github.com/b0o/schemastore.nvim) | JSON schema validation |
| [hover.nvim](https://github.com/lewis6991/hover.nvim) | Hover float UI (`K`) |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git hunk signs + inline blame |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder |
| [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) | File explorer sidebar |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting + indent |
| [catppuccin](https://github.com/catppuccin/nvim) | Colorscheme (Frappé flavour) |
| [copilot.vim](https://github.com/github/copilot.vim) | GitHub Copilot inline suggestions |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keymap hint popup |

---

## Keymaps

Leader key: `<Space>`

### LSP

| Key | Action |
|---|---|
| `gd` | Go to Definition |
| `gD` | Go to Declaration |
| `gI` | Go to Implementation |
| `gr` | References (quickfix — `<CR>` to jump & close) |
| `K` | Hover docs |
| `gK` | Select hover provider |
| `gl` | Line diagnostics (float) |
| `<leader>la` | Code action |
| `<leader>lr` | Rename symbol |
| `<leader>lf` | Format buffer |

### Git

| Key | Action |
|---|---|
| `]h` | Next hunk |
| `[h` | Prev hunk |
| `<leader>gb` | Toggle inline line blame |
| `<leader>gB` | Full blame popup |
| `<leader>gp` | Preview hunk |
| `<leader>gs` | Stage hunk |
| `<leader>gr` | Reset hunk |
| `<leader>gd` | Diff this |

### Finder

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fh` | Help tags |

### Explorer

| Key | Action |
|---|---|
| `<leader>e` | Toggle file explorer |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add languages, plugins, or improve existing integrations.

---

## License

[MIT](LICENSE)
