# Omarchy Notes

## Add keyd and my mappings:

https://github.com/omacom/omarchy/discussions/175
https://github.com/bdtomlin/config-arch/blob/main/keyd.conf

## Add 1password

super-shift-/ automatically installs 1password. So easy!

## Figure out git syncing

use stow. more to figure out...

## change terminal to ghostty

super space then default terminal

## Omarchy script for monitor issue:

added ~/.config/omarchy/bin/wake-external-display

## Omarchy add asterists for terminal passwords

sudo env EDITOR=nvim visudo
add a line with `Defaults pwfeedback`

## Todo

- [ ] add some kind of terminal mux

## Favorite Omarchy Themes

- Vitesse Black

## Favorite Fonts

`omarchy install font 'Commit Mono' otf-commit-mono-nerd 'CommitMono Nerd Font'`
`omarchy font set "CommitMono Nerd Font"`

`omarchy install font 'Maple Mono' maplemono-nf-cn 'Maple Mono NF CN'`
`omarchy font set "Maple Mono NF CN"`

`omarchy install font 'Meslo LG Mono' ttf-meslo-nerd 'MesloLGL Nerd Font'`
`omarchy font set "MesloLGL Nerd Font"`

`omarchy install font 'Intel One Mono' ttf-intone-nerd 'IntoneMono Nerd Font'`
`omarchy font set "IntoneMono Nerd Font"`

`omarchy install font 'Adwaita Mono' ttf-adwaitamono-nerd 'AdwaitaMono Nerd Font'`
`omarchy font set "AdwaitaMono Nerd Font"`

## Bibata cursor

1. Install it (AUR, prebuilt):

omarchy pkg aur add bibata-cursor-theme-bin

2. Tell GTK apps (and anything that reads GSettings):

gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
gsettings set org.gnome.desktop.interface cursor-size 24

3. Tell Hyprland. Add this to ~/.config/hypr/looknfeel.lua:

hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "24")

GSettings alone will not move the Hyprland pointer. XCURSOR_THEME is already default, and Omarchy keeps that instead of reading GSettings.

4. Apply it without logging out:

hyprctl reload
hyprctl setcursor Bibata-Modern-Classic 24
dbus-update-activation-environment --systemd XCURSOR_THEME XCURSOR_SIZE

New windows pick it up immediately. Already-open apps keep the old cursor until you restart them.

Bibata-Original-Classic is the same black cursor with sharp edges, if you want that instead. The package also ships Ice (white) and Amber.

## zellij theme syncing

https://github.com/skvggor/omarchy-zellij-theme
