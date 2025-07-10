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
sh.belt = "create:belt_connector"
sh.shaft = "create:shaft"
sh.cog = "create:cogwheel"
sh.bigCog = "create:large_cogwheel"
sh.eTube = "create:electron_tube"
sh.aCasing = "create:andesite_casing"
sh.bCasing = "create:brass_casing"
sh.cCasing = "create:copper_casing"
sh.blackDye = "minecraft:black_dye"
sh.netherite = "minecraft:netherite_ingot"
sh.stick = "minecraft:stick"
sh.plank = "minecraft:birch_planks"
sh.plankS = "minecraft:birch_slab"
sh.chest = "minecraft:chest"
sh.barrel = "minecraft:barrel"
sh.paper = "minecraft:paper"
sh.stone = "minecraft:stone"
sh.cobble = "minecraft:cobblestone"
sh.obsidian = "minecraft:obsidian"
sh.furnace = "minecraft:furnace"
sh.piston = "minecraft:piston"
sh.sand = "minecraft:sand"
sh.gravel = "minecraft:gravel"
sh.flint = "minecraft:flint"
sh.glass = "minecraft:glass"
sh.glassP = "minecraft:glass_pane"
sh.ironBars = "minecraft:iron_bars"
sh.dKelp = "minecraft:dried_kelp"
sh.nRack = "minecraft:netherrack"
sh.dirt = "minecraft:dirt"
sh.bucket = "minecraft:bucket"
sh.glowstone = "minecraft:glowstone_dust"
sh.glowstoneB = "minecraft:glowstone"
sh.quartz = "minecraft:quartz"
sh.rs = "minecraft:redstone"
sh.iron = "minecraft:iron_ingot"
sh.gold = "minecraft:gold_ingot"
sh.copper = "minecraft:copper_ingot"
sh.tin = "techreborn:tin_ingot"
sh.aluminium = "techreborn:aluminum_ingot"
sh.chrome = "techreborn:chrome_ingot"
sh.zinc = "create:zinc_ingot"
sh.nickel = "techreborn:nickel_ingot"
sh.electrum = "techreborn:electrum_ingot"
sh.bronze = "techreborn:bronze_ingot"
sh.invar = "techreborn:invar_ingot"
sh.brass = "techreborn:brass_ingot"
sh.refIron = "techreborn:refined_iron_ingot"
sh.aAlloy = "techreborn:advanced_alloy_ingot"
sh.steel = "techreborn:steel_ingot"
sh.andAlloy = "create:andesite_alloy"
sh.ironN = "minecraft:iron_nugget"
sh.bmFrame = "techreborn:basic_machine_frame"
sh.amFrame = "techreborn:advanced_machine_frame"
sh.imFrame = "techreborn:industrial_machine_frame"
sh.eCircuit = "techreborn:electronic_circuit"
sh.aCircuit = "techreborn:advanced_circuit"
sh.iCircuit = "techreborn:industrial_circuit"
sh.dsCore = "techreborn:data_storage_core"
sh.treetap = "techreborn:treetap#552887824c43124013fd24f6edcde0fb"
sh.cell = "techreborn:cell"
sh.ironP = "techreborn:iron_plate"
sh.goldP = "techreborn:gold_plate"
sh.copperP = "techreborn:copper_plate"
sh.tinP = "techreborn:tin_plate"
sh.aluminiumP = "techreborn:aluminum_plate"
sh.chromeP = "techreborn:chrome_plate"
sh.zincP = "techreborn:zinc_plate"
sh.nickelP = "techreborn:nickel_plate"
sh.electrumP = "techreborn:electrum_plate"
sh.bronzeP = "techreborn:bronze_plate"
sh.invarP = "techreborn:invar_plate"
sh.brassP = "techreborn:brass_plate"
sh.refIronP = "techreborn:refined_iron_plate"
sh.aAlloyP = "techreborn:advanced_alloy_plate"
sh.steelP = "techreborn:steel_plate"
sh.tinC = "techreborn:tin_cable"
sh.copperC = "techreborn:copper_cable"
sh.goldC = "techreborn:gold_cable"
sh.hvC = "techreborn:hv_cable"
sh.rubber = "techreborn:rubber"

return{
makeCTableRecipe = makeCTableRecipe,
makeExternalRecipe = makeExternalRecipe,
sh = sh
}