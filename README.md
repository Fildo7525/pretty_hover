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
 - [Default config](#default-configuration)
 - [Limitations](#limitations)
 - [Contributing](#contributing)
 - [Inspiration](#inspiration)

Pretty_hover is a light weight plugin that parses the hover message before opening the popup window.
The output can be easily manipulated with. This will result in more readable hover message.

### How it looks

Using native vim.lsp.buf.hover()
<img src="https://user-images.githubusercontent.com/59179935/230844931-49fdd776-2bf1-4017-8f08-fe4ac900c7c8.png">

Using pretty_hover
<img src="https://user-images.githubusercontent.com/59179935/230844929-fde11267-9b4f-4560-92e0-55cef8f2d457.png">

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

To close a hover window, run the following lua snippet (or bind it to a key)
```lua
require("pretty_hover").close()
```
**NOTE: When focused on a hover window, you can also press `q` to close the hover window**

### Configuration

| Parameter		| Description	|
|----------------- | -------------- |
| line			 | If one of the supplied strings is located as the first word in line the whole line is surrounded by `stylers.line`. |
| listing		  | These words will be substituted with `stylers.listing`. |
| word			 | List of strings. If this word is detected at the beginning of a line the next word is surrounded by `styles.word` |
| header		   | List of strings. If this word is detected at the beginning of a line the word is substituted by `styles.header` |
| return statement | This words are substituted with **Return** (in bold) |
| references	   | If any word from this list is detected, the next word is surrounded by `styles.references[1]`. If this word is located in `line` section the next word is surrounded by `stylers.references[2]` (see [Limitations](#limitations)) |
| hl			   | This is a table of highlighting groups. User can define new groups by specifying at least tow parameters. `color` and `detect`. Flag `line` is not mendatory, however by setting this flag you can ensure that the whole line is highlighted. When a detector from the table `detect` is found the detector is made uppercase, omits the beginning tag and gets highlighted. |
| border		   | Sets the border of the hover window. (none|single|double|rounded|solid|shadow). |
| max_width		| Sets the maximum width of the window. If you don't want any limitation set to nil. |
| max_height	   | Sets the maximum hight of the window. If you don't want any limitation set to nil. |
| toggle	   | Flag detecting whether you want to have the hover just as a toggle window or make the popup focusable. |

> _**NOTE**_: To really use this plugin you have to create a keymap that will call `require('pretty_hover').hover()` function.

The plugin supports code blocks. By specifying `@code{cpp}` the text in popup window is highlighted with its filetype highlighter
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
	word = {
		detect = { "[\\@]param", "[\\@]tparam", "[\\@]see", "[\\@]*param*" },
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
		-- Here you can setup your own highlight groups.
	},

	border = "rounded",
	max_width = nil,
	max_height = nil,
	toggle = false,
}
```

### Limitations

Currently neovim supports these markdown stylers: \`, \*, \`\`\`[language]. Unfortunately you cannot do any
of their combination. If the support is extended there will be more options to style the pop-up window.
Newly this plugin started supporting highlighting see the [Configuration](#configuration) for more information.

### Contributing

If you have any idea how to make this plugin better do not hesitate to crate a PR. If you know how
to make the improvement try mentioning it. Enjoy the plugin.

### Inspiration

https://github.com/lewis6991/hover.nvim
