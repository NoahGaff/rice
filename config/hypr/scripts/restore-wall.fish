#!/usr/bin/env fish

set -l STATE_FILE "$HOME/.local/state/hypr/walls.tsv"
set -l LOG_FILE "$HOME/.local/state/hypr/restore-wall.log"

mkdir -p (dirname "$STATE_FILE")
mkdir -p (dirname "$LOG_FILE")

echo "" >>"$LOG_FILE"
echo "==== restore-wall started at "(date)" ====" >>"$LOG_FILE"

if not test -f "$STATE_FILE"
    echo "No state file found: $STATE_FILE" >>"$LOG_FILE"
    exit 0
end

sleep 1

set -l connected_monitors
for line in (hyprctl monitors | string match -r '^Monitor .*')
    set -l mon (echo $line | awk '{print $2}')
    set connected_monitors $connected_monitors $mon
end

echo "Connected monitors: $connected_monitors" >>"$LOG_FILE"

if test (count $connected_monitors) -eq 0
    echo "No connected monitors detected, aborting restore" >>"$LOG_FILE"
    exit 1
end

if type -q awww-daemon
    if not pgrep -x awww-daemon >/dev/null
        echo "Starting awww-daemon" >>"$LOG_FILE"
        awww-daemon --no-cache >/dev/null 2>&1 &
        disown
        sleep 1
    end
end

if type -q mpvpaper
    echo "Stopping old mpvpaper instances" >>"$LOG_FILE"
    pkill -x mpvpaper >/dev/null 2>&1
    sleep 1
end

while read -l line
    if test -z "$line"
        continue
    end

    if string match -rq '^\s*#' -- "$line"
        continue
    end

    set -l parts (string split \t -- "$line")

    if test (count $parts) -lt 3
        echo "Skipping malformed line: $line" >>"$LOG_FILE"
        continue
    end

    set -l monitor $parts[1]
    set -l walltype $parts[2]
    set -l path $parts[3]

    if not contains -- "$monitor" $connected_monitors
        echo "Skipping $monitor (not connected)" >>"$LOG_FILE"
        continue
    end

    if not test -e "$path"
        echo "Skipping $monitor, missing file: $path" >>"$LOG_FILE"
        continue
    end

    switch "$walltype"
        case static
            if type -q awww
                echo "Applying static to $monitor: $path" >>"$LOG_FILE"
                awww img "$path" --outputs "$monitor" --transition-type none >/dev/null 2>&1
            else
                echo "awww not found for static wallpaper on $monitor" >>"$LOG_FILE"
            end

        case live
            if type -q mpvpaper
                echo "Applying live to $monitor: $path" >>"$LOG_FILE"
                mpvpaper -o "no-audio --loop-file=inf --hwdec=auto-safe --profile=fast --interpolation=no --vd-lavc-threads=2" "$monitor" "$path" >/dev/null 2>&1 &
                disown
            else
                echo "mpvpaper not found for live wallpaper on $monitor" >>"$LOG_FILE"
            end

        case '*'
            echo "Unknown wall type '$walltype' for $monitor" >>"$LOG_FILE"
    end
end <"$STATE_FILE"

echo "==== restore-wall finished at "(date)" ====" >>"$LOG_FILE"
