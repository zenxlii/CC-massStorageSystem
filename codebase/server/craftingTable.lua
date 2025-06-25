--Required Stuff
local core = require("recipeCoreDefs")

local n = core.sh

local recipeList = {}
--Relevant Recipe Function Wrapper
local function addRecipe(productTable, batchLim, ingredientsTable, byproductsTable)
	local eName, recipeData = core.makeCTableRecipe(productTable, batchLim, ingredientsTable, byproductsTable)
	recipeList[eName] = recipeData
end
--User-Defined Recipes

--Generic Components
addRecipe({"minecraft:redstone_torch",1},64,{"minecraft:redstone",nil,nil,n.stick})
addRecipe({n.stick,4},64,{n.plank,nil,nil,n.plank})
addRecipe({n.plank,4},64,{"minecraft:birch_log"})
addRecipe({"minecraft:torch",4},64,{"minecraft:charcoal",nil,nil,n.stick})
--Tech Reborn Components
addRecipe({n.bmFrame,1},64,{n.refIron,n.refIron,n.refIron,n.refIron,nil,n.refIron,n.refIron,n.refIron,n.refIron})
addRecipe({n.treetap,1},16,{nil,n.stick,nil,n.plank,n.plank,n.plank,n.plank})
--Tech Reborn Machines
addRecipe({"techreborn:compressor",1},64,{n.stone,nil,n.stone,n.stone,n.bmFrame,n.stone,n.stone,n.eCircuit,n.stone})
addRecipe({"techreborn:extractor",1},1,{n.treetap,n.bmFrame,n.treetap,n.treetap,n.eCircuit,n.treetap})

--Final Return Statement

return{
recipeList = recipeList
}