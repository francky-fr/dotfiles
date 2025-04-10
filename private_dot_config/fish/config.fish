if status is-interactive
    # Commands to run in interactive sessions can go here
end


# To allow spamming tab
function tab_complete
    if commandline --paging-mode
        # Just re-show completions without selecting anything
        commandline -f repaint
    else
        commandline -f complete
    end
end

bind \t tab_complete

