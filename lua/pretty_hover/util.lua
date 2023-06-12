local api = vim.api
local ref = require("pretty_hover.references")
local hl = require("pretty_hover.highlight")

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

--- This function checks all the active clients for current buffer and returns the active client that supports the current filetype.
---@return table|nil Active client for the current buffer or nil if there is no active client.
M.get_current_active_clent = function()
	for _, client in ipairs(vim.lsp.get_active_clients()) do
		if ref.tbl_contains(client.config.filetypes, vim.bo.filetype) then
			return client
		end
	end
	return nil
end

--- Transforms the line from doxygen stype into markdown
---@param line string Line to be transformed.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@param hl_data table Table of control variables to be used for the popup window highlighting.
---@param control table Table of control variables to be used for the conversion to the markdown language.
-- @return table Table of strings from doxygen to markdown.
M.transform_line = function (line, opts, control, hl_data)
	local result = {}
	local tbl = M.split(line)
	local el = tbl[1]
	local insertEmptyLine = false

	for name, group in pairs(opts.hl) do
		if ref.tbl_contains(group.detect, el) then
			tbl[1] = string.upper(ref.find(group.detect, el))
			if tbl[1]:sub(1, 2) == '@' then
				tbl[1] = tbl[1]:sub(3)
			else
				tbl[1] = tbl[1]:sub(2)
			end
			hl_data.lines[tostring(name)] = {}
			hl_data.lines[tostring(name)].detected = true
			hl_data.replacement = tbl[1]
		end
	end

	if ref.tbl_contains(opts.line, el) then
		table.remove(tbl, 1)
		tbl[1] = "**" .. tbl[1]
		tbl[#tbl] = tbl[#tbl] .. "**"
		insertEmptyLine = true;

	elseif ref.tbl_contains(opts.header, el) then
		tbl[1] = opts.stylers.header
		insertEmptyLine = true;

	elseif ref.tbl_contains(opts.code.start, el) then
		local language = el:gmatch("{(%w+)}")() or vim.o.filetype
		table.insert(result, "```" .. language)
		table.remove(tbl, 1)

	elseif ref.tbl_contains(opts.code.ending, el) then
		table.insert(result, "```")
		table.remove(tbl, 1)

	elseif ref.tbl_contains(opts.word, el) then
		tbl[2] = opts.stylers.word .. tbl[2] .. opts.stylers.word
		table.remove(tbl, 1)

		if control.firstParam and el:find("[@\\]param") then
			control.firstParam = false
			table.insert(result, "---")
			table.insert(result, "**Parameters**")
		elseif control.firstTemplate and el:find("[@\\]tparam") then
			control.firstTemplate = false
			table.insert(result, "---")
			table.insert(result, "**Types**")
		elseif control.firstSee and el:find("[@\\]see") then
			control.firstSee = false
			table.insert(result, "---")
			table.insert(result, "**See**")
		end

	elseif ref.tbl_contains(opts.return_statement, el) then
		table.insert(result, "")
		tbl[1] = "**Return**"
		line = M.joint_table(tbl, " ")

	elseif ref.tbl_contains(opts.listing, el) then
		tbl[1] = opts.stylers.listing
	end

	tbl = ref.check_line_for_references(tbl, opts)
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
---@param hl_data table Table of control variables to be used for the popup window highlighting.
---@return table Converted table of strings from doxygen to markdown.
M.convert_to_markdown = function(toConvert, opts, hl_data)
	local result = {}
	local control = {
		firstParam = true,
		firstSee = true,
		firstTemplate = true,
	}

	local chunks = M.split(toConvert, "([^\n]*)\n?")
	if #chunks == 0 then
		return result
	end

	for idx, chunk in pairs(chunks) do
		local toAdd = M.transform_line(chunk, opts, control, hl_data)
		vim.list_extend(result, toAdd)

		for name, group in pairs(hl_data.lines) do
			if group.detected then
				group.detected = false
				table.insert(hl_data.lines[tostring(name)], {
					line_nr = ref.printable_table_size(result) - 2,
					to = (opts.hl[tostring(name)].line and -1 or string.len(hl_data.replacement))
				})
			end
		end
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

	local hl_data = {
		replacement = "",
		lines = {},
	}

	-- Convert Doxygen comments to Markdown format
	local tbl = M.convert_to_markdown(hover_text, config, hl_data)
	if #tbl == 0 then
		vim.notify("No information available", vim.log.levels.INFO)
		return
	end

	M.bufnr, M.winnr = vim.lsp.util.open_floating_preview(tbl, 'markdown', {
		border = config.border,
		focusable = true,
		focus = true,
		focus_id = "pretty-hover",
		wrap_at = config.max_width,
		max_width = config.max_width,
		max_height = config.max_height,
	})

	vim.wo[M.winnr].foldenable = false
	vim.bo[M.bufnr].modifiable = false
	vim.bo[M.bufnr].bufhidden = 'wipe'

	vim.print("HL: ", hl_data)
	hl.apply_highlight(config, hl_data, M.bufnr)

	vim.keymap.set('n', 'q', M.close_float, {
		buffer = M.bufnr,
		silent = true,
		nowait = true,
	})
end

return M

