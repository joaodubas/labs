local opts = { noremap = true, silent = true }

-- Shorten keymap function
local keymap = vim.api.nvim_set_keymap

-- Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
-- * normal_mode = "n"
-- * insert_mode = "i"
-- * visual_mode = "v"
-- * visual_block_mode = "x"
-- * term_mode = "t"
-- * command_mode = "c"

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Nvimtree
keymap("n", "<leader>e", ":NvimTreeToggle<cr>", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<cr>", opts)
keymap("n", "<C-Down>", ":resize +2<cr>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<cr>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<cr>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<cr>", opts)
keymap("n", "<S-h>", ":bprevious<cr>", opts)

-- Move text up/down
keymap("n", "<A-j>", "<Esc>:m .+1<cr>==gi", opts)
keymap("n", "<A-k>", "<Esc>:m .-2<cr>==gi", opts)

-- Telescope
-- keymap("n", "<leader>f", "<cmd>Telescope find_files<cr>", opts)
keymap("n", "<leader>f", "<cmd>lua require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({ previewer = false }))<cr>", opts)
keymap("n", "<C-t>", "<cmd>Telescope live_grep<cr>", opts)

-- Git
keymap("n", "<leader>G", ":Git<cr>", opts)
keymap("n", "<leader>Gcc", "<cmd>GHCloseCommit<cr>", opts)
keymap("n", "<leader>Gce", "<cmd>GHExpandCommit<cr>", opts)
keymap("n", "<leader>Gco", "<cmd>GHOpenToCommit<cr>", opts)
keymap("n", "<leader>Gcp", "<cmd>GHPopOutCommit<cr>", opts)
keymap("n", "<leader>Gcz", "<cmd>GHCollapseCommit<cr>", opts)
keymap("n", "<leader>Gip", "<cmd>GHPreviewIssue<cr>", opts)
keymap("n", "<leader>Glt", "<cmd>LTPanel<cr>", opts)
keymap("n", "<leader>Grb", "<cmd>GHStartReview<cr>", opts)
keymap("n", "<leader>Grc", "<cmd>GHCloseReview<cr>", opts)
keymap("n", "<leader>Grd", "<cmd>GHDeleteReview<cr>", opts)
keymap("n", "<leader>Gre", "<cmd>GHExpandReview<cr>", opts)
keymap("n", "<leader>Grs", "<cmd>GHSubmitReview<cr>", opts)
keymap("n", "<leader>Grz", "<cmd>GHCollapseReview<cr>", opts)
keymap("n", "<leader>Gpc", "<cmd>GHClosePR<cr>", opts)
keymap("n", "<leader>Gpd", "<cmd>GHPRDetails<cr>", opts)
keymap("n", "<leader>Gpe", "<cmd>GHExpandPR<cr>", opts)
keymap("n", "<leader>Gpo", "<cmd>GHOpenPR<cr>", opts)
keymap("n", "<leader>Gpp", "<cmd>GHPopOutPR<cr>", opts)
keymap("n", "<leader>Gpr", "<cmd>GHRefreshPR<cr>", opts)
keymap("n", "<leader>Gpt", "<cmd>GHOpenToPR<cr>", opts)
keymap("n", "<leader>Gpz", "<cmd>GHCollapsePR<cr>", opts)
keymap("n", "<leader>Gtc", "<cmd>GHCreateThread<cr>", opts)
keymap("n", "<leader>Gtn", "<cmd>GHNextThread<cr>", opts)
keymap("n", "<leader>Gtt", "<cmd>GHToggleThread<cr>", opts)

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up/down
keymap("v", "<A-j>", ":m .+1<cr>==", opts)
keymap("v", "<A-k>", ":m .-2<cr>==", opts)
keymap("v", "p", '"_dP', opts)

-- Visual Block
-- Move text up/down
keymap("x", "J", ":move '>+1<cr>gv-gv", opts)
keymap("x", "K", ":move '<-2<cr>gv-gv", opts)
keymap("x", "<A-j>", ":move '>+1<cr>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<cr>gv-gv", opts)
