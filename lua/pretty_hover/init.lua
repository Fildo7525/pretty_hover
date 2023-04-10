local M = {}

M.config = {}

local api = vim.api
local h_util = require("pretty_hover.util")

--- Parses the response from the server and displays the hover information converted to markdown.
M.hover = function()
	local util = require('vim.lsp.util')
	local params = util.make_position_params()


	-- check if this popup is focusable and we need to focus
	if h_util.winnr ~= 0 then
		if not api.nvim_win_is_valid(h_util.winnr) then
			h_util.winnr = 0
			h_util.bufnr = 0
		else
			api.nvim_set_current_win(h_util.winnr)
			return
		end
	end

	vim.lsp.buf_request_all(0, 'textDocument/hover', params, function(responses)
		for _, response in pairs(responses) do
			if response.result and response.result.contents then
				local contents = response.result.contents

				-- We have to do this because of java. Sometimes is the value parameter split
				-- into two chunks. Leaving the rest of the hover message as the second argument
				-- in the received table.
				if contents.language == "java" then
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

M.close = function()
	h_util.close_float()
end

return M
