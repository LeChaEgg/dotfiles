-- =============================================================================
--  自定义自动命令 (Custom Autocmds)
--  @description: 所有自动命令的集中管理文件
-- =============================================================================

-- print('自定义 autocmds.lua 已加载')

-- -----------------------------------------------------------------------------
-- 辅助函数：用于创建带统一前缀的、干净的自动命令组
-- 这是管理 autocmd 的最佳实践，避免命名冲突且保持代码整洁。
-- -----------------------------------------------------------------------------
local function augroup(name)
  return vim.api.nvim_create_augroup('CustomAu_' .. name, { clear = true })
end

-- -----------------------------------------------------------------------------
-- 1. Linter 白名单自动开关
-- @description: 仅在指定文件类型中启用 linter/diagnostics。
-- -----------------------------------------------------------------------------

-- !!! 重要: 请根据你的需要，编辑下面的白名单列表 !!!
local LINT_ALLOWLIST = {
  -- Languages
  lua = true,
  python = true,
  sh = true,
  bash = true,
  zsh = true,
  -- Formats
  json = true,
  yaml = true,
  toml = true,
  -- Docs
  markdown = true,
}

vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'LinterToggle',
  pattern = '*',
  desc = '根据文件类型白名单启用/禁用 Linter',
  callback = function(args)
    -- 使用 buffer-local 的方式精确控制
    local opts = { bufnr = args.buf }
    if LINT_ALLOWLIST[vim.bo[args.buf].filetype] then
      vim.diagnostic.enable(true, opts) -- 启用
    else
      vim.diagnostic.enable(false, opts) -- 禁用
    end
  end,
})

-- -----------------------------------------------------------------------------
-- 2. 复制文本时高亮
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup 'YankHighlight',
  desc = '复制(Yank)文本时高亮',
  callback = function()
    vim.hl.on_yank()
  end,
})

-- -----------------------------------------------------------------------------
-- 3. 自动恢复光标位置
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
  group = augroup 'CursorRestore',
  pattern = { '*' },
  desc = '重新打开文件时恢复光标位置',
  callback = function()
    vim.api.nvim_exec2('silent! normal! g`"zv', { output = false })
  end,
})

-- -----------------------------------------------------------------------------
-- 4. Markdown 文件专属设置
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'MarkdownSetup',
  pattern = 'markdown',
  desc = '为 Markdown 文件提供增强设置',
  callback = function(args)
    -- a) 优化显示
    vim.opt_local.conceallevel = 2

    -- b) 智能 gx
    vim.keymap.set('n', 'gx', function()
      local line = vim.fn.getline '.'
      local cursor_col = vim.fn.col '.'
      for s, e, url in line:gmatch '%[.-%]%(([^)]+)%)' do
        local url_start = line:find('(', e, true)
        if cursor_col >= s and cursor_col <= url_start + #url then
          vim.ui.open(url)
          return
        end
      end
      vim.cmd 'normal! gx'
    end, { buffer = args.buf, silent = true, desc = '智能打开 Markdown 中的链接' })
  end,
})

-- -----------------------------------------------------------------------------
-- 5. 终端窗口优化
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd('TermOpen', {
  group = augroup 'TermSetup',
  pattern = '*',
  desc = '在终端中禁用行号',
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
})

-- -----------------------------------------------------------------------------
-- 6. 保护特殊窗口 (如文件树)
-- -----------------------------------------------------------------------------
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = augroup 'IrreplaceableWindows',
  pattern = '*',
  desc = '防止特殊窗口被意外替换',
  callback = function()
    local filetypes = { 'OverseerList', 'neo-tree' }
    local buftypes = { 'nofile', 'terminal' }
    if vim.tbl_contains(buftypes, vim.bo.buftype) or vim.tbl_contains(filetypes, vim.bo.filetype) then
      vim.cmd 'setlocal winfixbuf'
    end
  end,
})

-- 文件结束
