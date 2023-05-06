local api = vim.api

local M = {}

M.winnr = 0
M.bufnr = 0

--- Splits a string into a table of strings.
---@param toSplit string String to be split.
---@param separator string|nil The separator. If not defined, the separator is set to "%S+".
---@return table Table of strings split by the separator.
M.split = function(toSplit, separator)
	if separator == nil then
		separator = "%S+"
	end

	if toSplit == nil then
		return {}
	end

	local chunks = {}
	for substring in toSplit:gmatch(separator) do
		table.insert(chunks, substring)
	end
	return chunks
end

--- Join the elemnets of a table into a string with a delimiter.
---@param tbl table Table to be joined.
---@param delim string Delimiter to be used.
---@return string Joined string.
M.joint_table = function(tbl, delim)
	local result = ""
	for idx, chunk in pairs(tbl) do
		result = result .. chunk
		if idx ~= #tbl then
			result = result .. delim
		end
	end
	return result
end

--- Check if a table contains desired element. vim.tbl_contains does not work for all cases.
---@param tbl table Table to be checked.
---@param el string Element to be checked.
---@return boolean True if the table contains the element, false otherwise.
M.tbl_contains = function(tbl, el)
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

--- Converts all the references to markdown text.
---@param tabled_line table Words to be checked.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@return table Converted line to markdown.
M.check_line_for_references = function (tabled_line, opts)
	for index, word in ipairs(tabled_line) do
		if M.tbl_contains(opts.references, word) then
			tabled_line[index] = opts.stylers.references .. tabled_line[index+1] .. opts.stylers.references
			table.remove(tabled_line, index + 1)
		end
	end
	vim.print(tabled_line)

	return tabled_line
end

--- This function checks all the active clients for current buffer and returns the active client that supports the current filetype.
---@return table|nil Active client for the current buffer or nil if there is no active client.
M.get_current_active_clent = function()
	for _, client in ipairs(vim.lsp.get_active_clients()) do
		if M.tbl_contains(client.config.filetypes, vim.bo.filetype) then
			return client
		end
	end
	return nil
end

--- Transforms the line from doxygen stype into markdown
---@param line string Line to be transformed.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@param control table Table of control variables to be used for the conversion to the markdown language.
-- @return table Table of strings from doxygen to markdown.
M.transform_line = function (line, opts, control)
	local result = {}
	local tbl = M.split(line)
	local el = tbl[1]
	local insertEmptyLine = false

	if M.tbl_contains(opts.line, el) then
		table.remove(tbl, 1)
		tbl[1] = "**" .. tbl[1]
		tbl[#tbl] = tbl[#tbl] .. "**"
		insertEmptyLine = true;

	elseif M.tbl_contains(opts.header, el) then
		tbl[1] = opts.stylers.header
		insertEmptyLine = true;

	elseif M.tbl_contains(opts.word, el) then
		tbl[2] = opts.stylers.word .. tbl[2] .. opts.stylers.word
		table.remove(tbl, 1)

		if control.firstParam and el:find("[@\\]param") then
			control.firstParam = false
			table.insert(result, "---")
			table.insert(result, "**Parameters**")
		elseif control.firstSee and el:find("[@\\]see") then
			control.firstSee = false
			table.insert(result, "---")
			table.insert(result, "**See**")
		end

	elseif M.tbl_contains(opts.return_statement, el) then
		table.insert(result, "")
		tbl[1] = "**Return**"
		line = M.joint_table(tbl, " ")
	elseif M.tbl_contains(opts.listing, el) then
		tbl[1] = opts.stylers.listing
	end

	tbl = M.check_line_for_references(tbl, opts)
	line = M.joint_table(tbl, " ")
	table.insert(result, line)
	if insertEmptyLine then
		table.insert(result, "")
	end
	return result
end

--- Converts a string returned by response.result.contents.value from vim.lsp[textDocument/hover] to markdown.
---@param toConvert string Documentation of the string to be converted.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@return table Converted table of strings from doxygen to markdown.
M.convert_to_markdown = function(toConvert, opts)
	local result = {}
	local control = {
		firstParam = true,
		firstSee = true,
	}

	local chunks = M.split(toConvert, "([^\n]*)\n?")
	if #chunks == 0 then
		return result
	end

	for _, chunk in pairs(chunks) do
		local toAdd = M.transform_line(chunk, opts, control)
		vim.list_extend(result, toAdd)
	end
	return result
end

--- Close the opened floating window.
M.close_float = function()
	-- Safeguard around accidentally calling close when there is no pretty_hover window open
	if M.winnr == 0 and M.bufnr == 0 then
		return
	end

	-- Befor closing the window, check if it is still valid.
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
M.open_float = function(hover_text, config)
	if not hover_text or hover_text:len() == 0 then
		-- There is nothing to display, quit out early
		vim.notify("No information available", vim.log.levels.INFO)
		return
	end

	-- Convert Doxygen comments to Markdown format
	local tbl = M.convert_to_markdown(hover_text, config)
	if #tbl == 0 then
		vim.notify("No information available", vim.log.levels.INFO)
		return
	end

	local bufnr, winnr = vim.lsp.util.open_floating_preview(tbl, 'markdown', {
		border = config.border,
		focusable = true,
		focus = true,
		focus_id = "pretty-hover",
		wrap_at = config.max_width,
		max_width = config.max_width,
		max_height = config.max_height,
	})
	M.bufnr = bufnr
	M.winnr = winnr

	vim.wo[M.winnr].foldenable = false
	vim.bo[M.bufnr].modifiable = false
	vim.bo[M.bufnr].bufhidden = 'wipe'

	vim.keymap.set('n', 'q', M.close_float, {
		buffer = bufnr,
		silent = true,
		nowait = true,
	})
end

return M

