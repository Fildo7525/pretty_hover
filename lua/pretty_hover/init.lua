M = {}

M.winnr = 0
M.bufnr = 0
M.config = {}

local api = vim.api
local h_util = require("pretty_hover.util")

--- Parses the response from the server and displays the hover information converted to markdown.
M.hover = function()
	local util = require('vim.lsp.util')
	local params = util.make_position_params()


	-- check if this popup is focusable and we need to focus
	if M.winnr ~= 0 then
		if not api.nvim_win_is_valid(M.winnr) then
			M.winnr = 0
			M.bufnr = 0
		else
			api.nvim_set_current_win(M.winnr)
			return
		end
	end

	vim.lsp.buf_request_all(0, 'textDocument/hover', params, function(responses)
		for _, response in pairs(responses) do
			if response.result and response.result.contents then

				local hover_text = response.result.contents.value
				-- Convert Doxygen comments to Markdown format
				local tbl = h_util.convert_to_markdown(hover_text, M.config)

				local bufnr, winnr = vim.lsp.util.open_floating_preview(tbl, 'markdown', {border = M.config.border, focusable = true})
				M.bufnr = bufnr
				M.winnr = winnr

				vim.keymap.set('n', 'q', function ()
					api.nvim_win_close(winnr, true)
					M.winnr = 0
					M.bufnr = 0
				end, { buffer = bufnr, silent = true, nowait = true })
			end
		end
	end)
end

M.setup = function(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", require("pretty_hover.config"), opts)
end

return M
