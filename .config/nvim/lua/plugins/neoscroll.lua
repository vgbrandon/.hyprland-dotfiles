return {
	"karb94/neoscroll.nvim",
	opts = {},

	-- DEFAULT MAPPINGS
	-- The following mappings are valid for normal, visual and select mode.

	-- Key     Function ~
	-- <C-u>    scroll(-vim.wo.scroll, true, 350)
	-- <C-d>    scroll( vim.wo.scroll, true, 350)
	-- <C-b>    scroll(-vim.api.nvim_win_get_height(0), true, 550)
	-- <C-f>    scroll( vim.api.nvim_win_get_height(0), true, 550)
	-- <C-y>    scroll(-0.10, false, 100)
	-- <C-e>    scroll( 0.10, false, 100)
	-- zt      zt(200)
	-- zz      zz(200)
	-- zb      zb(200)
}
