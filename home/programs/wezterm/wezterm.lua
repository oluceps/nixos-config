local wezterm = require("wezterm")
-- local act = wezterm.act

local catppuccin = require("catppuccin").setup({
	-- whether or not to sync with the system's theme
	sync = false,
	-- the flavours to switch between when syncing
	-- available flavours: "latte" | "frappe" | "macchiato" | "mocha"
	sync_flavours = {
		light = "latte",
		dark = "mocha",
	},
	-- the default/fallback flavour, when syncing is disabled
	flavour = "mocha",
})

return {
	-- Smart tab bar [distraction-free mode]
	hide_tab_bar_if_only_one_tab = true,
	enable_wayland = true,
	scrollback_lines = 5000,

	pane_focus_follows_mouse = true,
	warn_about_missing_glyphs = false,
	use_ime = true,
	xim_im_name = "fcitx5",
	enable_kitty_graphics = true,
	window_close_confirmation = "NeverPrompt",

	-- Color scheme
	-- https://wezfurlong.org/wezterm/config/appearance.html
	--
	-- Dracula
	-- https://draculatheme.com
	window_padding = {
		left = 8,
	},

	colors = catppuccin,

	window_background_opacity = 0.82,

	-- Font configuration
	-- https://wezfurlong.org/wezterm/config/fonts.html
	-- font = wezterm.font('Fira Code'),
	font = wezterm.font{
    family = "FiraCode Nerd Font Mono",
    weight = 'Medium',
    harfbuzz_features = {'calt=1', 'clig=1', 'liga=1'}
  },
	font_size = 11.5,

	-- Disable ligatures
	-- https://wezfurlong.org/wezterm/config/font-shaping.html
	-- harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },

	-- Cursor style
	default_cursor_style = "BlinkingBar",

	-- Enable CSI u mode
	-- https://wezfurlong.org/wezterm/config/lua/config/enable_csi_u_key_encoding.html
	enable_csi_u_key_encoding = true,

	keys = {

		{ key = ",", mods = "CTRL", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = ".", mods = "CTRL", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	},
	hyperlink_rules = {
		-- Linkify things that look like URLs and the host has a TLD name.
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = "\\b\\w+://[\\w.-]+\\.[a-z]{2,15}\\S*\\b",
			format = "$0",
		},

		-- linkify email addresses
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
			format = "mailto:$0",
		},

		-- file:// URI
		-- Compiled-in default. Used if you don't specify any hyperlink_rules.
		{
			regex = [[\bfile://\S*\b]],
			format = "$0",
		},

		-- Linkify things that look like URLs with numeric addresses as hosts.
		-- E.g. http://127.0.0.1:8000 for a local development server,
		-- or http://192.168.1.1 for the web interface of many routers.
		{
			regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
			format = "$0",
		},

		-- Make task numbers clickable
		-- The first matched regex group is captured in $1.
		{
			regex = [[\b[tT](\d+)\b]],
			format = "https://example.com/tasks/?t=$1",
		},

		-- Make username/project paths clickable. This implies paths like the following are for GitHub.
		-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
		-- As long as a full URL hyperlink regex exists above this it should not match a full URL to
		-- GitHub or GitLab / BitBucket (i.e. https://gitlab.com/user/project.git is still a whole clickable URL)
		{
			regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
			format = "https://www.github.com/$1/$3",
		},
	},
}
