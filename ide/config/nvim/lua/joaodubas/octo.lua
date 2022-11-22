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
    issue = {
      close_issue = { lhs = "<leader>Gic", desc = "close issue" },
      reopen_issue = { lhs = "<leader>Gio", desc = "reopen issue" },
      list_issues = { lhs = "<leader>Gil", desc = "list open issues on same repo" },
      goto_issue = { lhs = "<leader>Gig", desc = "navigate to a local repo issue" },
      reload = { lhs = "<C-r>", desc = "reload issue" },
      copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
      add_assignee = { lhs = "<leader>Gaa", desc = "add assignee" },
      remove_assignee = { lhs = "<leader>Gar", desc = "remove assignee" },
      create_label = { lhs = "<leader>Glc", desc = "create label" },
      add_label = { lhs = "<leader>Gla", desc = "add label" },
      remove_label = { lhs = "<leader>Glr", desc = "remove label" },
      add_comment = { lhs = "<leader>Gca", desc = "add comment" },
      delete_comment = { lhs = "<leader>Gcr", desc = "delete comment" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      react_hooray = { lhs = "<leader>Grp", desc = "add/remove 🎉 reaction" },
      react_heart = { lhs = "<leader>Grh", desc = "add/remove ❤️ reaction" },
      react_eyes = { lhs = "<leader>Gre", desc = "add/remove 👀 reaction" },
      react_thumbs_up = { lhs = "<leader>Gr+", desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "<leader>Gr-", desc = "add/remove 👎 reaction" },
      react_rocket = { lhs = "<leader>Grr", desc = "add/remove 🚀 reaction" },
      react_laugh = { lhs = "<leader>Grl", desc = "add/remove 😄 reaction" },
      react_confused = { lhs = "<leader>Grc", desc = "add/remove 😕 reaction" },
    },
    pull_request = {
      checkout_pr = { lhs = "<leader>Gpc", desc = "checkout PR" },
      merge_pr = { lhs = "<leader>Gpm", desc = "merge commit PR" },
      squash_and_merge_pr = { lhs = "<leader>Gpsm", desc = "squash and merge PR" },
      list_commits = { lhs = "<leader>Gpl", desc = "list PR commits" },
      list_changed_files = { lhs = "<leader>Gpf", desc = "list PR changed fileds" },
      show_pr_diff = { lhs = "<leader>Gpd", desc = "show PR diff" },
      add_reviewer = { lhs = "<leader>Gra", desc = "add reviewer" },
      remove_reviewer = { lhs = "<leader>Grr", desc = "remove reviwer request" },
      close_issue = { lhs = "<leader>Gic", desc = "close PR" },
      reopen_issue = { lhs = "<leader>Gio", desc = "reopen PR" },
      list_issues = { lhs = "<leader>Gil", desc = "list open issues on same repo" },
      goto_issue = { lhs = "<leader>Gig", desc = "navigate to a local repo issue" },
      reload = { lhs = "<C-r>", desc = "reload PR" },
      copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
      goto_file = { lhs = "Ggf", desc = "go to file" },
      add_assignee = { lhs = "<leader>Gaa", desc = "add assignee" },
      remove_assignee = { lhs = "<leader>Gad", desc = "remove assignee" },
      create_label = { lhs = "<leader>Glc", desc = "create label" },
      add_label = { lhs = "<leader>Gla", desc = "add label" },
      remove_label = { lhs = "<leader>Gld", desc = "remove label" },
      add_comment = { lhs = "<leader>Gca", desc = "add comment" },
      delete_comment = { lhs = "<leader>Gcr", desc = "delete comment" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      react_hooray = { lhs = "<leader>Grp", desc = "add/remove 🎉 reaction" },
      react_heart = { lhs = "<leader>Grh", desc = "add/remove ❤️ reaction" },
      react_eyes = { lhs = "<leader>Gre", desc = "add/remove 👀 reaction" },
      react_thumbs_up = { lhs = "<leader>Gr+", desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "<leader>Gr-", desc = "add/remove 👎 reaction" },
      react_rocket = { lhs = "<leader>Grr", desc = "add/remove 🚀 reaction" },
      react_laugh = { lhs = "<leader>Grl", desc = "add/remove 😄 reaction" },
      react_confused = { lhs = "<leader>Grc", desc = "add/remove 😕 reaction" },
    },
    review_thread = {
      goto_issue = { lhs = "<leader>Ggi", desc = "navigate to a local repo issue" },
      add_comment = { lhs = "<leader>Gca", desc = "add comment" },
      delete_comment = { lhs = "<leader>Gcr", desc = "delete comment" },
      add_suggestion = { lhs = "<leader>Gsa", desc = "add suggestion" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
      select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      react_hooray = { lhs = "<leader>Grp", desc = "add/remove 🎉 reaction" },
      react_heart = { lhs = "<leader>Grh", desc = "add/remove ❤️ reaction" },
      react_eyes = { lhs = "<leader>Gre", desc = "add/remove 👀 reaction" },
      react_thumbs_up = { lhs = "<leader>Gr+", desc = "add/remove 👍 reaction" },
      react_thumbs_down = { lhs = "<leader>Gr-", desc = "add/remove 👎 reaction" },
      react_rocket = { lhs = "<leader>Grr", desc = "add/remove 🚀 reaction" },
      react_laugh = { lhs = "<leader>Grl", desc = "add/remove 😄 reaction" },
      react_confused = { lhs = "<leader>Grc", desc = "add/remove 😕 reaction" },
    },
    review_diff = {
      add_review_comment = { lhs = "<leader>Gca", desc = "add a new review comment" },
      add_review_suggestion = { lhs = "<leader>Gsa", desc = "add a new review suggestion" },
      focus_files = { lhs = "<leader>e", desc = "move focus to changed file panel" },
      toggle_files = { lhs = "<leader>b", desc = "hide/show changed files panel" },
      next_thread = { lhs = "]t", desc = "move to next thread" },
      prev_thread = { lhs = "[t", desc = "move to previous thread" },
      select_next_entry = { lhs = "]q", desc = "move to previous changed file" },
      select_prev_entry = { lhs = "[q", desc = "move to next changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      toggle_viewed = { lhs = "<leader><leader>", desc = "toggle viewer viewed state" },
    },
    submit_win = {
      approve_review = { lhs = "<C-a>", desc = "approve review" },
      comment_review = { lhs = "<C-m>", desc = "comment review" },
      request_changes = { lhs = "<C-r>", desc = "request changes review" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
    },
  },
}