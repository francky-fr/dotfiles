function lshist
    for f in ~/.local/share/fish/*_history
        if test -e $f
            echo $f
        end
    end
end

