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
		if substring:sub(1, 2) == ". " then
			substring = substring:sub(5)
		end
		table.insert(chunks, substring)
	end
	return chunks
end

--- Join the elements of a table into a string with a delimiter.
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

--- Transforms the line from doxygen type into markdown
---@param line string Line to be transformed.
---@param config table Table of options to be used for the conversion to the markdown language.
---@param hl_data table Table of control variables to be used for the pop-up window highlighting.
---@param control table Table of control variables to be used for the conversion to the markdown language.
-- @return table Table of strings from doxygen to markdown.
function M.transform_line(line, config, control, hl_data)
	local result = {}
	local tbl = M.split(line)
	local el = tbl[1]
	local insertEmptyLine = false

	for name, group in pairs(config.hl) do
		if M.tbl_contains(group.detect, el) then
			tbl[1] = string.upper(M.find(group.detect, el))
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

	if M.tbl_contains(config.header.detect, el) then
		tbl[1] = config.header.styler
		insertEmptyLine = true;

	elseif M.tbl_contains(config.line.detect, el) then
		table.remove(tbl, 1)
		tbl[1] = config.line.styler .. tbl[1]
		tbl[#tbl] = tbl[#tbl] .. config.line.styler
		M.brief_detected = true

	elseif M.tbl_contains(config.listing.detect, el) then
		tbl[1] = config.listing.styler

	elseif M.tbl_contains(config.word.detect, el) then
		tbl[2] = config.word.styler .. tbl[2] .. config.word.styler
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

	elseif M.tbl_contains(config.return_statement, el) then
		table.insert(result, "")
		tbl[1] = "**Return**"
		line = M.joint_table(tbl, " ")

	elseif M.tbl_contains(config.code.start, el) then
		local language = el:gmatch("{(%w+)}")() or vim.o.filetype
		table.insert(result, "```" .. language)
		table.remove(tbl, 1)

	elseif M.tbl_contains(config.code.ending, el) then
		table.insert(result, "```")
		table.remove(tbl, 1)
	end

	local ref = require("pretty_hover.references")
	tbl = ref.check_line_for_references(tbl, config)
	line = M.joint_table(tbl, " ")
	table.insert(result, line)
	if insertEmptyLine then
		table.insert(result, "")
	end
	return result
end

--- Converts a string returned by response.result.contents.value from vim.lsp[textDocument/hover] to markdown.
---@param toConvert string Documentation of the string to be converted.
---@param config table Table of options to be used for the conversion to the markdown language.
---@param hl_data table Table of control variables to be used for the pop-up window highlighting.
---@return table Converted table of strings from doxygen to markdown.
function M.convert_to_markdown(toConvert, config, hl_data)
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

	-- Remove footer padding. The last line is always empty.
	if chunks[#chunks] == "" then
		table.remove(chunks, #chunks)
	end

	for name, _ in pairs(config.hl) do
		hl_data.lines[tostring(name)] = {}
	end

	for _, chunk in pairs(chunks) do
		local toAdd = M.transform_line(chunk, config, control, hl_data)
		vim.list_extend(result, toAdd)

		for name, group in pairs(hl_data.lines) do
			if group.detected then
				group.detected = false
				table.insert(hl_data.lines[tostring(name)], {
					line_nr = M.printable_table_size(result) - 2,
					to = (config.hl[tostring(name)].line and -1 or string.len(hl_data.replacement))
				})
			end
		end
	end

	-- If the message is only one-liner, remove the code block.
	-- See issue #24
	if #result == 3 and result[#result] == "```" then
		result = { result[2] }
	end

	return result
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

