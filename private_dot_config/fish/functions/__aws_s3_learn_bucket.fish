function __aws_s3_learn_bucket --description "Mémorise un bucket dont le listing a réussi"
    set -l profile $argv[1]
    set -l bucket $argv[2]
    test -n "$bucket"; or return

    set -l tag (string escape --style=var -- "$profile")
    set -l dir $HOME/.cache/fish-aws-s3
    set -l learned $dir/learned_$tag
    mkdir -p $dir

    # Déjà connu ? on ne réécrit pas
    if test -e $learned
        grep -qxF -- $bucket $learned 2>/dev/null; and return
    end
    echo $bucket >>$learned
end
