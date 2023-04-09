local M = {}

--- Splits a string into a table of strings.
---@param toSplit string String to be split.
---@param separator string|nil The separator. If not defined, the separator is set to "%S+".
---@return table Table of strings split by the separator.
M.split = function(toSplit, separator)
	if separator == nil then
		separator = "%S+"
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

--- Converts a string returned by response.result.contents.value from vim.lsp[textDocument/hover] to markdown.
---@param toConvert string Documentation of the string to be converted.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@return table Converted table of strings from doxygen to markdown.
M.convert_to_markdown = function(toConvert, opts)
	local chunks = M.split(toConvert, "([^\n]*)\n?")
	local result = {}
	local firstParam = true
	local firstSee = true

	for _, chunk in pairs(chunks) do
		local el = M.split(chunk)[1]

		if M.tbl_contains(opts.line, el) then
			local tbl = M.split(chunk)
			table.remove(tbl, 1)
			chunk = M.joint_table(tbl, " ")
			table.insert(result, opts.stylers.line .. chunk .. opts.stylers.line)
			table.insert(result, "")

		elseif M.tbl_contains(opts.header, el) then
			local tbl = M.split(chunk)
			table.remove(tbl, 1)
			chunk = M.joint_table(tbl, " ")
			table.insert(result, opts.stylers.header .. " " .. chunk)
			table.insert(result, "")

		elseif M.tbl_contains(opts.word, el) then
			local tbl = M.split(chunk)
			local operation = tbl[1]
			tbl[2] = opts.stylers.word .. tbl[2] .. opts.stylers.word
			table.remove(tbl, 1)
			chunk = M.joint_table(tbl, " ")

			if firstParam and operation == "@param" then
				firstParam = false
				table.insert(result, "---")
			elseif firstSee and operation == "@see" then
				firstSee = false
				table.insert(result, "---")
				table.insert(result, "**See**")
			end

			table.insert(result, chunk)

		else
			table.insert(result, chunk)
		end
	end
	return result
end

return M

