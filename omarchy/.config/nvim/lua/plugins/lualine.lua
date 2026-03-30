return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections.lualine_a = {}
      opts.sections.lualine_c[4] = { LazyVim.lualine.pretty_path({ length = 0 }) }
    end,
  },
}
