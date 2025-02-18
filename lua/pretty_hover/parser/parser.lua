local util = require("pretty_hover.core.util")

local M = {
	brief = {
		detected = false,
		option = "",
	},
}

--- Transforms the line from doxygen type into markdown
---@param line string Line to be transformed.
---@param config table Table of options to be used for the conversion to the markdown language.
---@param hl_data table Table of control variables to be used for the pop-up window highlighting.
---@param control table Table of control variables to be used for the conversion to the markdown language.
---@return table Table of strings from doxygen to markdown.
function M.transform_line(line, config, control, hl_data)
	local result = {}

	-- Some servers add whitespaces infornt of some rows.
	if line:find("^%s+[\\@]") then
		line = line:gsub("^%s+", "")
	end

	local tbl = util.split(line)
	local el = tbl[1]
	local insertEmptyLine = false

	for name, group in pairs(config.hl) do
		if util.tbl_contains(group.detect, el) then
			tbl[1] = string.upper(util.find(group.detect, el))
			if tbl[1]:sub(1, 2) == '@' then
				tbl[1] = tbl[1]:sub(3)
			else
				tbl[1] = tbl[1]:sub(2)
			end
			hl_data.lines[tostring(name)].detected = true
			hl_data.replacement = tbl[1]
		end
	end

	-- Either end the brief line or extend it to the next line.
	if M.brief.detected and el and not el:sub(1,2):gmatch("[\\@]")() then
		if M.brief.option == "continue" then
			table.insert(result, "")
			M.brief.detected = false
			M.brief.option = ""

		elseif M.brief.option == "start" then
			tbl[1] = config.line.styler .. tbl[1]
			tbl[#tbl] = tbl[#tbl] .. config.line.styler
			M.brief.detected = false
			M.brief.option = ""
		end
	end

	if util.tbl_contains(config.header.detect, el) then
		tbl[1] = config.header.styler
		insertEmptyLine = true;

	elseif util.tbl_contains(config.line.detect, el) then
		table.remove(tbl, 1)
		M.brief.detected = true

		if #tbl == 0 then
			M.brief.option = "start"

		else
			tbl[1] = config.line.styler .. (tbl[1] or "")
			tbl[#tbl] = tbl[#tbl] .. config.line.styler
			M.brief.option = "continue"
		end

	elseif util.tbl_contains(config.listing.detect, el) then
		tbl[1] = config.listing.styler

	elseif util.tbl_contains(config.return_statement, el) then
		table.insert(result, "")
		tbl[1] = "**Return**"
		line = util.join_table(tbl, " ")

	elseif util.tbl_contains(config.code.start, el) then
		local language = el:gmatch("{(%w+)}")() or vim.o.filetype
		table.insert(result, "```" .. language)
		table.remove(tbl, 1)

	elseif util.tbl_contains(config.code.ending, el) then
		table.insert(result, "```")
		table.remove(tbl, 1)
	end

	for name, group in pairs(config.group.detect) do
		if group and util.tbl_contains(group, el) then
			tbl[2] = config.group.styler .. tbl[2] .. config.group.styler
			table.remove(tbl, 1)

			if control[name] then
				control[tostring(name)] = false
				table.insert(result, "---")
				table.insert(result, "**" .. name .. "**")
			end
		end
	end

	local ref = require("pretty_hover.parser.references")
	tbl = ref.check_line_for_references(tbl, config)
	line = util.join_table(tbl, " ")
	table.insert(result, line)
	if insertEmptyLine then
		table.insert(result, "")
	end
	return result
end

--- Converts a string returned by response.result.contents.value from vim.lsp[textDocument/hover] to markdown.
---@param toConvert string|table Documentation of the string to be converted.
---@param config table Table of options to be used for the conversion to the markdown language.
---@param hl_data table Table of control variables to be used for the pop-up window highlighting.
---@return table Converted table of strings from doxygen to markdown.
---@overload fun(toConvert: string, config: table, hl_data: table): table
---@overload fun(toConvert: table, config: table, hl_data: table): table
function M.convert_to_markdown(toConvert, config, hl_data)

	config.one_liner = false
	local result = {}

	local control = {}
	for name, group in pairs(config.group.detect) do
		control[tostring(name)] = true
	end

	local lines = {}
	if type(toConvert) == "string" then
		lines = util.split(toConvert, "([^\n]*)\n?")
	elseif type(toConvert) == "table" then
		lines = toConvert
	end

	if #lines == 0 then
		return result
	end

	-- Remove footer padding. The last line is always empty.
	if lines[#lines] == "" then
		table.remove(lines, #lines)
	end

	for name, _ in pairs(config.hl) do
		hl_data.lines[tostring(name)] = {}
	end

	for _, line in pairs(lines) do
		local toAdd = M.transform_line(line, config, control, hl_data)
		vim.list_extend(result, toAdd)

		for name, group in pairs(hl_data.lines) do
			if group.detected then
				group.detected = false
				table.insert(hl_data.lines[tostring(name)], {
					line_nr = util.printable_table_size(result) - 2,
					to = (config.hl[tostring(name)].line and -1 or string.len(hl_data.replacement))
				})
			end
		end
	end

	-- If the message is only one-liner, remove the code block.
	-- See issue #24
	if #result == 3 and result[#result] == "```" then
		result = { result[2] }
		config.one_liner = true
	end

	return result
end

return M

