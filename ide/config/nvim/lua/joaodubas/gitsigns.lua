local status_ok, gitsigns = pcall(require, "gitsigns")
if not status_ok then
  return
end

gitsigns.setup {
  signs = {
    add = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
    change = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
    delete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
    topdelete = { hl = "GitSignsDelete", text = "契", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
    changedelete = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
  },
  signcolumn = true,
  numhl = false,
  linehl = false,
  word_diff = false,
  watch_gitdir = {
    interval = 1000,
    follow_files = true,
  },
  attach_to_untracked = true,
  current_line_blame = false,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = "eol",
    delay = 1000,
    ignore_whitespace = false,
  },
  current_line_blame_formatter_opts = {
    relative_time = false,
  },
  sign_priority = 6,
  update_debounce = 100,
  status_formatter = nil,
  max_file_length = 40000,
  preview_config = {
    border = "single",
    style = "minimal",
    relative = "cursor",
    row = 0,
    col = 1,
  },
  yadm = {
    enable = false,
  },
  on_attach = function(bufnr)
    local function map(mode, lhs, rhs, opts)
      opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})
      vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
    end

    -- navigation
    map("n", "]c", "&diff ? ']c' : '<cmd>Gitsigns next_hunk<cr>'", { expr = true })
    map("n", "[c", "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<cr>'", { expr = true })

    -- actions normal
    map("n", "<leader>hs", ":Gitsigns stage_hunk<cr>")
    map("n", "<leader>hr", ":Gitsigns reset_hunk<cr>")
    map("n", "<leader>hu", ":Gitsigns undo_stage_hunk<cr>")
    map("n", "<leader>hp", ":Gitsigns preview_hunk<cr>")
    map("n", "<leader>hd", ":Gitsigns diffthis<cr>")
    map("n", "<leader>hb", ":lua require'gitsigns'.blame_line{full=true}<cr>")
    map("n", "<leader>tb", ":Gitsigns toggle_current_line_blame<cr>")
    map("n", "<leader>hS", ":Gitsigns stage_buffer<cr>")
    map("n", "<leader>hR", ":Gitsigns reset_buffer<cr>")
    map("n", "<leader>hD", ":lua require'gitsigns'.diffthis('~')<cr>")

    -- actions visual
    map("v", "<leader>hs", ":Gitsigns stage_hunk<cr>")
    map("v", "<leader>hr", ":Gitsigns reset_hunk<cr>")
  end,
}
