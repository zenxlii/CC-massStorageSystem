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

--Below is an example recipe.
addRecipe({"minecraft:torch",4},64,{"minecraft:charcoal",nil,nil,"minecraft:stick"})


--Final Return Statement

return{
recipeList = recipeList
}