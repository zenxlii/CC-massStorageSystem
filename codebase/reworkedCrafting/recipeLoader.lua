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
	ctct[4] = {16}
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

local masterRecipeTable = {}

local function makeSlotBasedRecipe(recipeDataTable)
	
end