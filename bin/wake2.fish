#!/usr/bin/fish

hyprctl eval 'hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "auto", scale = 1 })'
sleep 2
hyprctl eval 'hl.monitor({ output = "DP-2", mode = "3840x2160@160.00", position = "2048x0", scale = 1, transform = 0 })'
