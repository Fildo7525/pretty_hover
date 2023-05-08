local M = {}

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

--- Detect if the check line is already bolded.
---@param table_line table Table of words to be checked.
---@return boolean True if the line is bolded, false otherwise.
M.is_bold = function(table_line)
	local last_word = table_line[#table_line]
	return table_line[1]:find("*") == 1 and last_word:find("*") == #last_word-1
end

--- Based on the tabled_line markdown representation, this function returns the surrounding string.
---@param tabled_line table Table of words to be checked.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@return table The first element of the table is boolean which indicates if the string is already converted. Second element is the surrounding string.
M.get_surround_string = function(tabled_line, opts)
	if tabled_line and #tabled_line > 0 and M.is_bold(tabled_line) then
		return { is_brief = true, marker = opts.stylers.references[2]}
	else
		return { is_brief = false, marker = opts.stylers.references[1]}
	end
end

--- Checks the current line on the index if it is an opening reference.
---@param tabled_line table Table of strings representing current line.
---@param index integer Index of the line to be checked.
---@return boolean True if the reference is opening, false otherwise.
M.is_opening_reference = function(tabled_line, index)
	return (tabled_line[index]:find("[(]") or tabled_line[index+1]:find("[(]")) and not tabled_line[index+1]:find("[)]")
end

--- Surrounds the reference from the front. If the reference is opened, it is not closed.
---@param tabled_line table Table of strings representing current line.
---@param index integer Index of the word to be checked.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@param surround table Table of the surrounding strings.
M.surround_references = function(tabled_line, index, opts, surround)
	-- Surround the word in brief line.
	if surround.is_brief then
		-- End the brief line formatting if possible.
		if tabled_line[index-1] then
			tabled_line[index-1] = tabled_line[index-1] .. opts.stylers.line
		end
		-- Start the reference formatting.
		tabled_line[index] = surround.marker .. tabled_line[index+1]

		-- End the reference formatting and start the brief line formatting if possible.
		if tabled_line[index+2] and not surround.openedReference then
			tabled_line[index] = tabled_line[index] .. surround.marker
			tabled_line[index+2] = opts.stylers.line .. tabled_line[index+2]

		elseif tabled_line[index+2] then
			-- The reference is opened so we don't add ending reference.

		else
			tabled_line[index] = string.sub(tabled_line[index], 1, #tabled_line[index]-2) .. surround.marker
			if tabled_line[index]:find('[)]') then
				surround.openedReference = false
			end
		end

	-- Surround the word in non-brief line.
	else
		tabled_line[index] = surround.marker .. tabled_line[index+1]

		-- End the reference formatting and start the brief line formatting if possible.
		if not surround.openedReference then
			tabled_line[index] = tabled_line[index] .. surround.marker
		end
	end
end

--- Close the opened reference if it is opened.
---@param tabled_line table Table of strings representing current line.
---@param index integer Index of the word to be checked.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@param surround table Table of the surrounding strings.
M.close_opened_references = function(tabled_line, index, opts, surround)
	if surround.openedReference and tabled_line[index]:find("[)]") then
		if surround.is_brief then
			if tabled_line[index+1] then
				tabled_line[index] = tabled_line[index] .. surround.marker
				tabled_line[index+1] = opts.stylers.line .. tabled_line[index+1]
			else
				tabled_line[index] = string.sub(tabled_line[index], 1, #tabled_line[index]-2) .. surround.marker
			end

		else
			tabled_line[index] = tabled_line[index] .. surround.marker

		end
		surround.openedReference = false
	end
end

--- Converts all the references to markdown text.
---@param tabled_line table Words to be checked.
---@param opts table Table of options to be used for the conversion to the markdown language.
---@return table Converted line to markdown.
M.check_line_for_references = function (tabled_line, opts)
	local surround = M.get_surround_string(tabled_line, opts)
	surround.openedReference = false

	for index, word in ipairs(tabled_line) do
		if M.tbl_contains(opts.references, word) then
			-- Handle the parantheses surrounding the reference.
			if tabled_line[index]:sub(1,1) == "(" then
				tabled_line[index+1] = "(" .. tabled_line[index+1]
			end

			if M.is_opening_reference(tabled_line, index) then
				surround.openedReference = true
			end

			M.surround_references(tabled_line, index, opts, surround)

			table.remove(tabled_line, index + 1)
		end

		M.close_opened_references(tabled_line, index, opts, surround)

	end

	return tabled_line
end

return M
