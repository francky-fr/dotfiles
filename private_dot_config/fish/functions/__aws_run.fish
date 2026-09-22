function __aws_run --description "Appelle aws avec le profil donné (vide = profil par défaut)"
    set -l profile $argv[1]
    set -e argv[1]
    if test -n "$profile"
        command aws --profile $profile $argv
    else
        command aws $argv
    end
end
