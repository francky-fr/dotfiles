require('Comment').setup({
  toggler = {
    line = 'cc',       -- Toggle comment for the current line
    block = 'cb',      -- Optional: Toggle block comments (if needed)
  },
  opleader = {
    line = 'cc',       -- Operator mode for commenting (Normal/Visual mode)
    block = 'cb',      -- Operator mode for block commenting
  },
  mappings = {
    basic = true,      -- Enable basic mappings
    extra = true,      -- Enable extra mappings (like `gcA` for commenting at end of line)
  },
})
