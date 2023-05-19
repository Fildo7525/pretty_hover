# pretty_hover

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
		require("pretty_hover").setup(options)
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

| Parameter        | Description    |
|----------------- | -------------- |
| line             | If one of the supplied strings is located as the first word in line the whole line is surrounded by `stylers.line`. |
| listing          | These words will be substituted with `stylers.listing`. |
| word             | List of strings. If this word is detected at the beginning of a line the next word is surrounded by `styles.word` |
| header           | List of strings. If this word is detected at the beginning of a line the word is substituted by `styles.header` |
| return statement | This words are substituted with **Return** (in bold) |
| references       | If any word from this list is detected, the next word is surrounded by `styles.references[1]`. If this word is located in `line` section the next word is surrounded by `stylers.references[2]` (see [Limitations](#limitations)) |
| border           | Sets the border of the hover window. (none|single|double|rounded|solid|shadow). |
| max_width        | Sets the maximum width of the window. If you don't want any limitation set to nil. |
| max_height       | Sets the maximum hight of the window. If you don't want any limitation set to nil. |

> _**NOTE**_: To really use this plugin you have to create a keymap that will call `require('pretty_hover').hover()` function.

#### Default configuration

```lua
{
	line = {
		"@brief",
	},
	listing = {
		"@li",
	},
	word = {
		"@param",
		"@tparam",
		"@see",
		"@*param*", -- for lua
	},
	header = {
		"@class",
	},
	return_statement = {
		"@return",
		"\\return",
		"@*return*", -- for lua
	},
	references = {
		"@ref",
		"@c",
		"@name",
	},
	stylers = {
		line = '**',
		word = '`',
		header = '###',
		listing = " - ",
		references = {
			"**", -- Used primarly in main body.
			"`" -- Used in brief section.
		},
	},
	border = "rounded",
	max_width = nil, -- Leave nil for no restriction.
	max_height = nil, -- Leave nil for no restriction.
}
```

### Limitations

Currently neovim supports these markdown stylers: \`, \*, \`\`\`[language]. Unfortunately you cannot do any
of their combination. If the support is extended there will be more options to style the pop-up window.

### Contributing

If you have any idea how to make this plugin better do not hesitate to crate a PR. If you know how
to make the improvement try mentioning it. Enjoy the plugin.

### Inspiration

https://github.com/lewis6991/hover.nvim
