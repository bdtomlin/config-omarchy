-- Pre-warm the sidecar's Python deps on install/update.
-- Register this before vim.pack.add so the initial install is seen.
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		if ev.data.spec.name ~= "neocursor.nvim" then
			return
		end
		if ev.data.kind == "install" or ev.data.kind == "update" then
			vim.system({ "uv", "run", "--with", "httpx[http2]", "python", "-c", "import httpx" })
		end
	end,
})

vim.pack.add({ "https://github.com/teocns/neocursor.nvim" })

-- Defer until the first insert so the sidecar stays idle while reading files.
vim.api.nvim_create_autocmd("InsertEnter", {
	once = true,
	callback = function()
		require("neocursor").setup({})
	end,
})
