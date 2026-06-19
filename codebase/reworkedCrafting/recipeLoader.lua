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
	ctct[4] = {}
	craftingTypeTable["craftingTable"] = ctct
	file.write(textutils.serialise(craftingTypeTable, {compact = compactedFiles}))
	file.close()
	craftingTypeTable = {}
end

--Load the contents of
--craftingTypes.txt into a table.
local ctFile = fs.open("craftingTypes.txt", "r")
craftingTypeTable = textutils.unserialise(ctFile.readAll())
ctFile.close()
ctFile = nil

local masterRecipeTable = {}
--Makes recipeData.txt if it does not
--exist and initialises it.
if not fs.exists("recipeData.txt") then
	local file = fs.open("recipeData.txt", "w")
	local rd = {}
	rd[1] = {{"minecraft:torch",4}}
	rd[2] = {{"minecraft:charcoal"},nil,nil,nil,{"minecraft:stick"},nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil}
	rd[3] = 64
	rd[4] = "craftingTable"
	masterRecipeTable[1] = rd
	file.write(textutils.serialise(masterRecipeTable, {compact = compactedFiles}))
	file.close()
	masterRecipeTable = {}
end

local resourcePoolTable = {}
--Makes resourcePools.txt if it does
--not exist and initialises it.
if not fs.exists("resourcePools.txt") then
	local file = fs.open("resourcePools.txt", "w")
	local rp = {}
	rp = {}
	rp[1] = {{"minecraft:iron_nugget",1},{"minecraft:iron_ingot",9},{"minecraft:iron_block",81}}
	rp[2] = {}
	rp[2][1] = {}
	rp[2][1][1] = {{{"minecraft:iron_block"}},{{"minecraft:iron_ingot"},{"minecraft:iron_ingot"},{"minecraft:iron_ingot"},nil,{"minecraft:iron_ingot"},{"minecraft:iron_ingot"},{"minecraft:iron_ingot"},nil,{"minecraft:iron_ingot"},{"minecraft:iron_ingot"},{"minecraft:iron_ingot"},nil,nil,nil,nil,nil},64,"craftingTable"}
	rp[2][1][2] = {{{"minecraft:iron_ingot",9}},{{"minecraft:iron_block"}},64,"craftingTable"}
	rp[2][2] = {}
	rp[2][2][1] = {{{"minecraft:iron_ingot"}},{{"minecraft:iron_nugget"},{"minecraft:iron_nugget"},{"minecraft:iron_nugget"},nil,{"minecraft:iron_nugget"},{"minecraft:iron_nugget"},{"minecraft:iron_nugget"},nil,{"minecraft:iron_nugget"},{"minecraft:iron_nugget"},{"minecraft:iron_nugget"},nil,nil,nil,nil,nil},64,"craftingTable"}
	rp[2][2][2] = {{{"minecraft:iron_nugget",9}},{{"minecraft:iron_ingot"}},64,"craftingTable"}
	resourcePoolTable["iron"] = rp
	file.write(textutils.serialise(resourcePoolTable, {compact=compactedFiles}))
	file.close()
	resourcePoolTable = {}
end

--Load the contents of recipeData.txt
--into a table.
local rdFile = fs.open("recipeData.txt", "r")
masterRecipeTable = textutils.unserialise(rdFile.readAll())
rdFile.close()
rdFile = nil

--Load the contents of
--resourcePools.txt into a table.
local rpFile = fs.open("resourcePools.txt", "r")
resourcePoolTable = textutils.unserialise(rpFile.readAll())
rpFile.close()
rpFile = nil

local function makeSlotBasedRecipe(recipeDataTable)
	return "bruh"
end

local function makeInventoryBasedRecipe(recipeDataTable)
	return "bruh"
end

local function makeCraftingTableRecipeSpecial(recipeDataTable)
	return "bruh"
end

--Create a table that assigns recipes
--to the encoded names of their
--output(-s).
local recipeMap = {}
for i, recipe in ipairs(masterRecipeTable) do
	local priority = 0
	--If there is no quantity next to
	--an ingredient or result, set it
	--to 1.
	for j, resultData in pairs(recipe[1]) do
		if resultData[2] == nil then
			masterRecipeTable[i][1][j][2] = 1
		end
	end
	for j, ingredientData in pairs(recipe[2]) do
		if ingredientData[2] == nil then
			masterRecipeTable[i][2][j][2] = 1
		end
	end
	--Assign priority if relevant.
	if recipe[5] ~= nil then
		priority = recipe[5]
	end
	for _, item in pairs(recipe[1]) do
		if recipe[5] == nil then
			if recipeMap[item[1]] == nil then
				recipeMap[item[1]] = {}
			end
			priority = #recipeMap[item[1]] + 1
		end
		if recipe[6] == nil then
			if recipeMap[item[1]] == nil then
				recipeMap[item[1]] = {}
			end
			if recipeMap[item[1]][priority] == nil then
				recipeMap[item[1][priority] = i
			else
				if recipe[5] then
					recipeMap[item[1]][priority] = i
				else
					print("A recipe is trying to override another")
					print("without the proper permissions!")
					print(item[1])
					print(i)
					error("Check this recipe ID!")
				end
			end
		else
			--Deliberately skips over
			--items excluded by
			--recipe[6]'s contents.
			if not recipe[6][item[1]] then
				if recipeMap[item[1]] == nil then
					recipeMap[item[1]] = {}
				end
				if recipeMap[item[1]][priority] == nil then
					recipeMap[item[1][priority] = i
				else
					if recipe[5] then
						recipeMap[item[1]][priority] = i
					else
						print("A recipe is trying to override another")
						print("without the proper permissions!")
						print(item[1])
						print(i)
						error("Check this recipe ID!")
					end
				end
			end
		end
	end
end
--Note that resource pool recipes are
--not added to the masterRecipeTable,
--this is by design.

return{
craftingTypeTable = craftingTypeTable,
masterRecipeTable = masterRecipeTable,
recipeMap = recipeMap,
resourcePoolTable = resourcePoolTable
}