local status_ok, octo = pcall(require, "octo")
if not status_ok then
  return
end

octo.setup {
  default_remote = { "origin", "upstream" },
  ssh_aliases = { ["github"] = "github.com" },
  reaction_viewer_hint_icon = "",
  user_icon = " ",
  timeline_marker = "",
  timeline_indent = "2",
  right_bubble_delimiter = "",
  left_bubble_delimiter = "",
  snippet_context_lines = 10,
  file_panel = {
    size = 10,
    use_icons = true,
  },
  mappings = {
    file_panel = {
      next_entry = { lhs = "j", desc = "move to next changed file" },
      prev_entry = { lhs = "k", desc = "move to previous changed file" },
      select_entry = { lhs = "<cr>", desc = "show selected changed file diffs" },
      refresh_files = { lhs = "R", desc = "refresh changed files panel" },
      focus_files = { lhs = "<leader>e", desc = "move focus to changed file panel" },
      toggle_files = { lhs = "<leader>b", desc = "hide/show changed files panel" },
      select_next_entry = { lhs = "]q", desc = "move to next changed file" },
      select_pref_entry = { lhs = "[q", desc = "move to previous changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      toggle_viewed = { lhs = "<leader><space>", dec = "toggle viewer viewed state" },
    },
  },
}
