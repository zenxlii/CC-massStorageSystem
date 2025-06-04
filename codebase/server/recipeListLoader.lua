--Imports
local config = require("config")

local dir = config.recipesDir

local recipeList = {}

local recipeFiles = fs.list(dir)

--Recipe Making Functions

--Makes a crafting table recipe and
--adds it to the recipe list.
local function makeCTableRecipe(productTable, batchLim, ingredientsTable)
	local recipe = {}
	recipe[1] = productTable[2]
	recipe[2] = batchLim
	local ingSlots = {}
	for index, eName in pairs(ingredientsTable) do
		if index < 4 then
			ingSlots[index] = {eName, 1}
		elseif index < 7 then
			ingSlots[index+1] = {eName, 1}
		else
			ingSlots[index+2] = {eName, 1}
		end
	end
	recipe[3] = ingSlots
	recipe[4] = "craftingTable"
	recipeList[productTable[1]] = recipe
end

--Test Recipes
--TODO:
--Move each machine "type" of recipe to
--a separate file that requires a file
--that has the recipeList in it, and
--then have a final file require all of
--the individual recipe adder files.

makeCTableRecipe({"minecraft:redstone_torch",1},64,{"minecraft:redstone",nil,nil,"minecraft:stick"})
makeCTableRecipe({"minecraft:stick",4},64,{"minecraft:birch_planks",nil,nil,"minecraft:birch_planks"})
makeCTableRecipe({"minecraft:birch_planks",4},64,{"minecraft:birch_log"})

return{
recipeList = recipeList
}