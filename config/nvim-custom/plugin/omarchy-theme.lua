-- Follow the Omarchy theme. The live spec is the lazy-shaped file Omarchy
-- writes at ~/.local/state/omarchy/current/theme/neovim.lua. This config has
-- no lazy.nvim, so vim.pack installs the colorscheme plugin and a file
-- watcher applies it on startup and whenever that file changes.

local state_dir = vim.env.HOME .. "/.local/state/omarchy/current"
local theme_file = state_dir .. "/theme/neovim.lua"
local legacy_file = vim.env.HOME .. "/.config/omarchy/current/theme/neovim.lua"

local state = _G.__omarchy_theme or {
  handles = {},
  timer = nil,
  fingerprint = nil,
  applying = false,
}
_G.__omarchy_theme = state

local function theme_path()
  if vim.fn.filereadable(theme_file) == 1 then
    return theme_file
  end
  if vim.fn.filereadable(legacy_file) == 1 then
    return legacy_file
  end
  return theme_file
end

local function fingerprint(path)
  if vim.fn.filereadable(path) ~= 1 then
    return ""
  end
  return vim.fn.sha256(table.concat(vim.fn.readfile(path), "\n"))
end

local function normalize_repo(repo)
  return repo
    :gsub("^https://github.com/", "")
    :gsub("^http://github.com/", "")
    :gsub("^git@github%.com:", "")
    :gsub("%.git$", "")
end

local function github_src(repo)
  if repo:match("^%w+://") or repo:match("^git@") then
    return repo
  end
  return "https://github.com/" .. normalize_repo(repo)
end

local function coerce(entry)
  if type(entry) == "string" then
    return { entry }
  end
  if type(entry) == "table" then
    return entry
  end
end

local function to_pack(entry)
  local spec = coerce(entry)
  local repo = spec and spec[1]
  if type(repo) ~= "string" or repo:find("LazyVim", 1, true) then
    return nil
  end
  local base = normalize_repo(repo):match("([^/]+)$") or repo
  local name = spec.name or base
  local version = spec.branch or spec.tag or spec.commit or spec.version
  local src = github_src(repo)
  -- Omarchy 4 themes are aether v3. Stock specs name either fork.
  if base == "aether.nvim" then
    src = "https://github.com/omacom/aether.nvim"
    name = spec.name or "aether"
    version = version or "v3"
  end
  return {
    src = src,
    name = name,
    version = version,
    opts = spec.opts,
  }
end

local function unload_lua(dir)
  local root = dir .. "/lua"
  if vim.fn.isdirectory(root) ~= 1 then
    return
  end
  local function walk(path, prefix)
    for name, kind in vim.fs.dir(path) do
      local child = path .. "/" .. name
      if name == "init.lua" then
        local mod = prefix:gsub("%.$", "")
        if mod ~= "" then
          package.loaded[mod] = nil
          package.preload[mod] = nil
        end
      elseif (kind == "file" or kind == "link") and name:sub(-4) == ".lua" then
        package.loaded[prefix .. name:sub(1, -5)] = nil
        package.preload[prefix .. name:sub(1, -5)] = nil
      elseif kind == "directory" then
        walk(child, prefix .. name .. ".")
      end
    end
  end
  walk(root, "")
end

local function plugin_info(name)
  local ok, list = pcall(vim.pack.get, { name }, { info = false })
  if not ok then
    return nil
  end
  return list[1]
end

local function setup_plugin(pack)
  if type(pack.opts) ~= "table" then
    return
  end
  -- aether's own watcher also applies Omarchy theme files and notifies when
  -- the colorscheme plugin is not loaded yet. This config owns that switch.
  if pack.name == "aether" then
    local hot = _G.__aether_hotreload_state or {}
    hot.did_setup = true
    _G.__aether_hotreload_state = hot
  end
  local module = pack.name
    :gsub("%.nvim$", "")
    :gsub("%.vim$", "")
    :gsub("%-nvim$", "")
    :gsub("%-vim$", "")
    :gsub("%-neovim$", "")
  local ok, plugin = pcall(require, module)
  if not ok or type(plugin) ~= "table" or type(plugin.setup) ~= "function" then
    return
  end
  local ran, err = pcall(plugin.setup, pack.opts)
  if not ran then
    vim.notify("Omarchy theme: " .. module .. ".setup: " .. tostring(err), vim.log.levels.WARN)
  end
end

local function background_for(colorscheme)
  if colorscheme:find("light") or colorscheme:find("latte") or colorscheme:find("dawn") or colorscheme:find("day") or colorscheme:find("lotus") then
    return "light"
  end
  return "dark"
end

local function extra_opts(lazy_opts)
  if type(lazy_opts) ~= "table" then
    return nil
  end
  local opts = {}
  local any = false
  for key, value in pairs(lazy_opts) do
    if key ~= "colorscheme" then
      opts[key] = value
      any = true
    end
  end
  if any then
    return opts
  end
end

local function read_spec(path)
  if vim.fn.filereadable(path) ~= 1 then
    return nil, "theme file is missing"
  end
  local ok, spec = pcall(dofile, path)
  if not ok then
    return nil, tostring(spec)
  end
  if type(spec) ~= "table" then
    return nil, "theme file did not return a spec"
  end
  local colorscheme
  local theme_entry
  local lazy_opts
  for _, entry in ipairs(spec) do
    if type(entry) == "table" and entry[1] == "LazyVim/LazyVim" and type(entry.opts) == "table" then
      colorscheme = entry.opts.colorscheme
      lazy_opts = entry.opts
    elseif type(entry) == "table" and type(entry[1]) == "string" and not theme_entry and not tostring(entry[1]):find("LazyVim", 1, true) then
      theme_entry = entry
    end
  end
  if type(colorscheme) ~= "string" or colorscheme == "" then
    return nil, "theme file has no colorscheme"
  end
  return {
    colorscheme = colorscheme,
    theme_entry = theme_entry,
    lazy_opts = lazy_opts,
  }
