-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'mgoral/vim-bw',
    url = 'https://git.goral.net.pl/mgoral/vim-bw.git',
    priority = 1000,
    config = function ()
      vim.cmd.colorscheme 'bw-onedark'
    end
  },
  {
    'joaodubas/gitlinker.nvim',
    config = function ()
      local actions = require('gitlinker.actions')
      local hosts = require('gitlinker.hosts')
      require('gitlinker').setup({
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
      })
    end
  },
  'nvim-treesitter/nvim-treesitter-context',
  {
    'kevinhwang91/nvim-ufo',
    dependencies = { 'kevinhwang91/promise-async' },
    event = 'BufRead',
    keys = function ()
      local ufo = require('ufo')
      return {
        { 'zR', ufo.openAllFolds, { desc = "Open all folds" } },
        { 'zM', ufo.closeAllFolds, { desc = "Close all folds" } },
        { 'zr', ufo.openFoldsExceptKinds, { desc = "Open fold" } },
        { 'zm', ufo.closeFoldsWith, { desc = "Close fold" } },
      }
    end,
    opts = function ()
      local handler = function (virtText, lnum, endLnum, width, truncate)
        local newVirtText = {}
        local suffix = (' 󰁂 %d '):format(endLnum - lnum)
        local sufWidth = vim.fn.strdisplaywidth(suffix)
        local targetWidth = width - sufWidth
        local curWidth = 0
        for _, chunk in ipairs(virtText) do
          local chunkText = chunk[1]
          local chunkWidth = vim.fn.strdisplaywidth(chunkText)
          if targetWidth > curWidth + chunkWidth then
            table.insert(newVirtText, chunk)
          else
            chunkText = truncate(chunkText, targetWidth - curWidth)
            local hlGroup = chunk[2]
            table.insert(newVirtText, {chunkText, hlGroup})
            chunkWidth = vim.fn.strdisplaywidth(chunkText)
            -- str width returned from truncate() may less than 2nd argument, need padding
            if curWidth + chunkWidth < targetWidth then
                suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
            end
            break
          end
          curWidth = curWidth + chunkWidth
        end
        table.insert(newVirtText, { suffix, 'MoreMsg' })
        return newVirtText
      end

      return {
        fold_virt_text_handler = handler,
        provider_selector = function (_, _, _)
          return { 'treesitter', 'indent' }
        end
      }
    end,
  },
  {
    'stevearc/oil.nvim',
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { '-', '<cmd>Oil<cr>', desc = "Open parent directory" },
    },
    opts = {},
  },
  {
    'rest-nvim/rest.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ft = {
      'http',
      'rest'
    },
    opts = {
      result_split_horizontal = false,
      result_split_in_place = false,
      skip_ssl_verification = false,
      encode_url = true,
      highlight = {
        enabled = true,
        timeout = 15
      },
      result = {
        show_url = true,
        show_curl_command = true,
        show_http_info = true,
        show_headers = true,
        formatters = {
          json = 'jq',
          html = false
        },
        jump_to_request = true,
        env_file = '.env',
        custom_dynamic_variables = { },
        yank_dry_run = true
      }
    },
    keys = function ()
      local status_ok, which_key = pcall(require, 'which-key')
      if status_ok then
        which_key.register({
          ['<leader>t'] = { name = 'Res[t]', _ = 'which_key_ignore' }
        })
      end
      return {
        { '<leader>tr', '<Plug>RestNvim', desc = 'Run the request under cursor' },
        { '<leader>tp', '<Plug>RestNvimPreview', desc = 'Preview the curl command for the request under cursor' },
        { '<leader>tl', '<Plug>RestNvimLast', desc = 'Re-run the last request' }
      }
    end
  },
  {
    'akinsho/toggleterm.nvim',
    opts = {
      size = vim.o.lines * 0.75,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = { },
      shade_terminals = true,
      shading_factor = 2,
      direction = 'horizontal',
      shell = vim.o.shell,
    },
    keys = function ()
      local status_ok, which_key = pcall(require, 'which-key')
      if status_ok then
        which_key.register({
          ['<leader>m'] = { name = 'Toggle ter[m]inal', _ = 'which_key_ignore' }
        })
      end
      vim.api.nvim_create_autocmd('TermOpen', {
        group = vim.api.nvim_create_augroup('kickstart-custom-term-open-mapping', { clear = true }),
        callback = function (args)
          local bufnr = args.buf
          local opts = { buffer = bufnr }
          vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
          vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
          vim.keymap.set('t', '<C-h>', [[<cmd>wincmd h<cr>]], opts)
          vim.keymap.set('t', '<C-j>', [[<cmd>wincmd j<cr>]], opts)
          vim.keymap.set('t', '<C-k>', [[<cmd>wincmd k<cr>]], opts)
          vim.keymap.set('t', '<C-l>', [[<cmd>wincmd l<cr>]], opts)
          vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
        end
      })
      return {
        { '<leader>mh', '<cmd>ToggleTerm direction=horizontal size=' .. tostring(vim.o.lines * 0.75) .. '<cr>', desc = 'Open ter[m]inal [h]orizontally', noremap = true },
        { '<leader>mv', '<cmd>ToggleTerm direction=vertical size=' .. tostring(vim.o.columns * 0.5) .. '<cr>', desc = 'Open ter[m]inal [v]ertically', noremap = true },
        { '<leader>mc', '<cmd>ToggleTermSendCurrentLine<cr>', desc = 'Send [c]urrent line under the cursor', noremap = true }
      }
    end
  },
}
