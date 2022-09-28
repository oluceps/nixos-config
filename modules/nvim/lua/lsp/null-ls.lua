local status, null_ls = pcall(require, "null-ls")
--  local helpers = require("null-ls.helpers")
-- local formatting = require("null-ls.builtins._meta.formatting")
if not status then
	vim.notify("null-ls not found")
	return
end

local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local code_actions = null_ls.builtins.code_actions
null_ls.setup({
	debug = false,
	sources = {
		-- Formatting ---------------------
		--  brew install shfmt
		formatting.shfmt,
		-- StyLua
		formatting.stylua,
		-- frontend
		-- nix
		-- formatting.alejandra,

		formatting.prettier.with({ -- 比默认少了 markdown
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"css",
				"scss",
				"less",
				"html",
				"json",
				"yaml",
				"graphql",
				"markdown",
			},
			prefer_local = "node_modules/.bin",
		}),
		-- rustfmt
		-- rustup component add rustfmt
		formatting.rustfmt,
		-- Python
		-- pip install black
		-- asdf reshim python
		formatting.black.with({ extra_args = { "--fast" } }),
		-----------------------------------------------------
		-- Ruby
		-----------------------------------------------------
		formatting.fixjson,
		-- Diagnostics  ---------------------
		diagnostics.eslint.with({
			prefer_local = "node_modules/.bin",
		}),
		-- formatting.mdformat,

		-- 		diagnostics.markdownlint,
		-- 		-- markdownlint-cli2
		-- 		diagnostics.markdownlint.with({
		-- 			prefer_local = "node_modules/.bin",
		-- 			command = "markdownlint-cli2",
		-- 			args = { "$FILENAME", "#node_modules" },
		-- 		}),
		-- 		--
		-- 		-- code actions ---------------------
		code_actions.gitsigns,
		code_actions.eslint.with({
			prefer_local = "node_modules/.bin",
		}),
	},
	-- #{m}: message
	-- #{s}: source name (defaults to null-ls if not specified)
	-- #{c}: code (if available)
	diagnostics_format = "[#{s}] #{m}",
	on_attach = function(_)
		vim.cmd([[ command! Format execute 'lua vim.lsp.buf.formatting()']])
		-- if client.resolved_capabilities.document_formatting then
		--   vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()")
		-- end
	end,
})
