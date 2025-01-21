local api = vim.api
local hl = require("pretty_hover.highlight")
local compatibility = require("pretty_hover.core.compatibility")

local M = {}

M.winnr = 0
M.bufnr = 0

--- Check if a table contains desired element. vim.tbl_contains does not work for all cases.
---@param tbl table Table to be checked.
---@param el string Element to be checked.
---@return boolean True if the table contains the element, false otherwise.
function M.tbl_contains(tbl, el)
	if not el then
		return false
	end
	if not tbl then
		return false
	end

	for _, v in pairs(tbl) do
		if el:find(v) then
			return true
		end
	end
	return false
end

--- Checks the table for the desired element. If the element is found, it is returned, otherwise nil is returned.
---@param tbl table Table to be checked.
---@param el string Element to be checked for.
---@return string The element if it is found, nil otherwise.
function M.find(tbl, el)
	if not el then
		return ""
	end
	if not tbl then
		return ""
	end

	for _, v in pairs(tbl) do
		if el:find(v) then
			return el
		end
	end
	return ""
end

--- Count the printable strings in the table.
---@param tbl table Table of string from hover.
---@return number Number of printable lines.
function M.printable_table_size(tbl)
	local count = 0
	for _, el in pairs(tbl) do
		if el and not el:gmatch("```")() then
			count = count + 1
		end
	end
	return count
end

--- Splits a string into a table of strings.
---@param toSplit string String to be split.
---@param separator string|nil The separator. If not defined, the separator is set to "%S+".
---@return table Table of strings split by the separator.
function M.split(toSplit, separator)
	local indentation = nil
	local text_start_detected = false

	if separator == nil then
		indentation = string.match(toSplit, "^%s+")
		separator = "%S+"
	end

	if toSplit == nil then
		return {}
	end

	local chunks = {}
	if indentation ~= nil and indentation:len() > 0 then
		table.insert(chunks, indentation)
	end

	for substring in toSplit:gmatch(separator) do
		-- These both cases are here because of python server. Some servers have '.... ' in front of every line and some
		-- servers surround the whole message with '```text' and '```'. This is a workaround for that.
		if substring:sub(1, 2) == ". " then
			substring = substring:sub(5)
		end

		if substring == "```text" then
			text_start_detected = true
			goto continue
		end

		table.insert(chunks, substring)
		::continue::
	end

	-- If text start is detected (```text), remove the previoius to the last element.
	if text_start_detected then
		chunks[#chunks-2] = " "
	end

	return chunks
end

--- Join the elements of a table into a string with a delimiter.
---@param tbl table Table to be joined.
---@param delim string Delimiter to be used.
---@return string Joined string.
function M.join_table(tbl, delim)
	local result = ""
	for idx, chunk in pairs(tbl) do
		result = result .. chunk
		if idx ~= #tbl then
			result = result .. delim
		end
	end
	return result
end

--- This function checks all the active clients for current buffer and returns the active client that supports the current file type.
---@return table|nil Active client for the current buffer or nil if there is no active client.
function M.get_current_active_clent()
	for _, client in ipairs(compatibility.get_clients()) do
		if M.tbl_contains(client.config.filetypes, vim.bo.filetype) then
			return client
		end
	end
	return nil
end

--- Close the opened floating window.
function M.close_float()
	-- Safeguard around accidentally calling close when there is no pretty_hover window open
	if M.winnr == 0 and M.bufnr == 0 then
		return
	end

	-- Before closing the window, check if it is still valid.
	if not api.nvim_win_is_valid(M.winnr) then
		M.winnr = 0
		M.bufnr = 0
		return
	end

	api.nvim_win_close(M.winnr, true)
	M.winnr = 0
	M.bufnr = 0
end

--- Opens a floating window with the documentation transformed from doxygen to markdown.
---@param hover_text string Text to be converted.
---@param config table Table of options to be used for the conversion to the markdown language.
function M.open_float(hover_text, config)
	if not hover_text or hover_text:len() == 0 then
		-- There is nothing to display, quit out early
		vim.notify("No information available", vim.log.levels.INFO)
		return
	end

	-- Convert Doxygen comments to Markdown format
	local out = require("pretty_hover.parser").parse(hover_text)
	if #out.text == 0 then
		vim.notify("No information available", vim.log.levels.INFO)
		return
	end

	if config.toggle and M.winnr ~= 0 then
		M.close_float()
		return
	end

	local language = 'markdown'
	if config.one_liner then
		language = vim.bo.filetype
	end

	M.bufnr, M.winnr = vim.lsp.util.open_floating_preview(out.text, language, {
		border = config.border,
		focusable = true,
		focus = true,
		focus_id = "pretty-hover",
		wrap = config.wrap,
		wrap_at = config.max_width and config.max_width - 2 or nil,
		max_width = config.max_width,
		max_height = config.max_height,
	})

	vim.wo[M.winnr].foldenable = false
	vim.bo[M.bufnr].modifiable = false
	vim.bo[M.bufnr].bufhidden = 'wipe'

	hl.apply_highlight(config, out.highlighting, M.bufnr)

	vim.keymap.set('n', 'q', M.close_float, {
		buffer = M.bufnr,
		silent = true,
		nowait = true,
	})
end

return M

