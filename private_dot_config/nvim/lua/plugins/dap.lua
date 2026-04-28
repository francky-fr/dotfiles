return {
  {
    "mfussenegger/nvim-dap",
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
	    require("dap-setup")
	    require("dapui").setup({
		    layouts = {
			    {
				    elements = {
					    { id = "repl",        size = 0.30 },
					    { id = "console",     size = 0.20 },
					    { id = "watches",     size = 0.25 },
					    { id = "stacks",      size = 0.15 },
					    { id = "breakpoints", size = 0.10 },
				    },
				    size = 40,
				    position = "left",
			    },
			    {
				    elements = {
					    "scopes",
				    },
				    size = 15,
				    position = "bottom",
			    },
		    },

		    controls = {
			    enabled = true,
			    element = "repl",
		    },

		    floating = {
			    border = "rounded",
			    mappings = {
				    close = { "q", "<Esc>" },
			    },
		    },
		    expand_lines = false
	    })
    end,
  },
}

