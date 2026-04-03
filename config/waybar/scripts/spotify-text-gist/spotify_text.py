#!/usr/bin/env python3
import subprocess
import json
import os
import re

# -------------------
# Helper functions
# -------------------
def get(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True).strip()
    except:
        return ""

def escape(text):
    if text:
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return ""

def strip_html(s):
    return re.sub(r"<.*?>", "", s)

def center_text(text, width):
    # Treat emojis as double width for approximate visual centering
    temp = re.sub(r"[^\w\s<>/]", "XX", strip_html(text))
    pad = max((width - len(temp)) // 2, 0)
    return " " * pad + text

# -------------------
# Load colors
# -------------------
css_file = os.path.expanduser("~/.config/waybar/style.css")
def get_css_color(var_name, css_file):
    try:
        with open(css_file, "r") as f:
            for line in f:
                match = re.match(rf"@define-color\s+{var_name}\s+([#\w]+);", line.strip())
                if match:
                    return match.group(1)
    except:
        pass
    return None

theme_colors = {
    "artist": "#F5C2E7",
    "song": "#89B4FA",
    "status_playing": "#A6E3A1",
    "status_stopped": "#F9E2AF",
    "line": get_css_color("line", css_file) or "#cdd6f4",
    "volume": get_css_color("volume", css_file) or "#FFD700",
    "spotify_header": "#a6d189",
    "album": "#F9E2AF"
}

# -------------------
# Spotify info
# -------------------
status = get("playerctl --player=spotify status") or "Stopped"
title = escape(get("playerctl --player=spotify metadata title") or "")
artist = escape(get("playerctl --player=spotify metadata artist") or "")
album = escape(get("playerctl --player=spotify metadata album") or "")
released = get("playerctl --player=spotify metadata xesam:contentCreated") or ""
year = re.match(r"(\d{4})", released).group(1) if released and re.match(r"(\d{4})", released) else ""
position = get("playerctl --player=spotify position") or "0"
length = get("playerctl --player=spotify metadata mpris:length") or "0"
volume = get("playerctl --player=spotify volume") or "0"

# -------------------
# Format times
# -------------------
try:
    length_sec = int(length) // 1000000
    length_formatted = f"{length_sec // 60}:{length_sec % 60:02d}"
except:
    length_formatted = "0:00"

try:
    pos_sec = int(float(position))
    pos_formatted = f"{pos_sec // 60}:{pos_sec % 60:02d}"
except:
    pos_formatted = "0:00"

# -------------------
# Spotify icon and status
# -------------------
spotify_icon = ""
status_glyph = "▶" if status.lower() == "playing" else "⏸"
status_color = theme_colors['status_playing'] if status.lower() == "playing" else theme_colors['status_stopped']

# -------------------
# Player row icons
# -------------------
row_emojis = ["🎵", "👤", "💿", "⏱️"]  # Song, Artist, Album, Position

# -------------------
# Volume text (plain) for centering
# -------------------
volume_text = f"🔊 Volume: {int(float(volume)*100)}%"

# -------------------
# Determine dynamic line width
# -------------------
all_lengths = [
    len(title), len(artist), len(album),
    len(f"{pos_formatted} / {length_formatted}"),
    len(f"{spotify_icon} Spotify {status_glyph} {status.capitalize()}"),
    len(volume_text)
]
line_width = max(all_lengths) + 6  # extra padding for emojis/margin

# -------------------
# Build tooltip
# -------------------
# Header line: icon + "Spotify" + Play/Pause status (centered)
header_line = center_text(f"<span foreground='{theme_colors['spotify_header']}'>{spotify_icon} Spotify</span> "
                          f"<span foreground='{status_color}'>{status_glyph} {status.capitalize()}</span>", line_width)

# Thin separator (dynamic)
separator_line = f"<span foreground='{theme_colors['line']}'>{'─'*line_width}</span>"

# Song info (left-aligned with icons)
song_line = f"{row_emojis[0]} <span foreground='{theme_colors['song']}'>{title}</span>"
artist_line = f"{row_emojis[1]} <span foreground='{theme_colors['artist']}'>{artist}</span>"
album_line = f"{row_emojis[2]} <span foreground='{theme_colors['album']}'>{album}{' ('+year+')' if year else ''}</span>"
time_line = f"{row_emojis[3]} <span foreground='white'>{pos_formatted} / {length_formatted}</span>"

# Volume row (centered correctly)
volume_line = center_text(f"<span foreground='{theme_colors['volume']}'>{volume_text}</span>", line_width)

# Combine all parts
tooltip = "\n".join([
    header_line,
    separator_line,
    song_line,
    artist_line,
    album_line,
    time_line,
    separator_line,
    volume_line
])

# -------------------
# Bar text
# -------------------
text = "Spotify" if (title == "" and artist == "") else f"<span foreground='{theme_colors['artist']}'>{artist}</span> — <span foreground='{theme_colors['song']}'><i>{title}</i></span>"

# -------------------
# Output JSON
# -------------------
print(json.dumps({
    "text": text,
    "tooltip": tooltip,
    "markup": "pango",
    "on-click": "playerctl --player=spotify play-pause",
    "on-right-click": "playerctl --player=spotify next",
    "on-middle-click": "playerctl --player=spotify previous"
}))
