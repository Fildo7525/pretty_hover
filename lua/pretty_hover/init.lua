local M = {}

M.config = {}

local h_util = require("pretty_hover.util")

--- Function that will be used in hover request invoked by lsp.
---@param responses table Table of responses from the server.
local function local_hover_request(responses)
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
				-- typescript-tools.nvim workaround
				if hover_text == nil then
					hover_text = response.result.contents[1].value
					for i = 2, #response.result.contents do
						if type(response.result.contents[i]) ~= "string" then
							vim.notify("Unexpected item type found in hover request's response.\n" ..
								"Please report an issue on github: https://github.com/Fildo7525/pretty_hover",
								vim.log.levels.ERROR)
							break
						end
						hover_text = hover_text .. response.result.contents[i]
					end
				end
				h_util.open_float(hover_text, M.config)
			end
		end
	end
end

--- Parses the response from the server and displays the hover information converted to markdown.
function M.hover()
	local util = require("vim.lsp.util")
	local params = util.make_position_params()

	-- Check if the server for this filetype exists and supports hover.
	local client = h_util.get_current_active_clent()
	if not client then
		vim.notify("The hover action is not supported in this filetype", vim.log.levels.INFO)
		return
	end

	vim.lsp.buf_request_all(0, "textDocument/hover", params, local_hover_request)
end

--- Setup the plugin to use the given options.
---@param opts table Options to be set for the plugin.
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", require("pretty_hover.config"), opts)
	require("pretty_hover.highlight").setup_colors(M.config)

	if M.config.toggle then
		local id = vim.api.nvim_create_augroup("pretty_hover_augroup", {
			clear = true,
		})
		vim.api.nvim_create_autocmd({ "CursorMoved" }, {
			callback = function()
				require("pretty_hover.util").close_float()
			end,
			group = id,
		})
	end
end

--- Close the opened floating window.
function M.close()
	h_util.close_float()
end

return M
