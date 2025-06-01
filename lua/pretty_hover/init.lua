local api = vim.api
local cfg = require("pretty_hover.config")
local h_util = require("pretty_hover.core.util")
local local_hover_request = require("pretty_hover.local_request").local_hover_request

local M = {}

--- Parses the response from the server and displays the hover information converted to markdown.
function M.hover(config)
	local params = vim.lsp.util.make_position_params(0, 'utf-16')

	-- Check if the server for this file type exists and supports hover.
	local client = h_util.get_current_active_client()
	local hover_support_present = client and client.capabilities.textDocument.hover

	if not client or not hover_support_present then
		vim.notify("There is no client for this filetype or the client does not support the hover capability.", vim.log.levels.WARN)
		return
	end

	config = config or {}
	cfg:instance().hover_cnf = config

	vim.lsp.buf_request_all(0, "textDocument/hover", params, local_hover_request)
end

--- Setup the plugin to use the given options.
---@param config table Options to be set for the plugin.
function M.setup(config)
	config = cfg:instance(config)

	if config.toggle then
		local id = api.nvim_create_augroup("pretty_hover_augroup", {
			clear = true,
		})
		api.nvim_create_autocmd({ "CursorMoved" }, {
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

function M.get_config()
	return cfg:instance()
end

return M
