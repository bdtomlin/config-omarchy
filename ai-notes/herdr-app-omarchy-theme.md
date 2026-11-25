# Herdr app follows the Omarchy theme

Applied 2026-11-22 17:28 CST, while the desktop theme was Tesla Roadster (`tesla-roadster`).

The Herdr desktop app now paints from the active Omarchy palette. A `theme-set` hook rewrites that palette and reselects it after every `omarchy theme set`.

This is not in the symlink tree. `symlink-config.fish` only links `~/config-omarchy/config` into `~/.config`. `~/.config/omarchy` is a real directory, and `~/.config/herdr-app` is the app's own home, which the app rewrites. This note is the record of what to put back.

## Two programs

`herdr` and `herdr-app` do not share a theme.

- The TUI is `/usr/bin/herdr`, package `herdr` 0.9.5-1. Its config is `~/.config/herdr/config.toml`. `[theme] name = "terminal"` was already set, so its tab bar follows Ghostty's ANSI palette. Ghostty is themed by Omarchy. That file was not changed.
- The desktop app is `~/.local/bin/herdr-app`. Its home is `~/.config/herdr-app`. It does not read `colors.toml`. A theme is a JSON file under `themes/`, and the theme picker stores the chosen name on the layout.

`omarchy-theme-set-herdr-machines` is a different feature. It copies the Omarchy theme name to other machines that have `herdr-theme-sync` on. It does not color the Herdr window.

## What was added

`~/.config/herdr-app/themes/omarchy.json`, mode `644`. Herdr derives the sidebar, tabs, and cards from these fields. There is no `colors` override object. Do not rename this file to `main`, `terminals`, or `win98`. A theme whose name matches a layout is offered only on that layout.

`~/.config/herdr-app/settings.json` gained one key, left as the first entry:

```json
"theme": "omarchy"
```

That is the fallback for a layout that does not set its own theme. The main layout already had a theme pick, so the fallback alone would not have changed the open window.

`~/.config/omarchy/hooks/theme-set.d/herdr-app-theme`, mode `755`. Installed with:

```bash
omarchy hook install theme-set /tmp/herdr-app-theme
```

`omarchy-hook` runs every file in `theme-set.d` with `bash` after a theme change. It skips `*.sample`. A non-zero exit prints `Hook failed` and does not stop the other hooks. This script exits 0 when it skips.

The main layout's pick lives in `~/.config/herdr-app/layouts/.state/main.json`. Before this change it was `{ "light": "paper", "dark": "graphite" }`. After `herdr-app do app.theme --name omarchy` it is:

```json
{ "light": "paper", "dark": "omarchy" }
```

`app.theme` writes only the half that matches the theme file's lightness. Tesla Roadster is dark, so the dark half changed and the light half stayed `paper`. A light system appearance still uses Herdr's paper theme. The next `omarchy theme set` to a light theme rewrites `omarchy.json` and sets the light half to `omarchy`. The dark half stays named `omarchy`. Both names point at the same file.

The Terminals layout sets `"theme": "graphite"` in its layout file. Herdr 98 sets `"theme": "win98"`. Those beat `settings.json`. Pick `omarchy` while that layout is showing to override it. The open window was on `main`.

## How the hook builds the file

It asks `omarchy-theme-color` for the resolved palette. That is the same alias and fallback cascade `omarchy-theme-set-templates` uses, so the file matches Ghostty rather than a hand parse of `colors.toml`.

| Herdr field | `omarchy-theme-color` key |
| --- | --- |
| `background` | `background` |
| `foreground` | `foreground` |
| `selection` | `selection_background` |
| `cursor` | `cursor` (`bright_foreground`) |
| `ansi[0]` … `ansi[7]` | `color0` … `color7`: background, red, green, yellow, blue, magenta, cyan, foreground |
| `ansi[8]` … `ansi[15]` | `color8` … `color15`: muted, bright_red, bright_green, bright_yellow, bright_blue, bright_magenta, bright_cyan, bright_foreground |

`color0` through `color15` are the aliases in `/usr/share/omarchy/default/themed/ghostty.conf.tpl`. The script accepts only `#RRGGBB`. Anything else, or a missing `omarchy-theme-color` or `herdr-app`, exits 0 and leaves the previous file in place. It writes through `mktemp` beside the destination, then `chmod 644`. `mktemp` creates the temp file mode `600`.

If `~/.config/herdr-app/herdr-app.sock` exists, it then runs:

```bash
herdr-app do app.theme --name omarchy
```

A closed app needs nothing else. The next launch reads the file. The theme name stays `omarchy`, so a later theme change only replaces the hex values and reselects that name.

## Check

Against Tesla Roadster on 2026-11-22, `omarchy.json` matched `~/.local/state/omarchy/current/theme/ghostty.conf`: background `#151516`, foreground `#c9c3b8`, selection `#42413f`, cursor `#eee5d6`, and all 16 palette entries. `herdr-app status` reported layout `main` and no errors. A window shot showed the warm bronze pane border from that palette.

Refresh just this hook, without running the other `theme-set` scripts:

```bash
bash ~/.config/omarchy/hooks/theme-set.d/herdr-app-theme
```

`omarchy hook theme-set` runs every script in that directory, including the Zellij theme hook.

## Put it back

```bash
rm ~/.config/omarchy/hooks/theme-set.d/herdr-app-theme
rm ~/.config/herdr-app/themes/omarchy.json
herdr-app do app.theme --name graphite
```

Remove the `"theme": "omarchy"` line from `~/.config/herdr-app/settings.json`. The dark half of the main layout returns to `graphite`. The light half was already `paper`.
