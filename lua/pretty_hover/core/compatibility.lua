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

function M.nvim_hl()
	return vim.version().minor >= 11 and vim.api.nvim_get_hl or vim.api.nvim_get_hl_by_name
end

return M
