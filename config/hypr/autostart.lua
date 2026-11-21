-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- External DP stays in standby after wake when its real mode list is gone
-- and Hyprland still reports the old mode as lit.
o.launch_on_start(os.getenv("HOME") .. "/.config/omarchy/bin/wake-external-display")
