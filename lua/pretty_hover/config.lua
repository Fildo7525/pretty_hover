---@class PrettyHoverConfig
local M = {
	_config = {},

	header = {
		detect = {"[\\@]class"},
		styler = '###',
	},
	line = {
		detect = { "[\\@]brief" },
		styler = '**',
	},
	listing = {
		detect = { "[\\@]li" },
		styler = " - ",
	},
	references = {
		detect = {
			"[\\@]ref",
			"[\\@]c",
			"[\\@]name",
			"[\\@]a",
		},
		styler = { "**", "`" },
	},
	group = {
		detect = {
			["Parameters"] = { "[\\@]param", "[\\@]*param*" },
			["Types"] = { "[\\@]tparam" },
			["See"] = { "[\\@]see" },
			["Return Value"] = { "[\\@]retval" },
		},
		styler = "`",
	},

	code = {
		start = {"[\\@]code"},
		ending = {"[\\@]endcode"},
	},
	return_statement = {
		"[\\@]return",
		"[\\@]*return*",
	},

	hl = {
		error = {
			color = "#DC2626",
			detect = {"[\\@]error", "[\\@]bug"},
			line = false,
		},
		warning = {
			color = "#FBBF24",
			detect = {"[\\@]warning", "[\\@]thread_safety", "[\\@]throw"},
			line = false,
		},
		info = {
			color = "#4FC1FF",
			detect = {"[\\@]remark", "[\\@]note", "[\\@]notes"},
		}
	},

	multi_server = true,
	border = "rounded",
	wrap = true,
	max_width = nil,
	max_height = nil,
	toggle = false,
}

---@class PrettyHoverConfig
---@brief This class is used to configure the pretty_hover plugin.
---@param config table Table of options to be used for the pretty_hover configuration. If none or empty is provided, the
---previous configuration will be used. If the previous configuration is also empty, the default configuration will be used.
---@return table config The configuration table that will be used for the pretty_hover plugin.
function M:instance(config)
	config = config or {}

	if vim.tbl_isempty(config) and not vim.tbl_isempty(self._config) then
		return self._config
	end

	self._config = vim.tbl_deep_extend('force', {}, self, config)
	require("pretty_hover.highlight").setup_colors(self._config)
	return self._config
end

-- return M
return M
