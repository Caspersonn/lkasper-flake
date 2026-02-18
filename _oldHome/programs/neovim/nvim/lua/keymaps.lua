local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Quit all
map("n", "<space>a", ":qa!<CR>", opts)

-- NERDTree
map("n", "<space>t", ":Neotree<CR>", opts)
map("n", ",,", ":NERDTreeFind<CR>", opts)

-- Buffers
map("n", ",b", ":buffers<CR>", opts)

-- Horizontal scrolling with Shift + ScrollWheel
map("", "<S-ScrollWheelUp>", "zH", {})
map("", "<S-ScrollWheelDown>", "zL", {})

-- Horizontal scrolling: disable line wrapping
vim.o.wrap = false

-- Tabs
map("n", ",tn", ":tabnew<CR>", opts)
map("n", ",tc", ":tabclose<CR>", opts)
map("n", ",to", ":tabnext<CR>", opts)
map("n", ",tp", ":tabprevious<CR>", opts)
