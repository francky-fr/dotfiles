local wezterm = require "wezterm"

return {
	mouse_bindings = {
		-- Drag
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "NONE",
			action = wezterm.action.CompleteSelection("PrimarySelection"),
		},
		-- Double-click
		{
			event = { Down = { streak = 2, button = "Left" } },
			mods = "NONE",
			action = wezterm.action.SelectTextAtMouseCursor("Word"),
		},
		{
			event = { Up = { streak = 2, button = "Left" } },
			mods = "NONE",
			action = wezterm.action.CompleteSelection("PrimarySelection"),
		},
		-- Triple-click
		{
			event = { Down = { streak = 3, button = "Left" } },
			mods = "NONE",
			action = wezterm.action.SelectTextAtMouseCursor("Line"),
		},
		{
			event = { Up = { streak = 3, button = "Left" } },
			mods = "NONE",
			action = wezterm.action.CompleteSelection("PrimarySelection"),
		},
	},

	unix_domains = {
		{
			name = 'unix'
		},

	},
	ssh_domains = {
		{
			name = "flxdev",
			remote_address = "10.200.1.1",
			username = "flevy"
		},
	},
	default_gui_startup_args = {"connect", "local"},

	keys = {
		{
			key = 'O',
			mods = 'CTRL|SHIFT',
			action = wezterm.action.SplitPane({
				direction = 'Down',
				size = { Percent = 50 },
			}),
		},
		{
			key = 'E',
			mods = 'CTRL|SHIFT',
			action = wezterm.action.SplitPane({
				direction = 'Right',
				size = { Percent = 50 },
			}),
		},
		{
			key = "W",
			mods = "CTRL|SHIFT",
			action =  wezterm.action.CloseCurrentPane({ confirm = false }),
		},
		{
			key = "W",
			mods = "CTRL|SHIFT",
			action = wezterm.action.CloseCurrentPane({ confirm = false }),
		},
		{
			key = "LeftArrow",
			mods = "ALT",
			action = wezterm.action.ActivatePaneDirection("Left"),
		},
		{
			key = "RightArrow",
			mods = "ALT",
			action = wezterm.action.ActivatePaneDirection("Right"),
		},
		{
			key = "UpArrow",
			mods = "ALT",
			action = wezterm.action.ActivatePaneDirection("Up"),
		},
		{
			key = "DownArrow",
			mods = "ALT",
			action = wezterm.action.ActivatePaneDirection("Down"),
		},
	},

	font = wezterm.font("JetBrains Mono", { weight = "Bold", italic = false}),
	font_size = 9,
	adjust_window_size_when_changing_font_size = false,
	hide_tab_bar_if_only_one_tab = true,

	enable_wayland = false
}
