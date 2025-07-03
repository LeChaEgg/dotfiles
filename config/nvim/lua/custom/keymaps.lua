local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- 定义模式 (方便参考)
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

--  常规与编辑 (General & Editing)

-- 插入模式下使用 jk 退出
map('i', 'jk', '<Esc>', opts)

-- 使用分号快速进入命令模式
map('n', ';', ':', { noremap = true, desc = 'Enter command mode' })

-- 保存与退出
map('n', 'S', ':w<CR>', opts) -- 保存
map('n', 'Q', ':q<CR>', opts) -- 退出

-- 按 Esc 清除搜索高亮
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- [强烈推荐] 可视模式下粘贴，不覆盖剪贴板内容
map('v', 'p', '"_dP', { noremap = true, desc = 'Paste without yanking' })

--  光标移动 (Movement)

-- [强烈推荐] 智能移动 j/k，可以按视觉行移动 (处理长文本换行时)
map('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = 'Move down (smart)' })
map('x', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = 'Move down (smart)' })
map('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = 'Move up (smart)' })
map('x', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = 'Move up (smart)' })

-- 移动代码行
map('n', '<leader>k', ':m .-2<CR>==', { desc = 'Move line up' })
map('n', '<leader>j', ':m .+1<CR>==', { desc = 'Move line down' })
map('v', '<leader>k', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })
map('v', '<leader>j', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })

-- 禁用方向键，强制使用 hjkl
map('n', '<left>', '<cmd>echo "请使用 h 移动！"<CR>')
map('n', '<right>', '<cmd>echo "请使用 l 移动！"<CR>')
map('n', '<up>', '<cmd>echo "请使用 k 移动！"<CR>')
map('n', '<down>', '<cmd>echo "请使用 j 移动！"<CR>')

--  窗口与终端 (Window & Terminal)

-- [强烈推荐] 高效分屏
map('n', '\\', '<CMD>:sp<CR>', { desc = '水平分屏 (Horizontal split)' })
map('n', '|', '<CMD>:vsp<CR>', { desc = '垂直分屏 (Vertical split)' })

-- 窗口焦点切换
map('n', '<C-h>', '<C-w><C-h>', { desc = '切换到左边窗口' })
map('n', '<C-l>', '<C-w><C-l>', { desc = '切换到右边窗口' })
map('n', '<C-j>', '<C-w><C-j>', { desc = '切换到下边窗口' })
map('n', '<C-k>', '<C-w><C-k>', { desc = '切换到上边窗口' })

-- 窗口大小管理
map('n', '+', '<C-w>|<C-w>_', { desc = '最大化当前窗口' })
map('n', '=', '<C-w>=', { desc = '恢复窗口均等布局' })

-- 退出终端模式
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = '退出终端模式' })

--诊断与 Quickfix (Diagnostics & Quickfix)

-- 开/关诊断提示
map('n', '<leader>dl', function()
	if vim.diagnostic.is_enabled() then
		vim.diagnostic.enable(false)
		print '诊断信息已禁用'
	else
		vim.diagnostic.enable()
		print '诊断信息已启用'
	end
end, { noremap = true, silent = true, desc = '切换诊断信息 (Toggle Diagnostics)' })

-- 打开诊断列表
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = '打开诊断 Quickfix 列表' })

-- [强烈推荐] 在 Quickfix 列表中导航
map('n', ']q', '<cmd>cnext<cr>', { desc = '下一个 Quickfix 项目' })
map('n', '[q', '<cmd>cprev<cr>', { desc = '上一个 Quickfix 项目' })

--  配置与文件 (Config & File)

-- 快速编辑自定义配置文件
map('n', '<leader>rc', '<cmd>e ~/.config/nvim/lua/custom/settings.lua<CR>', {
	noremap = true,
	silent = false,
	desc = '编辑自定义配置',
})

-- 重新加载当前文件 (对修改 lua 配置非常有用)
map('n', '<leader>R', ':source %<CR>', {
	noremap = true,
	silent = false,
	desc = '重新加载当前文件',
})
