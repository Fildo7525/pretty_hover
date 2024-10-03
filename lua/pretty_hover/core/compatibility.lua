local M = {}

--- Function that encapsulates the changes in nvim api for getting the active clients.
---
--- @return table List of active clients.
function M.get_clients()
	if vim.version().minor >= 11 then
		return vim.lsp.get_clients()
	else
		return vim.lsp.get_active_clients()
	end
end

function M.nvim_hl(name, fg)
	if vim.version().minor >= 11 then
		local ns = vim.api.nvim_get_namespaces()["pretty_hover_ns"]
		return vim.api.nvim_get_hl(ns, {name = name})
	end

	return vim.api.nvim_get_hl_by_name(name, fg)
end

return M
