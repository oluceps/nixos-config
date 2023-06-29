local wezterm = require("wezterm")
local act = wezterm.action

local config =
{
	default_prog = { '/usr/bin/env', 'fish' },
	-- Smart tab bar [distraction-free mode]
	hide_tab_bar_if_only_one_tab = true,
	enable_wayland = true,
	enable_scroll_bar = true,
	scrollback_lines = 5000,

	pane_focus_follows_mouse = true,
	warn_about_missing_glyphs = false,
	use_ime = true,
	xim_im_name = "fcitx5",
	-- front_end = "WebGpu",
	-- webgpu_power_preference = "HighPerformance",
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

	color_scheme = 'Catppuccin Mocha',

	window_background_opacity = 0.82,

	-- Font configuration
	-- https://wezfurlong.org/wezterm/config/fonts.html
	font = wezterm.font {
		family = "Maple Mono",
		-- weight = 'Regular',
		harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }
	},
	font_size = 15,

	-- Cursor style
	default_cursor_style = "BlinkingBar",

	-- Enable CSI u mode
	-- https://wezfurlong.org/wezterm/config/lua/config/enable_csi_u_key_encoding.html
	enable_csi_u_key_encoding = true,

	keys = {

		{ key = ",", mods = "CTRL", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ key = ".", mods = "CTRL", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{
			key = 'w',
			mods = 'CTRL',
			action = wezterm.action.CloseCurrentPane { confirm = true },
		},
		{ key = 'n', mods = 'SHIFT|CTRL', action = wezterm.action.SpawnWindow },

	},

}
return config
