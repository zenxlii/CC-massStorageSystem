--Recipe Format Notes:
--The recipe list key will be the
--encoded name of the primary product,
--and the nested table value will be
--as follows:
--1. How much of the primary product is
--made by this recipe.
--2. How many instances of this recipe
--can be put into a single batch.
--3. A table of recipe ingredients,
--indexed by either the target slot
--number or the target inventory,
--depending on what handler is used as
--the base. Each ingredient has both an
--encoded name and quantity specified.
--4. The class of recipe that this is,
--will later be used to determine which
--inventories to insert into rather
--than having that data in the recipe
--definition itself, to save on RAM
--usage.
--5. (OPTIONAL) A table of byproducts
--that this recipe produces in addition
--to the primary product. However, this
--currently has not been implemented,
--and attempting to define this will
--cause the server program to error.

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

--Item Shorthand Table

--(called "sh" for compactness)
local sh = {}
--Item Shorthands
sh.stick = "minecraft:stick"
sh.plank = "minecraft:birch_planks"
sh.stone = "minecraft:stone"
sh.cobble = "minecraft:cobblestone"
sh.rs = "minecraft:redstone"
sh.iron = "minecraft:iron_ingot"
sh.tin = "techreborn:tin_ingot"
sh.refIron = "techreborn:refined_iron_ingot"
sh.bmFrame = "techreborn:basic_machine_frame"
sh.eCircuit = "techreborn:electronic_circuit"
sh.treetap = "techreborn:treetap#552887824c43124013fd24f6edcde0fb"
sh.cell = "techreborn:cell"

return{
makeCTableRecipe = makeCTableRecipe,
makeExternalRecipe = makeExternalRecipe,
sh = sh
}