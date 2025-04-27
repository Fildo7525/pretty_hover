<h1 align="center">
pretty_hover
</h1>

<p align="center">
<a href="https://github.com/Fildo7525/pretty_hover/stargazers">
	<img
		alt="Stargazers"
		src="https://img.shields.io/github/stars/Fildo7525/pretty_hover?style=for-the-badge&logo=starship&color=fae3b0&logoColor=d9e0ee&labelColor=282a36"
	/>
	</a>
	<a href="https://github.com/Fildo7525/pretty_hover/issues">
	<img
		alt="Issues"
		src="https://img.shields.io/github/issues/Fildo7525/pretty_hover?style=for-the-badge&logo=gitbook&color=ddb6f2&logoColor=d9e0ee&labelColor=282a36"
	/>
	</a>
	<a href="https://github.com/Fildo7525/pretty_hover/contributors">
	<img
		alt="Contributors"
		src="https://img.shields.io/github/contributors/Fildo7525/pretty_hover?style=for-the-badge&logo=opensourceinitiative&color=abe9b3&logoColor=d9e0ee&labelColor=282a36"
	/>
	</a>
</p>

## Table of contents

 - [How it looks](#how-it-looks)
 - [Installation and setup](#installation-and-setup)
 - [Configuration](#configuration)
 - [Integration](#integration)
	- [Blink.cmp](#blink.cmp)
 - [Default config](#default-configuration)
 - [Limitations](#limitations)
 - [Contributing](#contributing)
 - [Inspiration](#inspiration)

Pretty_hover is a lightweight plugin that parses the hover message before opening the popup window.
The output can be easily manipulated with. This will result in a more readable hover message.

An additional feature is `number conversion`. If you are tired of constantly converting some numbers to hex, octal
or binary you can use this plugin to do it for you.

### How it looks

> _**NOTE**_: The colors of the text depend on the color of your chosen colorscheme.
These pictures are taken with colorscheme `catppuccin-mocha`

Using native vim.lsp.buf.hover()
<img src="https://github.com/user-attachments/assets/5f4bd780-8a24-44c8-8a8e-4803ae9f7ace">

Using pretty_hover
<img src="https://github.com/user-attachments/assets/e547359e-0a82-4fac-ba75-388cdd291804">

## Installation and setup

### via Lazy
```lua
{
	"Fildo7525/pretty_hover",
	event = "LspAttach",
	opts = {}
},
```

### via Packer
```lua
use {
	"Fildo7525/pretty_hover",
	config = function()
		require("pretty_hover").setup({})
	end
}
```

### Using Pretty Hover
To open a hover window, run the following lua snippet (or bind it to a key)
```lua
require("pretty_hover").hover()
```

To close a hover window either move the cursor as with nvim's hover popup or
run the following lua snippet (e.g. from a keymap)
```lua
require("pretty_hover").close()
```
**NOTE: When focused on a hover window, you can also press `q` to close the hover window**

### Configuration

| Parameter		| Description	|
|----------------- | -------------- |
| line			 | If one of the supplied strings is located as the first word in the line the whole line is surrounded by `line.styler`. |
| listing		  | These words will be substituted with `listing.styler`. |
| group			 | Table containing group name and its detectors. If this word is detected at the beginning of a line the next word is surrounded by `group.styler`. The whole group is separated by an line and the first line containing es the group name. |
| header		   | List of strings. If this word is detected at the beginning of a line the word is substituted by `header.styler` |
| return statement | This words are substituted with **Return** (in bold) |
| references	   | If any word from this list is detected, the next word is surrounded by `references.styler[1]`. If this word is located in `line` section the next word is surrounded by `references.styler[2]` (see [Limitations](#limitations)) |
| hl			   | This is a table of highlighting groups. You can define new groups by specifying at least two parameters. `color` and `detect`. Flag `line` is not mandatory, however by setting this flag you can ensure that the whole line is highlighted. When a detector from the table `detect` is found the detector is made uppercase, omits the beginning tag and gets highlighted. |
| border		   | Sets the border of the hover window. (none \| single \| double \| rounded \| solid \| shadow). |
| wrap			| Flag whether to wrap the text if the window is smaller. Otherwise the floating window is scrollable horizontally |
| max_width		| Sets the maximum width of the window. If you don't want any limitation set to nil. |
| max_height	   | Sets the maximum height of the window. If you don't want any limitation set to nil. |
| toggle	   | Flag detecting whether you want to have the hover just as a toggle window or make the popup focusable. |
| multi_server	   | Flag detecting whether you want to use the new multi lsp support or not. |

> _**NOTE**_: To really use this plugin you have to create a keymap that calls `require('pretty_hover').hover()` function.

The plugin supports code blocks. By specifying `@code{cpp}` the text in the popup window is highlighted with its filetype highlighter
until the `@endcode` is hit. When the filetype is not specified in the flag `@code` the filetype from the currently opened file is used.

#### Default configuration

```lua
{
	-- Tables grouping the detected strings and using the markdown highlighters.
	header = {
		detect = { "[\\@]class" },
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
		detect = { "[\\@]ref", "[\\@]c", "[\\@]name" },
		styler = { "**", "`" },
	},
	group = {
		detect = {
			-- ["Group name"] = {"detectors"}
			["Parameters"] = { "[\\@]param", "[\\@]*param*" },
			["Types"] = { "[\\@]tparam" },
			["See"] = { "[\\@]see" },
			["Return Value"] = { "[\\@]retval" },
		},
		styler = "`",
	},

	-- Tables used for cleaner identification of hover segments.
	code = {
		start = { "[\\@]code" },
		ending = { "[\\@]endcode" },
	},
	return_statement = {
		"[\\@]return",
		"[\\@]*return*",
	},

	-- Highlight groups used in the hover method. Feel free to define your own highlight group.
	hl = {
		error = {
			color = "#DC2626",
			detect = { "[\\@]error", "[\\@]bug" },
			line = false, -- Flag detecting if the whole line should be highlighted
		},
		warning = {
			color = "#FBBF24",
			detect = { "[\\@]warning", "[\\@]thread_safety", "[\\@]throw" },
			line = false,
		},
		info = {
			color = "#2563EB",
			detect = { "[\\@]remark", "[\\@]note", "[\\@]notes" },
		},
		-- Here you can set up your highlight groups.
	},

	-- If you use nvim 0.11.0 or higher you can choose, whether you want to use the new
	-- multi lsp support or not. Otherwise this option is ignored.
	multi_server = true,
	border = "rounded",
	wrap = true,
	max_width = nil,
	max_height = nil,
	toggle = false,
}
```

### Integration

The plugin supports an easy integration:

```lua
local parsed = require("pretty_hover.parser").parse(text)
```

the parsed variable contains two fields `text` and `highlight`. The `text` field contains the converted text to markdown
and the `highlight` field contains the highlight groups for the text.

You can use the `parsed` variable to display the hover message in your own way.

```lua
vim.lsp.util.open_floating_preview(parsed.text, "markdown", {
	focus = true,
	focusable = true,
	wrap = true,
	wrap_at = 100,
	max_width = 100,
	border = "rounded",
	focus_id = "pretty-hover-example",
})
```

To see an example of the implementation see the `pretty_hover/examples/parsing.lua` file.

#### Blink.cmp

This functionality is supported for blink.cmp from version v0.13.0 and higher.
To use this plugin with `blink.cmp` documentation you can add the following code snippet to you configuration:

```lua
{
	completion = {
		documentation = {
			draw = function(opts)
				if opts.item and opts.item.documentation then
					local out = require("pretty_hover.parser").parse(opts.item.documentation.value)
					opts.item.documentation.value = out:string()
				end

				opts.default_implementation(opts)
			end,
		}
	},
}
```

### Limitations

Currently, Neovim supports these markdown stylers: \`, \*, \`\`\`[language]. Unfortunately, you cannot do any
of their combination. If the support is extended there will be more options to style the pop-up window.
Newly this plugin started supporting highlighting see the [Configuration](#configuration) for more information.

### Contributing

If you have any idea how to improve this plugin do not hesitate to create a PR. Otherwise, if you know how
to improve the plugin mention it in a new issue. Enjoy the plugin.

### Inspiration

https://github.com/lewis6991/hover.nvim
