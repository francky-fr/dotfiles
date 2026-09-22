function __aws_s3_buckets --description "Buckets connus d'un profil : appris à l'usage, complétés par l'API"
    set -l profile $argv[1]
    set -l tag (string escape --style=var -- "$profile")
    set -l dir $HOME/.cache/fish-aws-s3
    set -l learned $dir/learned_$tag
    set -l api $dir/api_$tag
    mkdir -p $dir

    # Tentative API, avec cache 1 h. Échoue silencieusement sans ListAllMyBuckets.
    set -l fresh ""
    test -e $api; and set fresh (find $api -mmin -60 2>/dev/null)
    if test -z "$fresh"
        __aws_run "$profile" s3api list-buckets \
            --query 'Buckets[].Name' --output text 2>/dev/null \
            | string split \t | string trim >$api.tmp
        mv -f $api.tmp $api 2>/dev/null; or rm -f $api.tmp
    end

    # Union des deux sources, dédupliquée
    begin
        test -s $learned; and cat $learned
        test -s $api; and cat $api
    end | string match -rv '^\s*$' | sort -u
end
