local M = {}

local util = require("pretty_hover.core.util")

--- Detect if the check line is already in bold.
---@param table_line table Table of words to be checked.
---@return boolean True if the line style is bold, false otherwise.
function M.is_bold(table_line)
	local last_word = table_line[#table_line]
	return table_line[1]:find("*") == 1 and last_word:find("*") == #last_word-1
end

--- Based on the tabled_line markdown representation, this function returns the surrounding string.
---@param tabled_line table Table of words to be checked.
---@param config table Table of options to be used for the conversion to the markdown language.
---@return table The first element of the table is boolean which indicates if the string is already converted. Second element is the surrounding string.
function M.get_surround_string(tabled_line, config)
	if tabled_line and #tabled_line > 0 and M.is_bold(tabled_line) then
		return { is_brief = true, marker = config.references.styler[2]}
	else
		return { is_brief = false, marker = config.references.styler[1]}
	end
end

--- Checks the current line on the index if it is an opening reference.
---@param tabled_line table Table of strings representing current line.
---@param index integer Index of the line to be checked.
---@return boolean True if the reference is opening, false otherwise.
function M.is_opening_reference(tabled_line, index)
	if not tabled_line or not tabled_line[index + 1] or not tabled_line[index] then
		return false;
	end

	return (tabled_line[index]:find("[(]") or tabled_line[index+1]:find("[(]")) and not tabled_line[index+1]:find("[)]")
end

--- Surrounds the reference from the front. If the reference is opened, it is not closed.
---@param tabled_line table Table of strings representing current line.
---@param index integer Index of the word to be checked.
---@param config table Table of options to be used for the conversion to the markdown language.
---@param surround table Table of the surrounding strings.
function M.surround_references(tabled_line, index, config, surround)
	-- Surround the word in brief line.
	if surround.is_brief then
		-- End the brief line formatting if possible.
		if tabled_line[index-1] then
			tabled_line[index-1] = tabled_line[index-1] .. config.line.styler
		end
		-- Start the reference formatting.
		tabled_line[index] = surround.marker .. tabled_line[index+1]

		-- End the reference formatting and start the brief line formatting if possible.
		if tabled_line[index+2] and not surround.openedReference then
			tabled_line[index] = tabled_line[index] .. surround.marker
			tabled_line[index+2] = config.line.styler .. tabled_line[index+2]

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
		if not tabled_line or not tabled_line[index + 1] or not tabled_line[index] then
			return;
		end

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
---@param config table Table of options to be used for the conversion to the markdown language.
---@param surround table Table of the surrounding strings.
function M.close_opened_references(tabled_line, index, config, surround)
	if surround.openedReference and tabled_line[index]:find("[)]") then
		if surround.is_brief then
			if tabled_line[index+1] then
				tabled_line[index] = tabled_line[index] .. surround.marker
				tabled_line[index+1] = config.line.styler .. tabled_line[index+1]
			else
				tabled_line[index] = string.sub(tabled_line[index], 1, #tabled_line[index]-2) .. surround.marker
			end

		else
			tabled_line[index] = tabled_line[index] .. surround.marker

		end
		surround.openedReference = false
	end
end

--- Detects the HTML style hyperlinks in the line and converts them to markdown.
---@param tabled_line table Line from the hover message split into words.
---@param word string Word to be checked.
---@param index integer Index of the word from the @c tabled_line to be checked.
function M.detect_hyper_links(tabled_line, word, index)
	if word == "\\<a" then
		table.remove(tabled_line, index)

		word = tabled_line[index]
		local whole_link = vim.split(word, "\"", {trimempty = true})
		local link = whole_link[2]
		local styler = require("pretty_hover").get_config().line.styler

		-- The link is not closed in the same part of the line separated by the space.
		if word:sub(1,4) == "href" and word:match("\\</a>") then
			-- Handle the case of the link being the last word in the line.
			styler = word:match("\\</a>" .. styler) ~= nil and styler or ""
			local link_text = whole_link[3]:match("([%w_:.]+)\\</a>") or link
			tabled_line[index] = "[" .. link_text  .. "](" .. link .. ")" .. styler

		-- The link is closed in the next part of the line.
		elseif word:sub(1,4) == "href" then
			local link_text = whole_link[3]:sub(2)
			table.remove(tabled_line, index)

			-- Accumulate all the words until the closing tag.
			while not tabled_line[index]:match("\\</a>") do
				link_text = link_text .. " " .. tabled_line[index]
				table.remove(tabled_line, index)
			end

			-- The last word may be a space or just the closing tag.
			local final_word = tabled_line[index]:match("(%w+)\\</a>") or ""
			link_text = link_text .. " " .. final_word

			-- Handle the case of the link being the last word in the line.
			styler = tabled_line[index]:match("\\</a>" .. styler) ~= nil and styler or ""

			tabled_line[index] = "[" .. link_text  .. "](" .. link .. ")" ..styler
		end
	end
end

--- Converts all the references to markdown text.
---@param tabled_line table Words to be checked.
---@param config table Table of options to be used for the conversion to the markdown language.
---@return table Converted line to markdown.
function M.check_line_for_references(tabled_line, config)
	local surround = M.get_surround_string(tabled_line, config)
	surround.openedReference = false

	for index, word in ipairs(tabled_line) do
		if util.tbl_contains(config.references.detect, word) then
			-- Handle the parenthesis surrounding the reference.
			if tabled_line[index]:sub(1,1) == "(" then
				tabled_line[index+1] = "(" .. tabled_line[index+1]
			end

			if M.is_opening_reference(tabled_line, index) then
				surround.openedReference = true
			end

			M.surround_references(tabled_line, index, config, surround)

			table.remove(tabled_line, index + 1)
		end

		M.close_opened_references(tabled_line, index, config, surround)
		M.detect_hyper_links(tabled_line, word, index)

		-- We cannot use `word` because it will change also the hyperlinks.
		tabled_line[index] = tabled_line[index]:gsub("\\(<%w+)", "%1")
	end

	return tabled_line
end

return M
