-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- On a scrolling workspace, Super+F toggles the focused column between the
-- half-width preset (0.49) and the last peeking preset (0.98). A maximized
-- window would cover the sliver of the next column. Other layouts keep the
-- maximize toggle.
function o.full_width()
	local act = function()
		local window = hl.get_active_window()
		local workspace = (window and window.workspace) or hl.get_active_workspace()

		if workspace and workspace.tiled_layout == "scrolling" then
			if window and (window.fullscreen or 0) ~= 0 then
				hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
			end

			local column = window and window.layout and window.layout.column
			local width = column and column.width
			-- Already at the peeking full width: step back to half. Anything else
			-- (half, thirds, or an in-between resize) steps up to full.
			local target = (width and math.abs(width - 0.98) < 0.02) and 0.49 or 0.98
			hl.dispatch(hl.dsp.layout(string.format("colresize %.2f", target)))
			return
		end

		hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized" }))
	end

	o.bind_expressions[act] = "o.full_width()"
	return act
end

o.rebind("SUPER + F", "Full or half width", o.full_width())
o.rebind("SUPER + ALT + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- A full-width window on a scrolling workspace stays in the tape. Directional
-- focus treats that state as fullscreen and jumps to the next monitor, so step
-- along the tape instead. Other layouts, and real fullscreen, stay as they are.
function o.focus_direction(direction)
	local focus = function()
		local window = hl.get_active_window()
		local workspace = (window and window.workspace) or hl.get_active_workspace()
		local scrolling = workspace and workspace.tiled_layout == "scrolling"
		local full_width = window and window.fullscreen == 1

		if scrolling and full_width and (direction == "l" or direction == "r") then
			hl.dispatch(hl.dsp.layout("focus " .. direction))
			return
		end

		hl.dispatch(hl.dsp.focus({ direction = direction }))
	end

	o.bind_expressions[focus] = string.format("o.focus_direction(%q)", direction)
	return focus
end

o.rebind("SUPER + LEFT", "Focus on left window", o.focus_direction("l"))
o.rebind("SUPER + RIGHT", "Focus on right window", o.focus_direction("r"))

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { panel = "omarchy.emojis" })

o.rebind("SUPER + H", "Focus on left window", o.focus_direction("l"))
o.rebind("SUPER + L", "Focus on right window", o.focus_direction("r"))
o.rebind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.rebind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))

o.rebind("SUPER + SHIFT + H", "Swap column left", hl.dsp.window.swap({ direction = "l" }))
o.rebind("SUPER + SHIFT + L", "Swap column right", hl.dsp.window.swap({ direction = "r" }))
o.rebind("SUPER + SHIFT + K", "Swap column left", hl.dsp.window.swap({ direction = "u" }))
o.rebind("SUPER + SHIFT + J", "Swap column right", hl.dsp.window.swap({ direction = "d" }))

o.bind("SUPER + ALT + H", "Move window to left monitor", o.workspaces.move_window_to_monitor("l"))
o.rebind("SUPER + ALT + L", "Move window to right monitor", o.workspaces.move_window_to_monitor("r"))
o.bind("SUPER + SHIFT + ALT + H", "Move workspace to left monitor", o.workspaces.move_to_monitor("l"))
o.rebind("SUPER + SHIFT + ALT + L", "Move workspace to right monitor", o.workspaces.move_to_monitor("r"))
-- o.rebind("SUPER + RIGHT", "Move window to right monitor", hl.dsp.window.move({monitor = "l"}))
-- o.rebind("SUPER + LEFT", "Move window to left monitor", hl.dsp.window.move({monitor = "r"}))

o.bind("SUPER + SHIFT + CTRL + L", "Cycle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
o.bind("SUPER + SHIFT + CTRL + K", "Keybindings", "omarchy-menu-keybindings")
o.bind("SUPER + SHIFT + CTRL + J", "Toggle window split", hl.dsp.layout("togglesplit"))

-- Cycle the focused scrolling column through 1/3, 1/2, 2/3, and full width.
o.bind("SUPER + R", "Wider column", hl.dsp.layout("colresize +conf"))
o.bind("SUPER + SHIFT + R", "Narrower column", hl.dsp.layout("colresize -conf"))
o.rebind("SUPER + SHIFT + F", "Half column", hl.dsp.layout("colresize 0.49"))

o.bind("SUPER + E", "Yazi", { tui = "yazi", focus = true })
o.rebind("SUPER + SHIFT + E", "File manager", { launch = "folio --new-window", focus = "folio" })
o.rebind("SUPER + N", "Notes", { launch = "obsidian", focus = "obsidian" })
o.rebind("SUPER + Return", "Herdr App", { launch = "herdr-app", focus = true })
o.rebind("SUPER + SHIFT + RETURN", "Terminal", o.launch_terminal())
o.rebind("SUPER + Return", "Herdr App", { launch = "herdr-app", focus = true })
o.bind("SUPER + A", "Btop", { tui = "btop", focus = true })
o.bind("SUPER + D", "DBUI", { tui = "nvim -c DBUI", focus = true })
o.bind("SUPER + SHIFT + D", "Todoist", { webapp = "https://app.todoist.com", focus = "todoist" })
o.rebind("SUPER + SHIFT + B", "Default bindings", "omarchy-launch-tui nvim /usr/share/omarchy/default/hypr/bindings")
-- o.rebind("SUPER + SHIFT + W", "Wake external display", "~/config-omarchy/bin/wake-external-monitor.fish")
o.bind("SUPER + M", "Wake external display", "~/config-omarchy/bin/wake2.fish")

-- Raise the default browser if a window exists; otherwise launch it.
local focus_browser = [[
desktop=$(omarchy-cmd-default-browser) || exit 1
class=
IFS=: read -ra dirs <<< "${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
for dir in "${dirs[@]}"; do
  entry="$dir/applications/$desktop"
  [ -f "$entry" ] || continue
  class=$(sed -n 's/^StartupWMClass=//p' "$entry" | head -1)
  break
done
class=${class:-${desktop%.desktop}}
omarchy-hyprland-focus-app "^${class}$" || exec omarchy-launch-browser
]]

o.bind("SUPER + B", "Browser", focus_browser)
-- BEGIN CHROMA SHORTCUT SETUP v1 (managed; do not edit)
require("hypr.chroma")
-- END CHROMA SHORTCUT SETUP
-- OmaDBngin panel (dbctl unbind removes these two lines)
o.bind("SUPER + ALT + D", "OmaDBngin", "qs -p /usr/share/omarchy/shell ipc call blackcode.omadbngin toggle")
-- OmaTablePlus (omatableplus uninstall removes these two lines)
o.bind("SUPER + ALT + T", "OmaTablePlus", "/home/bryan/.config/omarchy/plugins/blackcode.omatableplus/app/omatableplus")
