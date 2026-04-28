function tmux-go-repl-lab
    set session go-repl-lab

    # créer la session si absente
    tmux has-session -t $session 2>/dev/null
    or tmux new-session -d -s $session -n gomacro-A 'gomacro'

    # gomacro
    tmux new-window -t $session -n gomacro-B 'gomacro'

    # yaegi
    tmux new-window -t $session -n yaegi-A 'yaegi'
    tmux new-window -t $session -n yaegi-B 'yaegi'

    # gore
    tmux new-window -t $session -n gore-A 'gore'
    tmux new-window -t $session -n gore-B 'gore'

    # revenir sur la première window
    tmux select-window -t $session:gomacro-A

    # attacher
    tmux attach -t $session
end

