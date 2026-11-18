# Fingerprint auth unless an external monitor is connected

Applied 2026-11-18 09:52:50 CST.

sudo and polkit use the fingerprint reader only when no external display is linked. A linked external display, or a closed lid, skips the reader and asks for the password. The lock screen was left alone.

This is a local edit of `/etc/pam.d`. It is not in the Stow packages under `~/config-omarchy` (`config-dirs`, `config-selective`, `home-dotfiles`). Those packages only manage `~/.config` and home dotfiles. An `omarchy update` that rewrites these PAM files can drop the extra line. This note is the record of what to put back.

## What was added

`/etc/pam.d/sudo` and `/etc/pam.d/polkit-1` each gained one line, placed first, above Omarchy's stock lid gate:

```
auth      [success=2 default=ignore] pam_exec.so quiet /usr/bin/omarchy-hw-external-monitors
```

`/etc/pam.d/sudo` as installed:

```
auth      [success=2 default=ignore] pam_exec.so quiet /usr/bin/omarchy-hw-external-monitors
auth      [success=1 default=ignore] pam_exec.so quiet /usr/bin/omarchy-hw-laptop-closed
auth      sufficient pam_fprintd.so
#%PAM-1.0
auth		include		system-auth
account		include		system-auth
session		include		system-auth
session		optional	pam_systemd.so class=none
```

The four `include` / `optional` lines in `sudo` are tab-separated. That whitespace was already there and was preserved.

`/etc/pam.d/polkit-1` as installed:

```
auth      [success=2 default=ignore] pam_exec.so quiet /usr/bin/omarchy-hw-external-monitors
auth      [success=1 default=ignore] pam_exec.so quiet /usr/bin/omarchy-hw-laptop-closed
auth      sufficient pam_fprintd.so
auth      include system-auth

account   include system-auth
password  include system-auth
session   include system-auth
```

Both files stayed mode `644`, owner `root:root`.

`pam_exec` needs a literal absolute path. It does not expand variables. `/usr/bin/omarchy-hw-external-monitors` is the packaged helper (the same path style Omarchy uses for the lid gate). `quiet` stops `pam_exec` from printing the helper's non-zero exit on the sudo prompt. Without it, every undocked sudo would show a "command failed" line, because the helper exits 1 whenever it is not skipping the reader.

## How the stack decides

PAM walks the `auth` lines in order. The bracket is the control flag:

- `success=N` means the helper exited 0, so skip the next N modules.
- `default=ignore` means every other result, including the helper exiting 1, is ignored and PAM continues at the next line.

`pam_fprintd.so` is `sufficient`. A match ends authentication successfully. A miss, or a skip of that module, falls through to `auth include system-auth`, which is the password.

| External display | Lid | What happens |
| --- | --- | --- |
| Linked (helper exits 0) | Open or closed | `success=2` skips the lid gate and `pam_fprintd`. Password. |
| Not linked (helper exits 1) | Closed (lid helper exits 0) | The monitor line is ignored. `success=1` skips `pam_fprintd`. Password. |
| Not linked | Open (lid helper exits 1) | Both gates are ignored. Fingerprint, then password if the print does not match. |

The skip count is 2 because the monitor line has to jump over two modules: the lid gate and `pam_fprintd`. A second line with `success=1` placed above the lid gate is the wrong shape. A closed lid would succeed, skip only the monitor line, and then still run `pam_fprintd` and wait on the reader.

The three lines have to stay in this order, with nothing inserted between the monitor line and `pam_fprintd`, or the skip count is wrong. If another gate is added above `pam_fprintd`, raise `success=2` by one for each module it must jump.

## What "external monitor" means

`/usr/bin/omarchy-hw-external-monitors` reads `/sys/class/drm/card*-*/status` (`OMARCHY_DRM_PATH` overrides the directory). It exits 0 on the first connector whose status is `connected`, and exits 1 if none are. It ignores internal panels: any status path matching `-(eDP|LVDS|DSI)-`.

This is the kernel link state, not a Hyprland monitor rule and not DPMS. A display that stays linked while asleep or blanked still counts as connected, so the reader stays off. A display that drops the link, so the status file says `disconnected`, brings the reader back even if the cable is still in the port. The MSI MAG323UPF on this machine often keeps the DP link through standby, which is the desired reading for this gate.

On this laptop the internal panel is `card0-eDP-1`. The external display this gate was aimed at is `card0-DP-2` (MSI MAG323UPF). The same helper also treats `card0-HDMI-A-1` and the other `card0-DP-*` connectors as external. Any one of them reporting `connected` is enough.

Check it without touching PAM:

