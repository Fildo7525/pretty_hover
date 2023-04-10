# pretty_hover

## Table of contents

 - [How it looks](#how-it-looks)
 - [Installation and setup](#installation-and-setup)
 - [Configuration](#configuration)
 - [Default config](#default-configuration)
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

### Configuration

The configuration consists of four parts. `line` is a table containing all the words after which will the whole line surrounded by `stylers.line` character.
The `word` will surround only one word after the elements with `stylers.word` character. The last table consists of flags that behave as an heading.
The `stylers.header` will replace the elements in `header`. `border` is than passed to the nvim api and represents the type of the floating window.

> _**NOTE**_: To really use this plugin you have to create a keymap that will call `require('pretty_hover').hover()` function.

#### Default configuration

```lua
{
	line = {
		"@brief",
	},
	word = {
		"@param",
		"@tparam",
		"@see",
	},
	header = {
		"@class",
	},
	stylers = {
		line = "**",
		word = "`",
		header = "###",
	},
	border = "rounded",
}
```

### Inspiration

https://github.com/lewis6991/hover.nvim
