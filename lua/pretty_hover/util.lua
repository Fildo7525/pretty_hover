local api = vim.api
local ref = require("pretty_hover.references")
local hl = require("pretty_hover.highlight")

local M = {}

M.winnr = 0
M.bufnr = 0

--- Splits a string into a table of strings. Wile preserving the indentation and inline whitespaces.
---@param toSplit string String to be split.
---@param separator string|nil The separator. If not defined, the separator is set to "%S+".
---@return table Table of strings split by the separator.
function M.split(toSplit, separator)
	if separator == nil then
		separator = "%S+"
	end

	local chunks = {}
	if toSplit == nil then
		return chunks
	end

	local startsWithWhitespace = toSplit:match("^%s+")
	for substring in toSplit:gmatch(separator) do
		local li
		if separator ~= "([^\n]*)\n?" then
			li = toSplit:gmatch("%s+")
		else
			li = nil
		end

		if startsWithWhitespace then
			if li ~= nil then
				local whitespace = li()
				if whitespace ~= nil then
					table.insert(chunks, whitespace)
				end
			end
			table.insert(chunks, substring)
		else
			table.insert(chunks, substring)
			if li ~= nil then
				local whitespace = li()
				if whitespace ~= nil then
					table.insert(chunks, whitespace)
				end
			end
		end
	end
	return chunks
end

--- Join the elemnets of a table into a string with a delimiter.
---@param tbl table Table to be joined.
---@param delim string Delimiter to be used.
---@return string Joined string.
function M.joint_table(tbl, delim)
	local result = ""
	for idx, chunk in pairs(tbl) do
		result = result .. chunk
		if idx ~= #tbl then
			result = result .. delim
		end
	end
	return result
end

--- Function that encapsulates the changes in nvim api for getting the active clients.
---
--- @return table List of active clients.
local function get_clients()
	if vim.version().minor == 11 then
		return vim.lsp.get_clients()
	else
		return vim.lsp.get_active_clients()
	end
end

--- This function checks all the active clients for current buffer and returns the active client that supports the current filetype.
---@return table|nil Active client for the current buffer or nil if there is no active client.
function M.get_current_active_clent()
	for _, client in ipairs(get_clients()) do
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
function M.transform_line(line, opts, control, hl_data)
	local result = {}
	vim.print("\nTransofrm: ", line)
	local tbl = M.split(line)
	vim.print(tbl)
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
			hl_data.lines[tostring(name)].detected = true
			hl_data.replacement = tbl[1]
		end
	end

	if M.brief_detected and el and not el:sub(1,2):gmatch("[\\@]")() then
		table.insert(result, "")
		M.brief_detected = false
	end

	if ref.tbl_contains(opts.header.detect, el) then
		tbl[1] = opts.header.styler
		insertEmptyLine = true;

	elseif ref.tbl_contains(opts.line.detect, el) then
		table.remove(tbl, 1)
		tbl[1] = opts.line.styler .. tbl[1]
		tbl[#tbl] = tbl[#tbl] .. opts.line.styler
		M.brief_detected = true

	elseif ref.tbl_contains(opts.listing.detect, el) then
		tbl[1] = opts.listing.styler

	elseif ref.tbl_contains(opts.word.detect, el) then
		tbl[2] = opts.word.styler .. tbl[2] .. opts.word.styler
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
		line = M.joint_table(tbl, "")

	elseif ref.tbl_contains(opts.code.start, el) then
		local language = el:gmatch("{(%w+)}")() or vim.o.filetype
		table.insert(result, "```" .. language)
		table.remove(tbl, 1)

	elseif ref.tbl_contains(opts.code.ending, el) then
		table.insert(result, "```")
		table.remove(tbl, 1)
	end


	tbl = ref.check_line_for_references(tbl, opts)
	line = M.joint_table(tbl, "")
	table.insert(result, line)
	if insertEmptyLine then
		table.insert(result, "")
	end

	vim.print(result)
	return result
end

--- Converts a string returned by response.result.contents.value from vim.lsp[textDocument/hover] to markdown.
---@param toConvert string Documentation of the string to be converted.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@param hl_data table Table of control variables to be used for the popup window highlighting.
---@return table Converted table of strings from doxygen to markdown.
function M.convert_to_markdown(toConvert, opts, hl_data)
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

	for name, _ in pairs(opts.hl) do
		hl_data.lines[tostring(name)] = {}
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
function M.close_float()
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
function M.open_float(hover_text, config)
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

	if config.toggle and M.winnr ~= 0 then
		M.close_float()
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

	hl.apply_highlight(config, hl_data, M.bufnr)

	vim.keymap.set('n', 'q', M.close_float, {
		buffer = M.bufnr,
		silent = true,
		nowait = true,
	})
end

return M

