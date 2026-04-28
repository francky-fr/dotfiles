function gow
  if test (count $argv) -lt 1
    echo "usage: gow <file.go> [nvim args...]"
    return 2
  end

  set -l file $argv[1]
  set -e argv[1]

  nvim $file -c 'GoKernel' -c 'GoTemp' $argv
end
