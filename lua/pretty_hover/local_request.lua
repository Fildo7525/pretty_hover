local api = vim.api
local lsp = vim.lsp
local util = vim.lsp.util
local hover_ns = api.nvim_create_namespace('pretty_hover_range')
local cfg = require("pretty_hover.config")

local h_util = require("pretty_hover.core.util")
local number = require("pretty_hover.number")

local M = {}

local function parse_response_contents(contents)
	local hover_text = contents.value;
	-- vtsls workaround, this lsp does not contain value in the contents. It's just pure text.
	if type(contents) == "string" then
		hover_text = contents
	end

	if hover_text ~= nil then
		return hover_text
	end

	-- typescript-tools.nvim workaround
	-- Add a test in case there are no contents.
	if not pcall(function() hover_text = contents[1].value end) then
		return
	end

	for i = 2, #contents do
		if type(contents[i]) ~= "string" then
			vim.notify("Unexpected item type found in hover request's response.\n" ..
				"Please report an issue on github: https://github.com/Fildo7525/pretty_hover",
				vim.log.levels.ERROR)
			break
		end
		hover_text = hover_text .. contents[i]
	end
	return hover_text
end

local function request_below11(results)
	local called = false

	for _, response in pairs(results) do
		if response.result and response.result.contents and called == false then
			called = true
			local contents = response.result.contents

			-- We have to do this because of java. Sometimes is the value parameter split
			-- into two chunks. Leaving the rest of the hover message as the second argument
			-- in the received table.
			if contents.language == "java" then
				for _, content in pairs(contents) do
					local hover_text = content.value or content
					if not hover_text then
						vim.notify("There is no text to be displayed", vim.log.levels.INFO)
						return
					end

					h_util.open_float(hover_text, "markdown", cfg:instance())
				end
			else
				local hover_text = parse_response_contents(response.result.contents)
				if not hover_text then
					vim.notify("There is no text to be displayed", vim.log.levels.INFO)
					return
				end

				h_util.open_float(hover_text, "markdown", cfg:instance())
			end
		end
	end

	if not called then
		local hover_text = number.get_number_representations()
		if not hover_text then
			return
		end

		h_util.open_float(hover_text, "markdown", cfg:instance())
		return
	end
end

local function request_above11(results, ctx)
	local bufnr = assert(ctx.bufnr)
	if api.nvim_get_current_buf() ~= bufnr then
		-- Ignore result since buffer changed. This happens for slow language servers.
		return
	end

	-- Filter errors from results
	local results1 = {} --- @type table<integer,lsp.Hover>

	for client_id, resp in pairs(results) do
		local err, result = resp.err, resp.result
		if err then
			lsp.log.error(err.code, err.message)
		elseif result then
			results1[client_id] = result
		end
	end

	if vim.tbl_isempty(results1) then
		if cfg:instance().hover_cnf.silent ~= true then
			vim.notify('No information available')
		end
		return
	end

	local contents = {} --- @type string[]

	local nresults = #vim.tbl_keys(results1)

	local format = 'markdown'

	for client_id, result in pairs(results1) do
		local client = assert(lsp.get_client_by_id(client_id))
		if nresults > 1 then
			-- Show client name if there are multiple clients
			contents[#contents + 1] = string.format('# %s', client.name)
		end
		if type(result.contents) == 'table' and result.contents.kind == 'plaintext' then
			if #results1 == 1 then
				format = 'plaintext'
				contents = vim.split(result.contents.value or '', '\n', { trimempty = true })
			else
				-- Surround plaintext with ``` to get correct formatting
				contents[#contents + 1] = '```'
				vim.list_extend(
					contents,
					vim.split(result.contents.value or '', '\n', { trimempty = true })
				)
				contents[#contents + 1] = '```'
			end
		else
			vim.list_extend(contents, util.convert_input_to_markdown_lines(result.contents))
		end
		local range = result.range
		if range then
			local start = range.start
			local end_ = range['end']
			local start_idx = util._get_line_byte_from_position(bufnr, start, client.offset_encoding)
			local end_idx = util._get_line_byte_from_position(bufnr, end_, client.offset_encoding)

			vim.hl.range(
				bufnr,
				hover_ns,
				'LspReferenceTarget',
				{ start.line, start_idx },
				{ end_.line, end_idx },
				{ priority = vim.hl.priorities.user }
			)
		end
		contents[#contents + 1] = '---'
	end

	-- Remove last linebreak ('---')
	contents[#contents] = nil

	if vim.tbl_isempty(contents) then
		if cfg:instance().hover_cnf.silent ~= true then
			vim.notify('No information available')
		end
		return
	end

	local _, winnr = h_util.open_float(contents, format, cfg:instance())

	-- Remove selection highlighting after window is closed
	api.nvim_create_autocmd('WinClosed', {
		pattern = tostring(winnr),
		once = true,
		callback = function()
			api.nvim_buf_clear_namespace(bufnr, hover_ns, 0, -1)
			return true
		end,
	})
end

--- Function that will be used in hover request invoked by lsp.
---@param results table Table of responses from the server.
---@param ctx table Context of the request.
function M.local_hover_request(results, ctx)
	-- Multi-server support is only available in nvim-0.11 and above.
	-- The user can still decide to use the multi-server or not.
	if vim.fn.has('nvim-0.11') == 1 and cfg:instance().multi_server then
		request_above11(results, ctx)
		return
	end

	request_below11(results)
end

return M
