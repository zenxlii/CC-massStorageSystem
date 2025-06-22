--Imports
local commonCodeDisk = require("commonCodeDisk")
local ccd = commonCodeDisk.commonCodeDisk
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

--Item Renames
local stick = "minecraft:stick"
local plank = "minecraft:birch_planks"
local stone = "minecraft:stone"
local refIron = "techreborn:refined_iron_ingot"
local bmFrame = "techreborn:basic_machine_frame"
local eCircuit = "techreborn:electronic_circuit"
local treetap = "techreborn:treetap#552887824c43124013fd24f6edcde0fb"
--Generic Components
makeCTableRecipe({"minecraft:redstone_torch",1},64,{"minecraft:redstone",nil,nil,stick})
makeCTableRecipe({stick,4},64,{plank,nil,nil,plank})
makeCTableRecipe({plank,4},64,{"minecraft:birch_log"})
--Tech Reborn Components
makeCTableRecipe({bmFrame,1},64,{refIron,refIron,refIron,refIron,nil,refIron,refIron,refIron,refIron})
makeCTableRecipe({treetap,1},16,{nil,stick,nil,plank,plank,plank,plank})
--Tech Reborn Machines
makeCTableRecipe({"techreborn:compressor",1},64,{stone,nil,stone,stone,bmFrame,stone,stone,eCircuit,stone})
makeCTableRecipe({"techreborn:extractor",1},1,{treetap,bmFrame,treetap,treetap,eCircuit,treetap})

return{
recipeList = recipeList
}