local M = {}

function M.toBase(num, base)
	local baseChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local baseStr = ""
	local idx = 0
	while num > 0 do
		local rem = num % base
		baseStr = baseChars:sub(rem + 1, rem + 1) .. baseStr
		num = math.floor(num / base)

		idx = idx + 1
		if idx % 4 == 0 and num > 0 then
			baseStr = " " .. baseStr
		end
	end
	return baseStr == "" and "0" or baseStr
end

-- Function to convert a number to its binary representation
function M.toBinary(num)
	return M.toBase(num, 2)
end

-- Function to convert a number to its octal representation
function M.toOctal(num)
	return M.toBase(num, 8)
end

-- Function to convert a number to its hexadecimal representation
function M.toHex(num)
	return M.toBase(num, 16)
end

function M.prettyDecimal(num)
	local len = #num
	local pretty = ""
	local idx = 0

	for i = len, 1, -1 do
		pretty = num:sub(i, i) .. pretty
		idx = idx + 1
		if idx % 3 == 0 and i ~= 1 then
			pretty = " " .. pretty
		end
	end

	return pretty
end

function M.get_number_type(num)
	local original
	if type(num) == 'string' and tonumber(num) then
		original = num
	else
		return nil
	end

	if original[1] ~= 0 or #original < 2 then
		return 10
	elseif original[2] == 'x' then
		return 16
	elseif original[2] == 'b' then
		return 2
	elseif original[2] == 'o' then
		return 8
	else
		return 10
	end
end

-- Function to get all representations of a number
function M.get_numerical_representations(num, type)
	local tmp = tonumber(num, type)
	if not tmp then
		return nil
	end

	local decimal = M.prettyDecimal(tostring(tmp))
	local binary = M.toBinary(tmp)
	local octal = M.toOctal(tmp)
	local hexadecimal = M.toHex(tmp)

	return string.format("### Number types:\n---\nBinary: 0b%s\nOctal: 0o%s\nDecimal: %s\nHexadecimal: 0x%s\n", binary, octal, decimal, hexadecimal)
end

function M.get_number_representations()
	local num = vim.fn.expand("<cword>");
	if num:sub(1,1) == '-' then
		num = num:sub(2)
	end

	local number_type = M.get_number_type(num)
	if not number_type then
		return
	end

	if number_type ~= 10 then
		num = num:sub(2)
	end
	return M.get_numerical_representations(num, number_type)
end

return M
