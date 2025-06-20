local M = {}

local parser = require("pretty_hover.parser.parser")

---@class ParserOutput
---@field public text table
---@field public highlighting table
---@field public new fun(self, text: table, highlighting: table): ParserOutput
---@field public string fun(self): string
ParserOutput = {
	text = {},
	highlighting = {},
	string = function(self)
		return table.concat(self.text, "\n")
	end,
}

--- Creates new ParserOutput object.
---
---@param text table of parsed input. This goes directly to functions like vim.lsp.util.open_floating_preview
---@param highlighting table of highlighting data
---
---The highlighting data can be applied fx. like this
---
---```lua
--- if M.hl_ns then
--- 	api.nvim_buf_clear_namespace(bufnr, M.hl_ns, 0, -1)
--- end
---
--- M.hl_ns = api.nvim_create_namespace("pretty_hover_ns")
---
--- for name, _ in pairs(config.hl) do
--- 	if hl_data.lines[tostring(name)] then
--- 		for _, line in pairs(hl_data.lines[tostring(name)]) do
--- 			if type(line) == "table" then
--- 				api.nvim_buf_add_highlight(bufnr, M.hl_ns, "PH"..tostring(name), line.line_nr, 0, line.to);
--- 			end
--- 		end
--- 	end
--- end
---```
---
---@return ParserOutput out New object of the referenced type
function ParserOutput:new(text, highlighting)
	local out = {}
	setmetatable(out, { __index = self })
	out.text = text
	out.highlighting = highlighting
	return out
end

--- @brief This method parses the input string or table and converts the contents from doxygen into markdown format.
---
--- NOTE: The string must have new lines inside. If the string is not separated by them the parsing will not be done.
---
--- The output highlighting data can be applied fx. like this
---
--- ```lua
--- function M.apply_highlight(config, hl_data, bufnr)
--- 	if M.hl_ns then
--- 		api.nvim_buf_clear_namespace(bufnr, M.hl_ns, 0, -1)
--- 	end
---
--- 	M.hl_ns = api.nvim_create_namespace("pretty_hover_ns")
---
--- 	for name, _ in pairs(config.hl) do
--- 		if hl_data.lines[tostring(name)] then
--- 			for _, line in pairs(hl_data.lines[tostring(name)]) do
--- 				if type(line) == "table" then
--- 					api.nvim_buf_add_highlight(bufnr, M.hl_ns, "PH"..tostring(name), line.line_nr, 0, line.to);
--- 				end
--- 			end
--- 		end
--- 	end
--- end
--- ```
--- @param text string|table Text as a string
--- @return ParserOutput Converted doxygen text into markdown.
---
--- @see pretty_hover.core.util.open_float function for the implementation in this plugin
---
--- @overload fun(text: string): ParserOutput
--- @overload fun(text: table): ParserOutput
function M.parse(text)
	local config = require("pretty_hover.config"):instance()

	local hl_data = {
		replacement = "",
		lines = {},
	}

	local tbl = parser.convert_to_markdown(text, config, hl_data)

	return ParserOutput:new(tbl, hl_data)
end

return M

