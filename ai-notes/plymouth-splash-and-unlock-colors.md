# Plymouth splash and disk-unlock colors

Noted 2026-11-18. Nothing was changed. The boot splash and the LUKS password screen were still the Omarchy default.

Both screens are one Plymouth theme, `omarchy`. They share one background color, one foreground color, and one logo. The desktop theme does not drive them. On this machine the desktop theme was Kanagawa Dragon (`~/.local/state/omarchy/current/theme.name` is `kanagawa-dragon`) while `omarchy plymouth current` printed `default`.

The theme Plymouth actually draws lives in `/usr/share/plymouth/themes/omarchy`. `/etc/plymouth/plymouthd.conf` sets `Theme=omarchy`. Leave those files alone. `omarchy plymouth set` publishes into them and rebuilds the initramfs. A hand edit there is overwritten by `omarchy plymouth reset`, `omarchy refresh plymouth`, or the next theme apply, and it is invisible until the initramfs is rebuilt because the theme is copied into the boot image.

## What the two colors cover

`omarchy plymouth set` takes a background hex, a text hex, and a logo PNG.

- Background is a solid fill on the splash and on the password screen. It is written to both `Window.SetBackgroundTopColor` and `Window.SetBackgroundBottomColor` in `omarchy.script`.
- Text recolors `bullet.png`, `entry.png`, `lock.png`, and `progress_bar.png`. That is the password box, the lock icon, the password dots, and the boot progress bar.
- The logo is the image in the center. It must be a regular PNG. A symlink is rejected.

The same command also recolors the SDDM login screen at `/usr/share/sddm/themes/omarchy` (background, text, and the same box, lock, and bullet assets). The failed-entry assets stay the stock pink `#f7768e`.

The command must be run as the user, not under an outer `sudo`. It calls `sudo` itself, runs `plymouth-set-default-theme omarchy`, then `limine-mkinitcpio`. The new colors show up after a reboot. The initramfs rebuild takes a minute or two.

## Pick a stock theme

Launcher: **Appearance → Unlock**. That picker only lists themes that ship `preview-unlock.png`. Choosing one runs `omarchy plymouth set by theme <name>` in a terminal. Choosing `default` runs `omarchy plymouth reset`.

From a terminal:

```bash
omarchy plymouth list
omarchy plymouth current
omarchy plymouth set by theme kanagawa
```

`set by theme` reads `background` and `foreground` from that theme's `colors.toml` and uses its `unlock.png` as the logo. Stock Kanagawa (`/usr/share/omarchy/themes/kanagawa`) has `unlock.png` and `preview-unlock.png`. Its colors are background `#1f1f28` and foreground `#dcd7ba`.

`kanagawa-dragon` is absent from `omarchy plymouth list`. The copy in `~/.config/omarchy/themes/kanagawa-dragon` has `colors.toml` and no `unlock.png`, so `omarchy plymouth set by theme kanagawa-dragon` fails looking for that file.

## Match Kanagawa Dragon and keep the Omarchy logo

Dragon's `colors.toml` is background `#181616` and foreground `#c5c9c5`. The packaged logo is a normal file at `/usr/share/omarchy/default/plymouth/logo.png`.

Preview, which opens the PNG in `imv` and does not install anything:

```bash
omarchy plymouth preview '#181616' '#c5c9c5' /usr/share/omarchy/default/plymouth/logo.png /tmp/plymouth-preview.png
```

Install:

```bash
omarchy plymouth set '#181616' '#c5c9c5' /usr/share/omarchy/default/plymouth/logo.png
```

Any other `#RRGGBB` pair works the same way. Pass a different PNG as the third argument to change the logo.

## Put it back

```bash
omarchy plymouth reset
```

`omarchy refresh plymouth` restores the packaged Plymouth assets and rebuilds the initramfs. The default background in the packaged script is about `#1a1b26`.
