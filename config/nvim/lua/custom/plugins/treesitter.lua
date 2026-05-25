return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  opts = function()
    local languages = {
      'bash',
      'c',
      'cpp',
      'diff',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'python',
      'query',
      'snakemake',
      'vim',
      'vimdoc',
      'xml',
    }

    local filetypes = {
      'bash',
      'c',
      'cpp',
      'diff',
      'help',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'python',
      'query',
      'sh',
      'snakemake',
      'vim',
      'vimdoc',
      'xml',
      'zsh',
    }

    return {
      install_dir = vim.fn.stdpath 'data' .. '/site',
      languages = languages,
      filetypes = filetypes,
    }
  end,
  config = function(_, opts)
    require('nvim-treesitter').setup {
      install_dir = opts.install_dir,
    }

    require('nvim-treesitter').install(opts.languages)

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('CustomTreeSitter', { clear = true }),
      pattern = opts.filetypes,
      callback = function(args)
        local ok = pcall(vim.treesitter.start, args.buf)
        if not ok then
          return
        end

        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        vim.wo.foldmethod = 'expr'
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      end,
    })
  end,
}
