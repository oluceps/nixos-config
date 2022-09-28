-- 基础配置
require("basic")
-- 快捷键映射
require("keybindings")

require("plugin-config.catppuccin")
require("colorscheme")
-- 自动命令
-- 插件配置
-- require("plugin-config.nvim-tree")
require("plugin-config.bufferline")
require("plugin-config.lualine")
require("plugin-config.telescope")
require("plugin-config.dashboard")
require("plugin-config.project")
require("plugin-config.nvim-treesitter")
require("plugin-config.indent-blankline")
require("plugin-config.toggleterm")
require("plugin-config.surround")
require("plugin-config.comment")
require("plugin-config.nvim-autopairs")
require("plugin-config.fidget")
-- 内置LSP
-- require("lsp.setup")
require("lsp.cmp")
require("lsp.ui")
-- 格式化
-- require("lsp.formatter")
require("lsp.null-ls")
