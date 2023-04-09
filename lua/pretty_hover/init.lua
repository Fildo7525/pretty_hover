local M = {}

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
				local contents = response.result.contents

				if type(contents) == "table" then
					for _, content in pairs(contents) do
						local hover_text = content.value or content
						h_util.open_float(hover_text, M.config)
					end
				else
					local hover_text = response.result.contents.value
					h_util.open_float(hover_text, M.config)
				end
			end
		end
	end)
end

M.setup = function(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", require("pretty_hover.config"), opts)
end

return M
