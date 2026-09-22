function __aws_s3_complete --description "Complète s3://bucket/prefix/objet"
    set -l token (commandline -ct)
    string match -q 's3://*' -- $token; or return
    set -l profile (__aws_profile_for)
    set -l rest (string replace -r '^s3://' '' -- $token)

    if not string match -q '*/*' -- $rest
        for b in (__aws_s3_buckets "$profile")
            echo "s3://$b/"
        end
        return
    end

    set -l parts (string split -m1 / -- $rest)
    set -l bucket $parts[1]
    set -l key $parts[2]
    set -l prefix (string replace -r '[^/]*$' '' -- $key)

    set -l lines (__aws_run "$profile" s3 ls "s3://$bucket/$prefix" 2>/dev/null | head -n 500)

    # Le listing a abouti : ce bucket existe et nous est accessible
    if test $status -eq 0
        __aws_s3_learn_bucket "$profile" "$bucket"
    end

    for line in $lines
        set -l pre (string match -r '^\s+PRE\s+(.+)$' -- $line)
        if set -q pre[2]
            echo "s3://$bucket/$prefix$pre[2]"
            continue
        end
        set -l obj (string match -r '^\S+\s+\S+\s+\d+\s+(.+)$' -- $line)
        if set -q obj[2]
            echo "s3://$bucket/$prefix$obj[2]"
        end
    end
end
