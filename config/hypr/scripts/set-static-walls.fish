#!/usr/bin/env fish

set -l state_file ~/.local/state/hypr/current-static-walls.txt

if test (count $argv) -ne 3
    echo "Usage:"
    echo "  set-static-walls.fish <left-image> <middle-image> <right-image>"
    exit 1
end

set -l left $argv[1]
set -l middle $argv[2]
set -l right $argv[3]

for f in $left $middle $right
    if not test -f "$f"
        echo "Missing file: $f"
        exit 1
    end
end

mkdir -p ~/.local/state/hypr
printf '%s\n%s\n%s\n' "$left" "$middle" "$right" >$state_file

pkill -x mpvpaper 2>/dev/null

if not pgrep -x awww-daemon >/dev/null
    awww-daemon --no-cache >/dev/null 2>&1 &
    disown
    sleep 1
end

awww img "$left" --outputs DP-1 --transition-type none
awww img "$right" --outputs DP-2 --transition-type none
awww img "$middle" --outputs DP-3 --transition-type none

echo "Saved and applied static wallpapers:"
echo "  Left   (DP-1): $left"
echo "  Right  (DP-2): $right"
echo "  Middle (DP-3): $middle"
