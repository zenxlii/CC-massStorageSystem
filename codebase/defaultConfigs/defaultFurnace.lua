--Required Stuff
local core = require("recipeCoreDefs")

local n = core.sh

local inInvs = {
"Put your ingredient inventories here!",
"One inventory at a time, in the same",
"order as the ingredients are inside of",
"the recipes themselves."
}

local recipeList = {}
--Relevant Recipe Function Wrapper
local function addRecipe(productTable, batchLim, ingredientsTable, byproductsTable)
	local eName, recipeData = core.makeExternalRecipe(productTable, batchLim, ingredientsTable, "furnace", inInvs, byproductsTable)
	recipeList[eName] = recipeData
end
--User-Defined Recipes

--Below is an example recipe.
addRecipe({"minecraft:brick",1},64,{"minecraft:clay",1})


--Final Return Statement

return{
recipeList = recipeList
}