end

local function ensure(packs)
  local specs = {}
  for _, pack in ipairs(packs) do
    local spec = { src = pack.src, name = pack.name }
    if pack.version then
      spec.version = pack.version
    end
    specs[#specs + 1] = spec
  end
  if #specs == 0 then
    return true
  end
  local ok, err = pcall(vim.pack.add, specs, { confirm = false, load = true })
  if not ok then
    vim.notify("Omarchy theme: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return true
end

local function apply_colorscheme(colorscheme)
  vim.o.background = background_for(colorscheme)
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
  if not ok then
    vim.notify("Omarchy theme: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  vim.cmd("redraw")
  return true
end

local function apply(path, force)
  if state.applying then
    return
  end
  path = path or theme_path()
  local fp = fingerprint(path)
  if not force and path == theme_path() and fp ~= "" and fp == state.fingerprint then
    return
  end

  state.applying = true
  local ok, err = pcall(function()
    local spec, read_err = read_spec(path)
    if not spec then
      -- Theme set rewrites the file in place. A read during that window
      -- should wait and try once more before falling back or reporting.
      if not force then
        vim.defer_fn(function()
          apply(path, true)
        end, 300)
        return
      end
      if path == theme_path() and vim.g.colors_name == nil then
        require("kanagawa-theme").setup()
        apply_colorscheme("kanagawa-dragon")
      end
      error(read_err or "unreadable theme")
    end

    local packs = {}
    local seen = {}
    local function push(entry)
      local pack = to_pack(entry)
      if pack and not seen[pack.name] then
        seen[pack.name] = true
        packs[#packs + 1] = pack
      end
    end
    if spec.theme_entry and type(spec.theme_entry.dependencies) == "table" then
      for _, dep in ipairs(spec.theme_entry.dependencies) do
        push(dep)
      end
    end
    push(spec.theme_entry)

    if not ensure(packs) then
      return
    end

    local theme_pack = packs[#packs]
    if theme_pack then
      local info = plugin_info(theme_pack.name)
      if info then
        unload_lua(info.path)
      end
    end

    if spec.colorscheme:match("^kanagawa") then
      require("kanagawa-theme").setup()
    elseif theme_pack then
      theme_pack.opts = theme_pack.opts or extra_opts(spec.lazy_opts)
      setup_plugin(theme_pack)
    end

    if apply_colorscheme(spec.colorscheme) and path == theme_path() then
      state.fingerprint = fp
    end
  end)
  state.applying = false
  if not ok then
    vim.notify("Omarchy theme: " .. tostring(err), vim.log.levels.ERROR)
  end
end

local function schedule()
  local existing = state.timer
  if existing then
    pcall(function()
      if not existing:is_closing() then
        existing:stop()
        existing:close()
      end
    end)
    state.timer = nil
  end
  state.timer = vim.defer_fn(function()
    state.timer = nil
    apply()
  end, 400)
end

local function stop_watch(key)
  local handle = state.handles[key]
  if not handle then
    return
  end
  pcall(function()
    if not handle:is_closing() then
      handle:stop()
      handle:close()
    end
  end)
  state.handles[key] = nil
end

local function watch_file(path)
  stop_watch(path)
  if not vim.uv or vim.fn.filereadable(path) ~= 1 then
    return
  end
  local handle = vim.uv.new_fs_event()
  if not handle then
    return
  end
  local ok = handle:start(path, {}, vim.schedule_wrap(function()
    stop_watch(path)
    vim.defer_fn(function()
      watch_file(path)
    end, 50)
    schedule()
  end))
  if ok == 0 then
    state.handles[path] = handle
  else
    handle:close()
  end
end

local function watch_dir(dir, names, on_event)
  stop_watch(dir)
  if not vim.uv or vim.fn.isdirectory(dir) ~= 1 then
    return
  end
  local filter = {}
  for _, name in ipairs(names) do
    filter[name] = true
  end
  local handle = vim.uv.new_fs_event()
  if not handle then
    return
  end
  local ok = handle:start(dir, {}, vim.schedule_wrap(function(_, filename)
    if filename and not filter[filename] then
      return
    end
    on_event()
  end))
  if ok == 0 then
    state.handles[dir] = handle
  else
    handle:close()
  end
end

local function arm()
  local path = theme_path()
  watch_file(path)
  watch_dir(vim.fn.fnamemodify(path, ":h"), { "neovim.lua" }, function()
    watch_file(theme_path())
    schedule()
  end)
  watch_dir(state_dir, { "theme", "theme.generation", "theme.name" }, function()
    vim.schedule(function()
      arm()
      schedule()
    end)
  end)
end

local group = vim.api.nvim_create_augroup("OmarchyTheme", { clear = true })
vim.api.nvim_create_autocmd("FocusGained", {
  group = group,
  callback = schedule,
})

vim.api.nvim_create_user_command("OmarchyTheme", function(opts)
  local path = opts.args ~= "" and opts.args or nil
  apply(path, true)
end, { nargs = "?", complete = "file", desc = "Apply the current Omarchy theme" })

arm()
apply()
