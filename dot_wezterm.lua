local wezterm = require "wezterm"

wezterm.on("gui-attached", function(domain)
  wezterm.time.call_after(1, function()
    for _, gui_win in ipairs(wezterm.gui.gui_windows()) do
      for _, tab in ipairs(gui_win:mux_window():tabs()) do
        for _, pane_info in ipairs(tab:panes_with_info()) do
          gui_win:perform_action(wezterm.action.AdjustPaneSize({ "Down", 1 }), pane_info.pane)
          gui_win:perform_action(wezterm.action.AdjustPaneSize({ "Up", 1 }), pane_info.pane)
        end
      end
    end
  end)
end)


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
			name = 'unix',
		},

	},
	ssh_domains = {
		{
			name = "flxdev",
			remote_address = "10.200.1.1",
			username = "flevy"
		},
	},

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
		{
			key = "X",
			mods = "CTRL|SHIFT",
			action = wezterm.action.TogglePaneZoomState,
		},
		{
			key = "F",
			mods = "CTRL|SHIFT",
			action = wezterm.action.ActivateCopyMode,
		},
		{
			key = "PageUp",
			mods = "SHIFT",
			action = wezterm.action.ScrollByPage(-1)
		},
		{
			key = "PageDown",
			mods = "SHIFT",
			action = wezterm.action.ScrollByPage(1)
		},
		{
			key = "End",
			mods = "SHIFT",
			action = wezterm.action.ScrollToBottom
		}
	},

	font = wezterm.font("JetBrains Mono", { weight = "Bold", italic = false}),
	font_size = 9,
	adjust_window_size_when_changing_font_size = false,
	hide_tab_bar_if_only_one_tab = true,
	enable_wayland = false

	-- window_padding = {
	-- 	left = 0,
	-- 	right = 0,
	-- 	top = 0,
	-- 	bottom = 0,
	-- },
	-- window_decorations = "RESIZE",
	-- window_close_confirmation = "NeverPrompt",
	-- canonicalize_pasted_newlines = "None",
	-- enable_kitty_keyboard = true,
	-- enable_osc52 = true,
	-- enable_scroll_bar = true,
	-- scrollback_lines = 3500
}
