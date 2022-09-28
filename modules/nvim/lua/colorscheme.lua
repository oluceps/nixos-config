vim.o.background = "dark"
vim.g.tokyonight_style = "storm" -- day / night
vim.g.catppuccin_flavour = "macchiato"
-- 半透明
-- vim.g.catppuccin_transparent = true
-- vim.g.catppuccin_ransparent_sidebar = true
local colorscheme = "catppuccin"

-- tokyonight
-- OceanicNext
-- gruvbox
-- zephyr
-- nord
-- onedark
-- nightfox
local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
	vim.notify("colorscheme: " .. colorscheme .. " not found!")
	return
end
