local compactedFiles = false

local craftingTypeTable = {}
--Makes craftingTypes.txt if it does
--not exist and initialises it.
if not fs.exists("craftingTypes.txt") then
	local file = fs.open("craftingTypes.txt", "w")
	local ctct = {}
	ctct[1] = "c"
	ctct[2] = {"server"}
	ctct[3] = {1,2,3,5,6,7,9,10,11}
	craftingTypeTable["craftingTable"] = ctct
	file.write(textutils.serialise(craftingTypeTable, {compact = compactedFiles}))
	file.close()
	craftingTypeTable = {}
end

--Load the contents of
--craftingTypes.txt into a table.
local ctFile = fs.open("craftingTypes.txt", "r")
craftingTypeTable = textutils.unserialise(ctFile)
ctFile = nil

local recipeTable = {}
--Ensures that recipeData.txt exists.
if not fs.exists("recipeData.txt") then
	local file = fs.open("recipeData.txt", "w")
	file.close()
end

local recipeType = "doesn't exist, please don't use this as a recipe type you-"
if craftingTypeTable[recipeType] ~= nil then
	error("WHY IS THIS EVEN A CRAFTING TYPE?!?!?")
end
while recipeType == "doesn't exist, please don't use this as a recipe type you-" do
	local prompt = {}
	prompt[1] = ""
	prompt[2] = ""
	prompt[3] = "What crafting type would you like this"
	prompt[4] = "recipe to be? Valid values are:"
	local i = 5
	for line, _ in pairs(craftingTypeTable) do
		prompt[i] = line
		i = i + 1
	end
	i = nil
	local width, height = term.getCursorPos()
	textutils.pagedPrint(prompt, height - 2)
	
	local input = io.read()
	if craftingTypeTable[input] == nil then
		prompt[1] = input
		prompt[2] = "is not a valid value."
	else
		recipeType = input
	end
end

--This program can only create recipes
--with at most 9 input slots and 7
--output slots.
--Anything more complicated than this
--will require writing the recipe
--manually.
local recipeInputs = {}
local recipeOutputs = {}