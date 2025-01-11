local api = vim.api
local hl = require("pretty_hover.highlight")
local compatibility = require("pretty_hover.core.compatibility")
local ms = require('vim.lsp.protocol').Methods

local M = {}

local function on_clients_finished(client_opts, method, callback, pre_ececute_callback, post_execute_callback)
	local clients = vim.lsp.get_clients(client_opts)
	local util = require('vim.lsp.util')
	local remaining = #clients
	local all_items = {}

	local function on_response(_, result, client)
		local locations = {}
		if result then
			locations = vim.islist(result) and result or { result }
		end
		local items = util.locations_to_items(locations, client.offset_encoding)
		vim.list_extend(all_items, items)
		remaining = remaining - 1
		if remaining == 0 then
			callback(all_items)
		end
	end

	pre_ececute_callback()

	for _, client in ipairs(clients) do
		local params = util.make_position_params(api.nvim_get_current_win(), client.offset_encoding)
		vim.print("Params: " .. vim.inspect(params))
		client:request(method, params, function(_, result)
			on_response(_, result, client)
		end)
	end

	post_execute_callback()
end

local function popup_definition_handler(all_items, method, opts, tagname, from, win)
	if vim.tbl_isempty(all_items) then
		vim.notify('No locations found', vim.log.levels.INFO)
		return
	end

	vim.print("All items: " .. vim.inspect(all_items))

	local title = 'LSP locations'
	if opts.on_list then
		assert(vim.is_callable(opts.on_list), 'on_list is not a function')
		opts.on_list({
			title = title,
			items = all_items,
			context = { bufnr = M.original_buffer, method = method },
		})
		return
	end

	if #all_items == 1 then
		local item = all_items[1]
		local b = item.bufnr or vim.fn.bufadd(item.filename)

		-- Save position in jumplist
		vim.cmd("normal! m'")
		-- Push a new item into tagstack
		local tagstack = { { tagname = tagname, from = from } }
		vim.fn.settagstack(vim.fn.win_getid(win), { items = tagstack }, 't')

		vim.bo[b].buflisted = true
		local w = opts.reuse_win and vim.fn.win_findbuf(b)[1] or win
		api.nvim_win_set_buf(w, b)
		api.nvim_win_set_cursor(w, { item.lnum, item.col - 1 })
		vim._with({ win = w }, function()
			-- Open folds under the cursor
			vim.cmd('normal! zv')
		end)
		return
	end

	if opts.loclist then
		vim.fn.setloclist(0, {}, ' ', { title = title, items = all_items })
		vim.cmd.lopen()
	else
		vim.fn.setqflist({}, ' ', { title = title, items = all_items })
		vim.cmd('botright copen')
	end
end

--- @class vim.lsp.ListOpts
---
--- list-handler replacing the default handler.
--- Called for any non-empty result.
--- This table can be used with |setqflist()| or |setloclist()|. E.g.:
--- ```lua
--- local function on_list(options)
---   vim.fn.setqflist({}, ' ', options)
---   vim.cmd.cfirst()
--- end
---
--- vim.lsp.buf.definition({ on_list = on_list })
--- vim.lsp.buf.references(nil, { on_list = on_list })
--- ```
---
--- If you prefer loclist instead of qflist:
--- ```lua
--- vim.lsp.buf.definition({ loclist = true })
--- vim.lsp.buf.references(nil, { loclist = true })
--- ```
--- @field on_list? fun(t: vim.lsp.LocationOpts.OnList)
--- @field loclist? boolean

--- @class vim.lsp.LocationOpts.OnList
--- @field items table[] Structured like |setqflist-what|
--- @field title? string Title for the list.
--- @field context? table `ctx` from |lsp-handler|

--- @class vim.lsp.LocationOpts: vim.lsp.ListOpts
---
--- Jump to existing window if buffer is already open.
--- @field reuse_win? boolean

