set -g __PER_DIR_HIST_MARKER ".fish-history"

function __apply_dir_history --on-variable PWD

	if test -f $__PER_DIR_HIST_MARKER
		set hist_name (head -n 1 $__PER_DIR_HIST_MARKER)
	else
		set -e fish_history 
		return 0
	end

	if test -n $hist_name
		set -g fish_history $hist_name
	else
		set -e fish_history 
	end

	return 0
end

__apply_dir_history
