#!/usr/bin/env fish

set -l picked "$argv[1]"
set -l state_dir ~/.local/state/hypr/static-walls

if test -z "$picked"
    exit 0
end

if not test -f "$picked"
    echo "Picked wallpaper not found: $picked"
    exit 1
end

mkdir -p $state_dir

set -l slot ""
set -l output ""

if string match -rq /left/ -- "$picked"
    set slot left
    set output DP-1
else if string match -rq /middle/ -- "$picked"
    set slot middle
    set output DP-3
else if string match -rq /right/ -- "$picked"
    set slot right
    set output DP-2
else
    echo "Could not infer monitor from path: $picked"
    exit 1
end

printf '%s\n' "$picked" >"$state_dir/$slot.txt"

pkill -x mpvpaper 2>/dev/null

if not pgrep -x awww-daemon >/dev/null
    awww-daemon --no-cache >/dev/null 2>&1 &
    disown
    sleep 1
end

awww img "$picked" --outputs $output --transition-type none
