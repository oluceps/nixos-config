-- local lsp_installer = require("nvim-lsp-installer")

local lspconfig = require("lspconfig")

-- https://github.com/williamboman/nvim-lsp-installer#available-lsps
local servers = {

	sumneko_lua = require("lsp.config.lua"), -- lua/lsp/config/lua.lua
	bashls = require("lsp.config.bash"),
	html = require("lsp.config.html"),
	pyright = require("lsp.config.pyright"),
	cssls = require("lsp.config.css"),
	emmet_ls = require("lsp.config.emmet"),
	jsonls = require("lsp.config.json"),
	tsserver = require("lsp.config.ts"),
	rust_analyzer = require("lsp.config.rust"),
	yamlls = require("lsp.config.yamlls"),
	-- rnix = require("lsp.config.nix"),
	gopls = require("lsp.config.go"),
	texlab = require("lsp.config.latex"),
	taplo = require("lsp.config.toml"),
	clangd = require("lsp.config.c"),
	rnix = require("lsp.config.rnix"),

	remark_ls = require("lsp.config.markdown"),
}

for name, config in pairs(servers) do
	if config ~= nil and type(config) == "table" then
		-- 自定义初始化配置文件实现on_setup
		config.on_setup(lspconfig[name])
	else
		-- 使用默认参数
		lspconfig[name].setup({})
	end
end
