-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
-- Your own gestures replace Omarchy's defaults.
omarchy_default_gestures = false

require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Taller Quake console (the drop-down agent). Stock share in
-- /usr/share/omarchy/default/hypr/qconsole.lua is 0.5, and that script
-- rewrites the workspace rule whenever the console opens. This runs after
-- it and keeps the panel at three quarters of the usable screen.
-- Width stays on the stock formula (half the screen, twice as wide as tall),
-- so only the height changes.
local console_share = 0.75
local console_stock_share = 0.5
local console_box = 2
local CONSOLE = "special:qconsole"
local console_beside, console_below = nil, nil

local function console_alone()
	local tiled = 0
	for _, window in ipairs(hl.get_workspace_windows(CONSOLE)) do
		if not window.floating then
			tiled = tiled + 1
		end
	end
	return tiled <= 1
end

local function console_fit(monitor)
	if not monitor or not monitor.scale or monitor.scale <= 0 then
		return
	end

	local width, height = monitor.width, monitor.height
	if monitor.transform % 2 == 1 then
		width, height = height, width
	end

	local reserved = monitor.reserved
	height = height / monitor.scale - reserved.top - reserved.bottom
	width = width / monitor.scale - reserved.left - reserved.right

	local tall = math.floor(height * console_share)
	local wide = width
	if console_alone() then
		local stock_tall = math.floor(height * console_stock_share)
		wide = math.min(width, stock_tall * console_box)
	end

	local side = math.floor((width - wide) / 2)
	local bottom = math.floor(height - tall)
	if console_beside == side and console_below == bottom then
		return
	end
	console_beside, console_below = side, bottom

	hl.workspace_rule({
		workspace = CONSOLE,
		gaps_in = 0,
		gaps_out = { top = 0, right = side, bottom = bottom, left = side },
		no_border = true,
	})
	hl.exec_scheduled_prop_refresh_immediately()
end

local function console_monitor()
	local ws = hl.get_workspace(CONSOLE)
	local mon = ws and ws.visible and ws.monitor
	if mon and mon.scale and mon.scale > 0 then
		return mon
	end
	return hl.get_active_monitor()
end

local function console_refit(monitor)
	console_fit(monitor or console_monitor())
end

console_refit()

hl.on("monitor.layout_changed", function()
	console_refit()
end)

hl.on("monitor.focused", function()
	console_refit()
end)

hl.on("workspace.special_active", function(ws, mon)
	if ws and ws.name == CONSOLE then
		console_refit(mon)
	end
end)

hl.on("workspace.move_to_monitor", function(ws, mon)
	if ws and ws.name == CONSOLE then
		console_refit(mon)
	end
end)

-- Only while the console is on screen. Opening it refits through
-- workspace.special_active, and the stock script does the same.
local function console_recount()
	local ws = hl.get_workspace(CONSOLE)
	if ws and ws.visible then
		console_refit()
	end
end

hl.on("window.open", console_recount)
hl.on("window.destroy", console_recount)
hl.on("window.move_to_workspace", console_recount)
hl.on("window.update_rules", console_recount)

hl.env("GRIDCRAFT_WAYLAND", "1")
hl.env("DECKCRAFT_WAYLAND", "1")
hl.env("WORDCRAFT_WAYLAND", "1")
