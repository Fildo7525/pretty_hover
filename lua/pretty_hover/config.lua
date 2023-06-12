return {
	code = {
		start = {"[\\@]code"},
		ending = {"[\\@]endcode"},
	},
	line = {
		"[\\@]brief",
	},
	listing = {
		"[\\@]li",
	},
	word = {
		"[\\@]param",
		"[\\@]tparam",
		"[\\@]see",
		"[\\@]*param*",
	},
	header = {
		"[\\@]class",
	},
	return_statement = {
		"[\\@]return",
		"[\\@]*return*",
	},
	references = {
		"[\\@]ref",
		"[\\@]c",
		"[\\@]name",
	},
	stylers = {
		line = '**',
		word = '`',
		header = '###',
		listing = " - ",
		references = {
			"**",
			"`"
		},
	},
	border = "rounded",
	max_width = nil,
	max_height = nil,
	hl = {
		error = {
			color = "#DC2626",
			detect = {"[\\@]error", "[\\@]bug", "[\\@]errors"},
		},
		warning = {
			color = "#FBBF24",
			detect = {"[\\@]warning", "[\\@]thread_safety"},
		},
		--[[ info = { ]]
		--[[ 	color = "#2563EB", ]]
		--[[ 	detect = {"[\\@]note", "[\\@]notes"}, ]]
		--[[ } ]]
	},
}