--- Jumps to the declaration of the symbol under the cursor.
--- @note Many servers do not implement this method. Generally, see |vim.lsp.buf.definition()| instead.
--- @param opts? vim.lsp.LocationOpts
--- @param cword? string
function M.definition(opts, cword)
	opts = opts or {}
	local method = ms.textDocument_definition
	local util = require('vim.lsp.util')
	--- @type vim.lsp.Client[]
	local clients = vim.lsp.get_clients({ method = method, bufnr = M.original_buffer })
	if not next(clients) then
		vim.notify(vim.lsp._unsupported_method(method), vim.log.levels.WARN)
		return
	end

	local win = M.original_win --api.nvim_get_current_win()
	local from = vim.fn.getpos('.')
	from[1] = M.bufnr
	local tagname = vim.fn.expand('<cword>')
	local remaining = #clients

	local all_items = {}

	local function on_response(_, result, client)
		vim.print(result)
		local locations = {}
		if result then
			locations = vim.islist(result) and result or { result }
		end
		local items = util.locations_to_items(locations, client.offset_encoding)
		vim.list_extend(all_items, items)
		remaining = remaining - 1
		if remaining == 0 then
			if vim.tbl_isempty(all_items) then
				vim.notify('No locations found', vim.log.levels.INFO)
				return
			end

			vim.print("All items: " .. vim.inspect(all_items))

			local title = 'LSP locations'
			if opts.on_list then
				assert(vim.is_callable(opts.on_list), 'on_list is not a function')
				opts.on_list({
					title = title,
					items = all_items,
					context = { bufnr = M.original_buffer, method = method },
				})
				return
			end

			if #all_items == 1 then
				local item = all_items[1]
				local b = item.bufnr or vim.fn.bufadd(item.filename)

				-- Save position in jumplist
				vim.cmd("normal! m'")
				-- Push a new item into tagstack
				local tagstack = { { tagname = tagname, from = from } }
				vim.fn.settagstack(vim.fn.win_getid(win), { items = tagstack }, 't')

				vim.bo[b].buflisted = true
				local w = opts.reuse_win and vim.fn.win_findbuf(b)[1] or win
				api.nvim_win_set_buf(w, b)
				api.nvim_win_set_cursor(w, { item.lnum, item.col - 1 })
				vim._with({ win = w }, function()
					-- Open folds under the cursor
					vim.cmd('normal! zv')
				end)
				return
			end

			if opts.loclist then
				vim.fn.setloclist(0, {}, ' ', { title = title, items = all_items })
				vim.cmd.lopen()
			else
				vim.fn.setqflist({}, ' ', { title = title, items = all_items })
				vim.cmd('botright copen')
			end
		end
	end

	-- TODO: This variable is the filepath of the buffer that containes the definition of the word on which the hower was
	-- called.
	local cword_definition_file = ""
	client:request(method, params, function(_, result)
	end)
	local cword_bufnr = vim.fn.bufadd(cword_definition_file)

	for _, client in ipairs(clients) do
		-- XXX: The issue is here. We do not have a uri for the popup window. The hack would be to calculate the position of
		-- the word in the text document. That is however impossible to do. Firstly, we change the whole buffer. Secondly,
		-- the server alters the text document. The numbers would not correspont either way.
		local params = util.make_position_params(api.nvim_get_current_win(), client.offset_encoding)
		vim.print("Params: " .. vim.inspect(params))
		client:request(method, params, function(_, result)
			on_response(_, result, client)
		end)
	end

	-- Remove the temporarily loaded buffer.
	-- TODO: Do it only in case that it was loaded in this function. Otherwise, it might be a buffer that was already loaded
	-- and we do not want to remove it.
	vim.cmd.bd(cword_bufnr)
end


M.winnr = 0
M.bufnr = 0

--- Check if a table contains desired element. vim.tbl_contains does not work for all cases.
---@param tbl table Table to be checked.
---@param el string Element to be checked.
---@return boolean True if the table contains the element, false otherwise.
function M.tbl_contains(tbl, el)
	if not el then
		return false
	end
	if not tbl then
		return false
	end

	for _, v in pairs(tbl) do
		if el:find(v) then
			return true
		end
	end
	return false
end

--- Checks the table for the desired element. If the element is found, it is returned, otherwise nil is returned.
---@param tbl table Table to be checked.
---@param el string Element to be checked for.
---@return string The element if it is found, nil otherwise.
function M.find(tbl, el)
	if not el then
		return ""
	end
	if not tbl then
		return ""
	end

	for _, v in pairs(tbl) do
		if el:find(v) then
			return el
		end
	end
	return ""
end

