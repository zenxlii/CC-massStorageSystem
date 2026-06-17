

local recipeTable = {}

local function safeTextInputPrompt(prompt)
	--slightly faster than calling
	--type(prompt) multiple times.
	local pType = type(prompt)
	if pType == "string" then
		print(prompt)
	elseif pType == "table" then
		for _, line in pairs(prompt) do
			print(line)
		end
	else
		error("Invalid prompt datatype!")
	end
	local returnVal = io.read()
	return returnVal
end

local recipeType = "doesn't exist, please don't use this as a recipe type you-"
while recipeType == "doesn't exist, please don't use this as a recipe type you-" do
	print()
end