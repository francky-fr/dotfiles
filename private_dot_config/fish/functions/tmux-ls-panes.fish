function tmux-ls-panes
    tmux list-panes -F '#{pane_index}: #{pane_title} (#{pane_current_command})'
end
