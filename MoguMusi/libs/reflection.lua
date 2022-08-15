local function FindUpvalue(fn, upvalue_name)
	assert(type(fn) == "function", "Function expected as 'fn' parameter.")

	local info = debug.getinfo(fn, "u")
	local nups = info and info.nups
	if not nups then return end

	local getupvalue = debug.getupvalue

	for i = 1, nups do
		local name, val = getupvalue(fn, i)
		if name == upvalue_name then
			return val, true
		end
	end
end

local function SetUpvalue(fn, upvalue_name, value)
	assert(type(fn) == "function", "Function expected as 'fn' parameter.")

	local info = debug.getinfo(fn, "u")
	local nups = info and info.nups
	if not nups then return end

	local getupvalue = debug.getupvalue
	local setupvalue = debug.setupvalue

	for i = 1, nups do
		local name, val = getupvalue(fn, i)
		if name == upvalue_name then
			setupvalue(fn, i, value)
		end
	end
end

return {
	FindUpvalue = FindUpvalue,
	SetUpvalue = SetUpvalue,
}