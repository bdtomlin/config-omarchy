vim.pack.add({ "https://github.com/echasnovski/mini.animate" })

local animate = require("mini.animate")
animate.setup({
	cursor = { enable = false },
	resize = { enable = false },
	open = { enable = false },
	close = { enable = false },
	scroll = {
		enable = true,
		-- One short motion for the whole jump. j/k stay instant.
		-- timing = animate.gen_timing.linear({ duration = 200, unit = "total" }),
		subscroll = animate.gen_subscroll.equal({
			predicate = function(total_scroll)
				return total_scroll > 1
			end,
		}),
	},
})
