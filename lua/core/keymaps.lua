local keymap = vim.keymap.set

-- General
keymap("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Explorer" })

-- Telescope (lazy-loaded: require inside the callback to avoid loading at startup)
keymap("n", "<leader>ff", function() require("telescope.builtin").find_files() end, { desc = "Find Files" })
keymap("n", "<leader>fg", function() require("telescope.builtin").live_grep() end, { desc = "Live Grep" })
keymap("n", "<leader>fb", function() require("telescope.builtin").buffers() end, { desc = "Buffers" })
keymap("n", "<leader>fh", function() require("telescope.builtin").help_tags() end, { desc = "Help Tags" })
