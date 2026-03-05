return {
	"folke/snacks.nvim",
	opts = {
		scroll = {
			enabled = false, -- Disable scrolling animations
		},
		picker = {
			sources = {
				explorer = {
					hidden = true,
					ignored = true,
				},
				grep = {
					hidden = true,
					ignored = true,
				},
				files = {
					hidden = true,
					ignored = true,
				},
				git_files = {
					untracked = true,
				},
			},
		},
	},
}
