function lf --description "lf shell wrapper to change directory on exit"
	set tmp (mktemp)
	command lf -last-dir-path=$tmp $argv
	if test -f $tmp
		set -l dir (cat $tmp)
		if test -n "$dir" -a "$dir" != "$PWD"
			builtin cd -- "$dir"
		end
	end
	rm -f $tmp
end
