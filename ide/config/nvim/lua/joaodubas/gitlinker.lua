local status_ok, gitlinker = pcall(require, "gitlinker")
if not status_ok then
  return
end

local actions = require "gitlinker.actions"
local hosts = require "gitlinker.hosts"

gitlinker.setup {
  opts = {
    remote = "origin",
    add_current_line_on_normal_mode = true,
    action_callback = actions.copy_to_clipboard,
    print_url = true,
  },
  callbacks = {
    ["github.com"] = hosts.get_github_type_url,
    ["bitbucket.org"] = hosts.get_bitbucket_type_url,
    ["gitea.dubas.dev"] = hosts.get_gitea_type_url,
  },
  mappings = "<leader>gy"
}
