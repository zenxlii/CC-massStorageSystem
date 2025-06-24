



--Recipe Making Functions

--Makes a crafting table recipe and
--returns the final product and recipe.
local function makeCTableRecipe(productTable, batchLim, ingredientsTable, byproductsTable)
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
	if byproductsTable then
		error("Byproducts are not supported yet!")
	end
	--recipeList[productTable[1]] = recipe
	return productTable[1], recipe
end

--Makes an external non-machine
--crafting recipe and returns the final
--product and the recipe itself.
local function makeExternalRecipe(productTable, batchLim, ingredientsTable, recipeClass, inInvs, byproductsTable)
	local recipe = {}
	recipe[1] = productTable[2]
	recipe[2] = batchLim
	local ingInvs = {}
	for index, ingData in pairs(ingredientsTable) do
		ingInvs[inInvs[index]] = {ingData[1], ingData[2]}
	end
	recipe[3] = ingInvs
	recipe[4] = recipeClass
	if byproductsTable then
		error("Byproducts are not supported yet!")
	end
	return productTable[1], recipe
end

return{
makeCTableRecipe = makeCTableRecipe,
makeExternalRecipe = makeExternalRecipe
}