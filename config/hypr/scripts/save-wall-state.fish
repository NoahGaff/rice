#!/usr/bin/env fish

if test (count $argv) -lt 3
    echo "Usage: save-wall-state.fish MONITOR TYPE PATH"
    exit 1
end

set -l monitor $argv[1]
set -l walltype $argv[2]
set -l path $argv[3]

set -l STATE_FILE "$HOME/.local/state/wallpaper-manager/walls.tsv"
set -l TMP_FILE "$STATE_FILE.tmp"

mkdir -p (dirname "$STATE_FILE")
touch "$STATE_FILE"

# Rebuild file without old entry for this monitor
rm -f "$TMP_FILE"
for line in (cat "$STATE_FILE")
    if test -z "$line"
        continue
    end

    set -l parts (string split \t -- "$line")
    if test (count $parts) -ge 1
        if test "$parts[1]" != "$monitor"
            echo "$line" >>"$TMP_FILE"
        end
    end
end

printf "%s\t%s\t%s\n" "$monitor" "$walltype" "$path" >>"$TMP_FILE"
mv "$TMP_FILE" "$STATE_FILE"
