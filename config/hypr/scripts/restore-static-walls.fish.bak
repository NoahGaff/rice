#!/usr/bin/env fish

set -l state_dir ~/.local/state/hypr/static-walls

set -l left_file "$state_dir/left.txt"
set -l middle_file "$state_dir/middle.txt"
set -l right_file "$state_dir/right.txt"

if not test -f $left_file
    exit 0
end
if not test -f $middle_file
    exit 0
end
if not test -f $right_file
    exit 0
end

set -l left (string trim < $left_file)
set -l middle (string trim < $middle_file)
set -l right (string trim < $right_file)

for f in $left $middle $right
    if not test -f "$f"
        echo "Saved wallpaper missing: $f"
        exit 1
    end
end

pkill -x mpvpaper 2>/dev/null

if not pgrep -x awww-daemon >/dev/null
    awww-daemon --no-cache >/dev/null 2>&1 &
    disown
    sleep 1
end

awww img "$left" --outputs DP-1 --transition-type none
awww img "$middle" --outputs DP-3 --transition-type none
awww img "$right" --outputs DP-2 --transition-type none
