local M = {}

--- Convert the input number to the specified base.
--- @param num number Number to be converted.
--- @param base number Base to convert the number to.
--- @return string The number converted into specified base in a string format.
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

--- Function to convert a number to its binary representation
--- @see toBase
--- @param num number Number to be converted.
--- @return string The number converted into binary in a string format.
function M.toBinary(num)
	return M.toBase(num, 2)
end

--- Function to convert a number to its octal representation
--- @see toBase
--- @param num number Number to be converted.
--- @return string The number converted into octal in a string format.
function M.toOctal(num)
	return M.toBase(num, 8)
end

--- Function to convert a number to its hexadecimal representation
--- @see toBase
--- @param num number Number to be converted.
--- @return string The number converted into hexadecimal in a string format.
function M.toHex(num)
	return M.toBase(num, 16)
end

--- Pretty prints the decimal number by adding spaces after every 3 digits.
--- @param num string Number to be pretty printed.
--- @return string The pretty printed number.
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

--- Get the type of the number.
--- @param num string Number to get the type of.
--- @return number|nil The type of the number.
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

--- Function to get all representations of a number
--- @param num string Number to get the representations of.
--- @param type number Type of the number.
--- @param return_type string The type of the return value, either "string" or "table".
--- @return string[]|nil A table containing the representations of the number in different bases.
function M.get_numerical_representations(num, type, return_type)
	local tmp = tonumber(num, type)
	if not tmp then
		return nil
	end

	local decimal = M.prettyDecimal(tostring(tmp))
	local binary = M.toBinary(tmp)
	local octal = M.toOctal(tmp)
	local hexadecimal = M.toHex(tmp)

	local s =  string.format("### Number types:\n---\nBinary: 0b%s\nOctal: 0o%s\nDecimal: %s\nHexadecimal: 0x%s\n", binary, octal, decimal, hexadecimal)
	if return_type == "string" then
		return s
	end
	return s:split("\n")
end

--- Function to get the number representations of the current word under the cursor.
--- @see get_number_type
--- @param return_type? string The number to get the representations of.
--- @return string|string[]|nil The number representations of the current word under the cursor.
function M.get_number_representations(return_type)
	local num = vim.fn.expand("<cword>");
	if return_type == nil then
		return_type = "table"
	end

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
	return M.get_numerical_representations(num, number_type, return_type)
end

return M
