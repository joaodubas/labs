local litee_status_ok, litee = pcall(require, "litee.lib")
if not litee_status_ok then
  return
end

local gh_status_ok, gh = pcall(require, "litee.gh")
if not gh_status_ok then
  return
end

litee.setup {
  icons = {},
  jumps = {},
  lsp = {},
  navi = {},
  notify = {
    enabled = true,
  },
  panel = {
    orientation = "left",
    panel_size = 30,
  },
  state = {},
  term = {
    position = "bottom",
    term_size = 15,
  },
  tree = {
    icon_set = "codicons",
    indent_guides = true,
  },
}

gh.setup {
  map_resize_keys = false,
  disable_keymaps = false,
  icon_set = "codicons",
  git_buffer_completion = true,
  keymaps = {
    open = "<cr>",
    expand = "zo",
    collapse = "zc",
    goto_issue = "gd",
    details = "d",
    submit_comment = "<C-s>",
    actions = "<C-a>",
    resolve_thread = "<C-r>",
    goto_web = "gx",
    select = "<leader>",
    clear_selection = "<leader><leader>",
    toggle_unread = "u",
  },
}