```bash
omarchy-hw-external-monitors; echo $?   # 0 linked, 1 not
omarchy-hw-laptop-closed; echo $?       # 0 closed, 1 open
```

At the time of the edit, DP-2 was `connected` and the lid helper exited 1.

## What the lid helper does

`/usr/bin/omarchy-hw-laptop-closed` is stock Omarchy, from `omarchy-setup-security-fingerprint`. It was already the first line of both files before this edit. It exits 0 when the lid is closed and 1 otherwise.

It prefers `/proc/acpi/button/lid/*/state` and treats a state containing `closed` as closed. If there is no ACPI lid file but some input device advertises `SW_LID`, it asks logind `LidClosed` over the system bus with a 2 second timeout. A stalled logind must not hang sudo, which is why the timeout is there. This machine has an ACPI lid, so the logind path is unused.

The lid gate exists because a closed lid makes the reader unreachable. Without the gate, sudo and polkit block for the full `pam_fprintd` timeout before offering the password.

## sudo and polkit

sudo uses `/etc/pam.d/sudo` directly. The next `sudo` in a terminal follows the table above. A cached sudo timestamp (`sudo -v` still valid) will not prompt at all until it expires. `sudo -k` clears it.

polkit uses `/etc/pam.d/polkit-1`. Graphical prompts (pkexec, package installs, settings that need admin) follow the same table. The Omarchy polkit agent (`/usr/share/omarchy/shell/plugins/polkit/PolkitAgent.qml`) shows a fingerprint icon only while all of these are true: `pam_fprintd.so` is in the polkit file, the lid probe says open, and PAM has not yet asked for a typed response. It probes the lid with `omarchy-hw-laptop-closed`. It does not probe the external-monitor helper.

With the lid open and DP-2 linked, PAM skips the reader immediately and asks for a password, so the dialog switches to the password field as soon as that request arrives. The icon can still appear for a moment first, because the agent only hides it up front for a closed lid. The authentication method is already the password. That flash is cosmetic.

The agent treats fingerprint as configured whenever any non-comment `auth` line contains `pam_fprintd.so` (`PolkitModel.js`). The monitor line does not turn that off. Removing `pam_fprintd.so` would disable fingerprint everywhere, including when undocked.

## Lock screen

`/etc/pam.d/omarchy-lock-fingerprint` was not modified:

```
#%PAM-1.0
auth       required                    pam_fprintd.so
account    include                     system-local-login
```

The lock screen runs two separate PAM stacks. The password field uses `/etc/pam.d/omarchy-lock-password`. The reader uses `/etc/pam.d/omarchy-lock-fingerprint`, and that module is `required`, not `sufficient`. Skipping it with `success=1` would skip the only auth module. A required module that never runs does not fail the stack, so the session would unlock with no credential.

`omarchy-apply-lock` rewrites `/etc/pam.d/omarchy-lock-fingerprint` from scratch whenever it configures the lock screen. A local line added there would disappear on the next apply.

The lock plugin (`/usr/share/omarchy/shell/plugins/lock/Service.qml`) starts the reader whenever a print is enrolled. `LockView.qml` always shows the password field beside it. Docked, the lock screen still listens on the reader and still accepts the password. Turning the listen off while docked means changing that plugin. The plugin lives in `/usr/share/omarchy`, and package updates overwrite it.

## What an update can do to this

`omarchy-setup-security-fingerprint` inserts the lid gate only when the file does not already contain the string `omarchy-hw-laptop-closed`, and it inserts that line immediately before `pam_fprintd.so`. Re-running setup while these files still have the lid line will not remove the monitor line and will not add a second lid line.

Setup will not notice if the monitor line is deleted. Stock behavior then returns: fingerprint whenever the lid is open, including at the desk.

If a future update rewrites either file and drops both custom lines, put the monitor line back first with `success=2`, then the lid line with `success=1`, then `pam_fprintd`. Confirm the password `include` line is still the next auth module. On sudo that include is the line after `#%PAM-1.0`.

Do not edit `/usr/share/omarchy` to make this permanent. The helpers are already the right ones. The local change is the two PAM lines.

## Check and revert

With the MSI linked, a fresh sudo or polkit prompt should ask for the password and should not wait on the reader. Unplug every external display, leave the lid open, and the same prompt should accept a fingerprint. Close the lid with nothing external linked and it should ask for the password again.

Pre-change copies, taken just before the edit:

```
/var/backups/omarchy-pam-1795017170/sudo
/var/backups/omarchy-pam-1795017170/polkit-1
```

Those copies are the files from before the monitor line existed. Restoring them returns the stock lid-only gate. To keep the lid gate and only undo the monitor behavior, delete the `omarchy-hw-external-monitors` line from both live files and leave the `success=1` lid line as the first line.
