function __aws_profile_for --description "Profil AWS applicable à la ligne de commande courante"
    set -l cmdline (commandline -opc)
    test (count $cmdline) -gt 0; or return

    # --profile foo
    set -l idx (contains -i -- --profile $cmdline)
    if test -n "$idx"
        set -l next (math $idx + 1)
        if test $next -le (count $cmdline)
            echo $cmdline[$next]
            return
        end
    end

    # --profile=foo
    for a in $cmdline
        set -l p (string replace -r '^--profile=' '' -- $a)
        if test "$p" != "$a"
            echo $p
            return
        end
    end

    switch (basename -- $cmdline[1])
        case awseu
            echo awseu
        case awsus
            echo awsus
        case aws
            test -n "$AWS_PROFILE"; and echo $AWS_PROFILE
    end
end
