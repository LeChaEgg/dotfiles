-- 1. 启用 LSP 服务器
-- 在这里添加或删除你需要的 LSP 服务器。
-- 记得先用 `:MasonInstall <server_name>` 安装。
vim.lsp.enable 'pyright'
vim.lsp.enable 'marksman'
vim.lsp.enable 'lua_ls'
-- vim.lsp.enable 'clangd'

-- 2. LspAttach: 配置的核心，当 LSP 附加到文件时触发
vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('user-lsp-attach-advanced', { clear = true }),
	callback = function(event)
		local client = vim.lsp.get_client_by_id(event.data.client_id)
		local bufnr = event.buf
		local map = function(mode, keys, func, desc)
			vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = 'LSP: ' .. desc })
		end
		-- =======================================================================
		--                  ↓↓↓ 默认关闭markdown的LSP诊断 ↓↓↓
		-- =======================================================================
		if client and client.name == 'marksman' then
			-- [修正] 使用 vim.diagnostic.enable(false) 替代旧的 disable() API
			vim.diagnostic.enable(false, { bufnr = bufnr })

			map('n', '<leader>tdm', function()
				-- [修正] 使用新的 API 来切换诊断状态
				if vim.diagnostic.is_enabled({ bufnr = bufnr }) then
					vim.diagnostic.enable(false, { bufnr = bufnr })
					vim.notify('Markdown diagnostics: [OFF]', vim.log.levels.INFO, { title = 'LSP' })
				else
					vim.diagnostic.enable(true, { bufnr = bufnr })
					vim.notify('Markdown diagnostics: [ON]', vim.log.levels.INFO, { title = 'LSP' })
				end
			end, 'Toggle Markdown Diagnostics')
		end
		map('n', 'K', vim.lsp.buf.hover, 'Hover Documentation')
		map('n', 'gd', function()
			require('telescope.builtin').lsp_definitions { jump_type = 'split' }
		end, 'Goto Definition')
		map('n', 'gr', require('telescope.builtin').lsp_references, 'Goto References')
		map('n', 'gD', vim.lsp.buf.declaration, 'Goto Declaration')
		map('n', 'gI', require('telescope.builtin').lsp_implementations, 'Goto Implementation')
		map('n', 'gT', require('telescope.builtin').lsp_type_definitions, 'Goto Type Definition')
		map('n', '<leader>ss', require('telescope.builtin').lsp_document_symbols, 'Search Document Symbols')
		map('n', '<leader>sS', require('telescope.builtin').lsp_dynamic_workspace_symbols,
			'Search Workspace Symbols')
		map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code Action')
		map('v', '<leader>ca', vim.lsp.buf.code_action, 'Code Action (Visual)')
		map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
		map('n', '<leader>ld', function()
			vim.diagnostic.open_float(nil, { scope = 'line' })
		end, 'Show Line Diagnostics')
		map('n', '[d', vim.diagnostic.goto_prev, 'Goto Previous Diagnostic')
		map('n', ']d', vim.diagnostic.goto_next, 'Goto Next Diagnostic')
		map(
			'n',
			'<leader>td',
			(function()
				local diag_status = true
				return function()
					diag_status = not diag_status
					if diag_status then
						vim.diagnostic.show()
					else
						vim.diagnostic.hide()
					end
				end
			end)(),
			'Toggle Diagnostics'
		)

		if client and client.supports_method 'textDocument/foldingRange' then
			vim.wo.foldmethod = 'expr'
			vim.wo.foldexpr = 'v:lua.vim.lsp.foldexpr()'
			vim.wo.foldenable = false
		end
		if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
			map('n', '<leader>th', function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
			end, 'Toggle Inlay Hints')
		end
		if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
			local group = vim.api.nvim_create_augroup('lsp-highlight-references', { clear = false })
			vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' },
				{ buffer = bufnr, group = group, callback = vim.lsp.buf.document_highlight })
			vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' },
				{ buffer = bufnr, group = group, callback = vim.lsp.buf.clear_references })
		end

		-- 内置特性: Folding & Inlay Hints (参考文件中的功能)
		if client and client.supports_method 'textDocument/foldingRange' then
			vim.wo.foldmethod = 'expr'
			vim.wo.foldexpr = 'v:lua.vim.lsp.foldexpr()'
			vim.wo.foldenable = false -- 默认不折叠，可手动开启
		end

		if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
			map('n', '<leader>th', function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
			end, 'Toggle Inlay Hints')
		end

		-- 光标悬停时高亮文档中的所有引用
		if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
			local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight-references',
				{ clear = false })
			vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
				buffer = bufnr,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
				buffer = bufnr,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})
		end
	end,
})

-- 3. 自定义诊断信息的 UI (使用你 kickstart 中的图标)
vim.diagnostic.config {
	severity_sort = true,
	float = { border = 'rounded', source = 'if_many' },
	underline = { severity = vim.diagnostic.severity.ERROR },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = '󰅚',
			[vim.diagnostic.severity.WARN] = '󰀪',
			[vim.diagnostic.severity.INFO] = '󰋽',
			[vim.diagnostic.severity.HINT] = '󰌶',
		},
	},
	virtual_text = {
		source = 'if_many',
		spacing = 4,
		prefix = '●',
	},
}

-- 4. 创建实用的自定义命令
local api, lsp = vim.api, vim.lsp
api.nvim_create_user_command('LspInfo', ':checkhealth vim.lsp', { desc = 'Alias to `:checkhealth vim.lsp`' })
api.nvim_create_user_command('LspLog', function()
	vim.cmd(string.format('tabnew %s', lsp.get_log_path()))
end, {
	desc = 'Opens the Nvim LSP client log.',
})

local complete_client = function(arg)
	return vim
	    .iter(vim.lsp.get_clients())
	    :map(function(client)
		    return client.name
	    end)
	    :filter(function(name)
		    return name:sub(1, #arg) == arg
	    end)
	    :totable()
end
api.nvim_create_user_command('LspRestart', function(info)
	for _, name in ipairs(info.fargs) do
		if vim.lsp.config[name] == nil then
			vim.notify(("Invalid server name '%s'"):format(info.args))
		else
			vim.lsp.enable(name, false)
		end
	end

	local timer = assert(vim.uv.new_timer())
	timer:start(500, 0, function()
		for _, name in ipairs(info.fargs) do
			vim.schedule_wrap(function(x)
				vim.lsp.enable(x)
			end)(name)
		end
	end)
end, {
	desc = 'Restart the given client(s)',
	nargs = '+',
	complete = complete_client,
})
