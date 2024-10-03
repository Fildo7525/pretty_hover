local M = {}

local compatibility = require "pretty_hover.core.compatibility"

local api = vim.api

--- Convert HEX color reprezentation to RGB
---@param hex string HEX color reprezentation
---@return number|nil, number|nil, number|nil # RGB color reprezentation
function M.hex2rgb(hex)
	hex = hex:gsub("#", "")
	return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

--- Check if HEX color is dark
---@param hex string HEX color reprezentation
---@return boolean True if color is dark, false otherwise
function M.is_dark(hex)
	local r, g, b = M.hex2rgb(hex)
	local lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255
	return lum <= 0.5
end

--- Get the highlight group
---@param name string Highlight group name
---@return table|nil Highlight group
function M.get_hl(name)
	local hl = compatibility.nvim_hl(name, true)

	for _, key in pairs({ "foreground", "background", "special" }) do
		if hl[key] then
			hl[key] = string.format("#%06x", hl[key])
		end
	end

	return hl
end

--- Setup color groups for pretty_hover plugin.
---@param opts table Options from the config.
function M.setup_colors(opts)
	M.hl_ns = api.nvim_create_namespace("pretty_hover_ns")
	local normal = M.get_hl("Normal")

	if not normal then
		vim.notify("No normal highlight group found", vim.log.levels.WARN)
		return
	end

	local fg_dark = M.is_dark(normal.foreground or "#ffffff") and normal.foreground or normal.background
	local fg_light = M.is_dark(normal.foreground or "#ffffff") and normal.background or normal.foreground
	fg_dark = fg_dark or "#000000"
	fg_light = fg_light or "#ffffff"

	for kw, hl_groups in pairs(opts.hl) do
		local kw_color = hl_groups.color or "default"
		local hex

		if kw_color:sub(1, 1) == "#" then
			hex = kw_color
		else
			local colors = M.options.colors[kw_color]
			colors = type(colors) == "string" and { colors } or colors

			for _, color in pairs(colors) do
				if color:sub(1, 1) == "#" then
					hex = color
					break
				end
				local c = M.get_hl(color)
				if c and c.foreground then
					hex = c.foreground
					break
				end
			end
		end
		if not hex then
			error("Todo: no color for " .. kw)
		end

		vim.cmd("hi def PH" .. kw .. " guibg=NONE  guifg=" .. hex .. " gui=NONE")
	end
end

--- Applies the highlight to the lines of the opened floating window.
--- The used groups are ErrorMsg and WarningMsg. For the propper highlighting, the
--- highlight groups must be defined.
---@param config table Table of configurations.
---@param hl_data table Table of control variables that were set during the conversion to markdown.
---@param bufnr number Buffer number of the popup window.
function M.apply_highlight(config, hl_data, bufnr)
	if M.hl_ns then
		api.nvim_buf_clear_namespace(bufnr, M.hl_ns, 0, -1)
	end

	M.hl_ns = api.nvim_create_namespace("pretty_hover_ns")

	for name, _ in pairs(config.hl) do
		if hl_data.lines[tostring(name)] then
			for _, line in pairs(hl_data.lines[tostring(name)]) do
				if type(line) == "table" then
					api.nvim_buf_add_highlight(bufnr, M.hl_ns, "PH"..tostring(name), line.line_nr, 0, line.to);
				end
			end
		end
	end
end


return M
