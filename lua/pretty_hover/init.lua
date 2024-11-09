local M = {}

M.config = {}

local h_util = require("pretty_hover.core.util")
local number = require("pretty_hover.number")

local function parse_response_contents(contents)
	local hover_text = contents.value;
	-- vtsls workaround, this lsp does not contain value in the contents. It's just pure text.
	if type(contents) == "string" then
		hover_text = contents
	end

	if hover_text ~= nil then
		return hover_text
	end

	-- typescript-tools.nvim workaround
	-- Add a test in case there are no contents.
	if not pcall(function() hover_text = contents[1].value end) then
		return
	end

	for i = 2, #contents do
		if type(contents[i]) ~= "string" then
			vim.notify("Unexpected item type found in hover request's response.\n" ..
				"Please report an issue on github: https://github.com/Fildo7525/pretty_hover",
				vim.log.levels.ERROR)
			break
		end
		hover_text = hover_text .. contents[i]
	end
	return hover_text
end

--- Function that will be used in hover request invoked by lsp.
---@param responses table Table of responses from the server.
local function local_hover_request(responses)
	local wasEmpty = true
	for _, response in pairs(responses) do
		if response.result and response.result.contents then
			wasEmpty = false
			local contents = response.result.contents

			-- We have to do this because of java. Sometimes is the value parameter split
			-- into two chunks. Leaving the rest of the hover message as the second argument
			-- in the received table.
			if contents.language == "java" then
				for _, content in pairs(contents) do
					local hover_text = content.value or content
					if not hover_text then
						vim.notify("There is no text to be displayed", vim.log.levels.INFO)
						return
					end

					h_util.open_float(hover_text, M.config)
				end
			else
				local hover_text = parse_response_contents(response.result.contents)
				if not hover_text then
					vim.notify("There is no text to be displayed", vim.log.levels.INFO)
					return
				end

				h_util.open_float(hover_text, M.config)
			end
		end
	end

	if wasEmpty then
		local hover_text = number.get_number_representations()
		if not hover_text then
			return
		end

		h_util.open_float(hover_text, M.config)
	end
end

--- Parses the response from the server and displays the hover information converted to markdown.
function M.hover()
	local util = require("vim.lsp.util")
	local params = util.make_position_params()

	-- Check if the server for this file type exists and supports hover.
	local client = h_util.get_current_active_clent()
	local hover_support_present = client and client.capabilities.textDocument.hover

	if not client or not hover_support_present then
		vim.notify("There is no client for this filetype or the client does not support the hover capability.", vim.log.levels.WARN)
		return
	end

	vim.lsp.buf_request_all(0, "textDocument/hover", params, local_hover_request)
end

--- Setup the plugin to use the given options.
---@param config table Options to be set for the plugin.
function M.setup(config)
	config = config or {}
	M.config = vim.tbl_deep_extend("force", require("pretty_hover.config"), config)
	require("pretty_hover.highlight").setup_colors(M.config)

	if M.config.toggle then
		local id = vim.api.nvim_create_augroup("pretty_hover_augroup", {
			clear = true,
		})
		vim.api.nvim_create_autocmd({ "CursorMoved" }, {
			callback = function()
				require("pretty_hover.core.util").close_float()
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
