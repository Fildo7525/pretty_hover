local text = [[### function `main`
---
	→ `int`
Parameters:
	- `int argc`
	- `char ** argv`

@brief Neque porro quisquam est qui dolorem @c ipsum quia dolor sit amet, consectetur, adipisci velit..."

Lorem Ipsum is simply dummy text of the printing and typesetting industry.
Lorem Ipsum has been the @c industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.
It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged.
It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.

@note This is a note.

@param argc Number of arguments from the command line.
@param argv The arguments in format of the strings.
@return int The return of the program. Usually 0 for successful run.
---
```cpp
int main(int argc, char *argv[])
```
]]

local text_table = {
"	### function `main`",
"---",
"	→ `int`",
"Parameters:",
"	- `int argc`",
"	- `char ** argv`",
"",
"@brief Neque porro quisquam est qui dolorem @c ipsum quia dolor sit amet, consectetur, adipisci velit...",
"",
"Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
"Lorem Ipsum has been the @c industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
"It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged.",
"It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
"",
"@note This is a note.",
"",
"@param argc Number of arguments from the command line.",
"@param argv The arguments in format of the strings.",
"@return int The return of the program. Usually 0 for successful run.",
"---",
"```cpp",
"int main(int argc, char *argv[])",
"```",
}

local parser = require("pretty_hover.parser")

local out = parser.parse(text)
--[[ local out = parser.parse(text_table) ]]

local bufnr, winnr = vim.lsp.util.open_floating_preview(out.text, "markdown", {
	focus = true,
	focusable = true,
	wrap = true,
	wrap_at = 100,
	max_width = 100,
	border = "rounded",
	focus_id = "pretty-hover-example",
})

require('pretty_hover.highlight').apply_highlight(require("pretty_hover").get_config(), out.highlighting, bufnr)
