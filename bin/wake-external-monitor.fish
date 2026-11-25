#!/usr/bin/fish

# One-time wake for DP-2. Stops the Omarchy shell, modesets, then starts the shell.
# Does not install itself or leave a watcher running.

if omarchy-hyprland-session-locked
    echo 'Refusing to stop the shell while the session is locked.' >&2
    exit 1
end

if set -q OMARCHY_PATH
    set config_dir $OMARCHY_PATH/shell
else
    set config_dir /usr/share/omarchy/shell
end

function apply_mode
    hyprctl eval "hl.monitor({ output = \"$argv[1]\", mode = \"$argv[2]\", position = \"$argv[3]\", scale = $argv[4] })" >/dev/null
end

echo '=== stop shell ==='
while timeout 30 quickshell kill -p $config_dir --any-display >/dev/null 2>&1
end

set deadline (math (date +%s) + 30)
while test (date +%s) -lt $deadline
    if not quickshell list -a -j 2>/dev/null | jq -e --arg dir "$config_dir/" 'any(.[]; .config_path | startswith($dir))' >/dev/null 2>&1
        break
    end
    sleep 0.1
end

if pgrep -x -f "quickshell -n -p $config_dir" >/dev/null
    echo 'SHELL_STILL_RUNNING' >&2
    pgrep -af quickshell >&2
    exit 1
end
echo 'shell stopped'

set path /sys/class/drm/card0-DP-2
set restored 0

echo '=== wake 1080p ==='
apply_mode DP-2 1920x1080@60 2048x0 1.0

# The 1080p link can be up for a while before the real EDID replaces the
# standby list. Keep trying the 4K mode until Hyprland reports it.
for attempt in (seq 40)
    sleep 0.5
    set enabled (cat $path/enabled)
    set dpms (cat $path/dpms)
    echo "poll enabled=$enabled dpms=$dpms"
    if test "$enabled" != enabled; or test "$dpms" != On
        continue
    end
    if not grep -qx 3840x2160 $path/modes
        continue
    end
    echo '=== restore 4K ==='
    apply_mode DP-2 3840x2160@160.00 2048x0 1.0
    sleep 0.5
    set size (hyprctl monitors -j | jq -r '.[] | select(.name=="DP-2") | "\(.width)x\(.height)"')
    echo "hypr size=$size"
    if test "$size" = 3840x2160
        set restored 1
        break
    end
end

echo '=== kernel after ==='
echo -n 'enabled='
cat $path/enabled
echo -n 'dpms='
cat $path/dpms
echo -n 'has 3840: '
grep -c '^3840x2160$' $path/modes
hyprctl monitors -j | jq '.[] | select(.name=="DP-2") | {dpmsStatus, disabled, width, height, refreshRate, scale}'

if test $restored -eq 0
    echo '4K mode did not return' >&2
end

echo '=== start shell ==='
hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-launch-shell")' >/dev/null
set ready 0
set deadline (math (date +%s) + 60)
while test (date +%s) -lt $deadline
    if omarchy-shell shell ping >/dev/null 2>&1
        set ready 1
        break
    end
    sleep 0.2
end

if test $ready -eq 0
    echo 'SHELL_NOT_READY' >&2
    exit 1
end
echo 'shell ready'

if test $restored -eq 0
    exit 1
end
