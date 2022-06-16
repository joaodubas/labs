local status_ok, iron = pcall(require, "iron.core")
if not status_ok then
  return
end

iron.setup {
  config = {
    should_map_plug = false,
    scratch_repl = true,
    repl_definition = {
      sh = { command = { "zsh" } },
      py = { command = { "python" } },
      ex = { command = { "iex" } },
    },
  },
  keymaps = {

  },
}
