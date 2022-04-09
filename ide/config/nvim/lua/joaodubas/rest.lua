local status_ok, rest = pcall(require, "rest-nvim")
if not status_ok then
  return
end

rest.setup {
  result_split_horizontal = false,
  skip_ssl_verification = false,
  highlight = {
    enabled = true,
    timeout = 150,
  },
  result = {
    show_url = true,
    show_http_info = true,
    show_headers = true,
  },
  jump_to_request = false,
  env_file = ".env",
  custom_dynamic_variables = {},
  yank_dry_run = true,
}