--- Count the printable strings in the table.
---@param tbl table Table of string from hover.
---@return number Number of printable lines.
function M.printable_table_size(tbl)
	local count = 0
	for _, el in pairs(tbl) do
		if el and not el:gmatch("```")() then
			count = count + 1
		end
	end
	return count
end

--- Splits a string into a table of strings.
---@param toSplit string String to be split.
---@param separator string|nil The separator. If not defined, the separator is set to "%S+".
---@return table Table of strings split by the separator.
function M.split(toSplit, separator)
	local indentation = nil
	local text_start_detected = false

	if separator == nil then
		indentation = string.match(toSplit, "^%s+")
		separator = "%S+"
	end

	if toSplit == nil then
		return {}
	end

	local chunks = {}
	if indentation ~= nil and indentation:len() > 0 then
		table.insert(chunks, indentation)
	end

	for substring in toSplit:gmatch(separator) do
		-- These both cases are here because of python server. Some servers have '.... ' in front of every line and some
		-- servers surround the whole message with '```text' and '```'. This is a workaround for that.
		if substring:sub(1, 2) == ". " then
			substring = substring:sub(5)
		end

		if substring == "```text" then
			text_start_detected = true
			goto continue
		end

		table.insert(chunks, substring)
		::continue::
	end

	-- If text start is detected (```text), remove the previoius to the last element.
	if text_start_detected then
		chunks[#chunks-2] = " "
	end

	return chunks
end

--- Join the elements of a table into a string with a delimiter.
---@param tbl table Table to be joined.
---@param delim string Delimiter to be used.
---@return string Joined string.
function M.join_table(tbl, delim)
	local result = ""
	for idx, chunk in pairs(tbl) do
		result = result .. chunk
		if idx ~= #tbl then
			result = result .. delim
		end
	end
	return result
end

--- This function checks all the active clients for current buffer and returns the active client that supports the current file type.
---@return table|nil Active client for the current buffer or nil if there is no active client.
function M.get_current_active_clent()
	for _, client in ipairs(compatibility.get_clients()) do
		if M.tbl_contains(client.config.filetypes, vim.bo.filetype) then
			return client
		end
	end
	return nil
end

--- Transforms the line from doxygen type into markdown
---@param line string Line to be transformed.
---@param config table Table of options to be used for the conversion to the markdown language.
---@param hl_data table Table of control variables to be used for the pop-up window highlighting.
---@param control table Table of control variables to be used for the conversion to the markdown language.
-- @return table Table of strings from doxygen to markdown.
function M.transform_line(line, config, control, hl_data)
	local result = {}
	local tbl = M.split(line)
	local el = tbl[1]
	local insertEmptyLine = false

	for name, group in pairs(config.hl) do
		if M.tbl_contains(group.detect, el) then
			tbl[1] = string.upper(M.find(group.detect, el))
			if tbl[1]:sub(1, 2) == '@' then
				tbl[1] = tbl[1]:sub(3)
			else
				tbl[1] = tbl[1]:sub(2)
			end
			hl_data.lines[tostring(name)].detected = true
			hl_data.replacement = tbl[1]
		end
	end

	if M.brief_detected and el and not el:sub(1,2):gmatch("[\\@]")() then
		table.insert(result, "")
		M.brief_detected = false
	end

	if M.tbl_contains(config.header.detect, el) then
		tbl[1] = config.header.styler
		insertEmptyLine = true;

	elseif M.tbl_contains(config.line.detect, el) then
		table.remove(tbl, 1)
		tbl[1] = config.line.styler .. tbl[1]
		tbl[#tbl] = tbl[#tbl] .. config.line.styler
		M.brief_detected = true

	elseif M.tbl_contains(config.listing.detect, el) then
		tbl[1] = config.listing.styler

	elseif M.tbl_contains(config.return_statement, el) then
		table.insert(result, "")
		tbl[1] = "**Return**"
		line = M.join_table(tbl, " ")

	elseif M.tbl_contains(config.code.start, el) then
		local language = el:gmatch("{(%w+)}")() or vim.o.filetype
		table.insert(result, "```" .. language)
		table.remove(tbl, 1)

	elseif M.tbl_contains(config.code.ending, el) then
		table.insert(result, "```")
		table.remove(tbl, 1)
	end

	for name, group in pairs(config.group.detect) do
		if group and M.tbl_contains(group, el) then
			tbl[2] = config.group.styler .. tbl[2] .. config.group.styler
			table.remove(tbl, 1)

			if control[name] then
				control[tostring(name)] = false
				table.insert(result, "---")
				table.insert(result, "**" .. name .. "**")
			end
		end
	end

	local ref = require("pretty_hover.references")
	tbl = ref.check_line_for_references(tbl, config)
	line = M.join_table(tbl, " ")
	table.insert(result, line)
	if insertEmptyLine then
		table.insert(result, "")
	end
	return result
end

--- Converts a string returned by response.result.contents.value from vim.lsp[textDocument/hover] to markdown.
---@param toConvert string Documentation of the string to be converted.
---@param config table Table of options to be used for the conversion to the markdown language.
---@param hl_data table Table of control variables to be used for the pop-up window highlighting.
---@return table Converted table of strings from doxygen to markdown.
function M.convert_to_markdown(toConvert, config, hl_data)
	config.one_liner = false
	local result = {}

	local control = {}
	for name, group in pairs(config.group.detect) do
		control[tostring(name)] = true
	end

	local chunks = M.split(toConvert, "([^\n]*)\n?")
	if #chunks == 0 then
		return result
	end

	-- Remove footer padding. The last line is always empty.
	if chunks[#chunks] == "" then
		table.remove(chunks, #chunks)
	end

	for name, _ in pairs(config.hl) do
		hl_data.lines[tostring(name)] = {}
	end

	for _, chunk in pairs(chunks) do
		local toAdd = M.transform_line(chunk, config, control, hl_data)
		vim.list_extend(result, toAdd)

		for name, group in pairs(hl_data.lines) do
			if group.detected then
				group.detected = false
				table.insert(hl_data.lines[tostring(name)], {
					line_nr = M.printable_table_size(result) - 2,
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

--- Close the opened floating window.
function M.close_float()
	-- Safeguard around accidentally calling close when there is no pretty_hover window open
	if M.winnr == 0 and M.bufnr == 0 then
		return
	end

	-- Before closing the window, check if it is still valid.
	if not api.nvim_win_is_valid(M.winnr) then
		M.winnr = 0
		M.bufnr = 0
		return
	end

	api.nvim_win_close(M.winnr, true)
	M.winnr = 0
	M.bufnr = 0
	M.original_buffer = 0
end

--- Opens a floating window with the documentation transformed from doxygen to markdown.
---@param hover_text string Text to be converted.
---@param config table Table of options to be used for the conversion to the markdown language.
function M.open_float(hover_text, config)
	if not hover_text or hover_text:len() == 0 then
		-- There is nothing to display, quit out early
		vim.notify("No information available", vim.log.levels.INFO)
		return
	end

	local hl_data = {
		replacement = "",
		lines = {},
	}

	-- Convert Doxygen comments to Markdown format
	local tbl = M.convert_to_markdown(hover_text, config, hl_data)
	if #tbl == 0 then
		vim.notify("No information available", vim.log.levels.INFO)
		return
	end

	if config.toggle and M.winnr ~= 0 then
		M.close_float()
		return
	end

	local language = 'markdown'
	if config.one_liner then
		language = vim.bo.filetype
	end

	M.original_buffer = vim.api.nvim_get_current_buf()
	M.original_win = api.nvim_get_current_win()
	M.bufnr, M.winnr = vim.lsp.util.open_floating_preview(tbl, language, {
		border = config.border,
		focusable = true,
		focus = true,
		focus_id = "pretty-hover",
		wrap_at = config.max_width,
		max_width = config.max_width,
		max_height = config.max_height,
	})

	vim.wo[M.winnr].foldenable = false
	vim.bo[M.bufnr].modifiable = false
	vim.bo[M.bufnr].bufhidden = 'wipe'


	vim.api.nvim_buf_set_keymap(M.bufnr, 'n', 'gd', '<cmd>lua require("pretty_hover.core.util").definition()<CR>', {
		noremap = true,
		silent = true,
	})

	hl.apply_highlight(config, hl_data, M.bufnr)

	vim.keymap.set('n', 'q', M.close_float, {
		buffer = M.bufnr,
		silent = true,
		nowait = true,
	})
end

return M

