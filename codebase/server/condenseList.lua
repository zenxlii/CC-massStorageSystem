--Table of items that should be
--auto-condensed by the server program.
--The sub-table structure is as
--follows:
--1. Input encoded name.
--2. Recipe type.
--3. Output encoded name.
--4. Maximum batch craft size.
--Note that situations such as nuggets
--to ingots to blocks should have the
--nugget to ingot recipe be inserted
--into condenseTable before the ingot
--to block recipe.
local condenseTable = {}
table.insert(condenseTable, {"minecraft:redstone", "3x3", "minecraft:redstone_block", 64})
table.insert(condenseTable, {"minecraft:lapis_lazuli", "3x3", "minecraft:lapis_block", 64})
table.insert(condenseTable, {"minecraft:emerald", "3x3", "minecraft:emerald_block", 64})
table.insert(condenseTable, {"minecraft:diamond", "3x3", "minecraft:diamond_block", 64})
table.insert(condenseTable, {"minecraft:coal", "3x3", "minecraft:coal_block", 64})
table.insert(condenseTable, {"techreborn:ruby_gem", "3x3", "techreborn:ruby_storage_block", 64})
table.insert(condenseTable, {"techreborn:sapphire_gem", "3x3", "techreborn:sapphire_storage_block", 64})
table.insert(condenseTable, {"minecraft:iron_nugget", "3x3", "minecraft:iron_ingot", 64})
table.insert(condenseTable, {"minecraft:iron_ingot", "3x3", "minecraft:iron_block", 64})
table.insert(condenseTable, {"minecraft:gold_nugget", "3x3", "minecraft:gold_ingot", 64})
table.insert(condenseTable, {"minecraft:gold_ingot", "3x3", "minecraft:gold_block", 64})
table.insert(condenseTable, {"create:copper_nugget", "3x3", "minecraft:copper_ingot", 64})
table.insert(condenseTable, {"minecraft:copper_ingot", "3x3", "minecraft:copper_block", 64})
table.insert(condenseTable, {"minecraft:clay_ball", "2x2", "minecraft:clay", 64})
table.insert(condenseTable, {"minecraft:rotten_flesh", "3x3", "blockus:rotten_flesh_block", 64})
table.insert(condenseTable, {"minecraft:ender_pearl", "3x3", "charm:ender_pearl_block", 16})
table.insert(condenseTable, {"create:zinc_nugget", "3x3", "create:zinc_ingot", 64})
table.insert(condenseTable, {"create:zinc_ingot", "3x3", "create:zinc_block", 64})
table.insert(condenseTable, {"techreborn:tin_nugget", "3x3", "techreborn:tin_ingot", 64})
table.insert(condenseTable, {"techreborn:tin_ingot", "3x3", "techreborn:tin_storage_block", 64})
table.insert(condenseTable, {"techreborn:nickel_nugget", "3x3", "techreborn:nickel_ingot", 64})
table.insert(condenseTable, {"techreborn:nickel_ingot", "3x3", "techreborn:nickel_storage_block", 64})
table.insert(condenseTable, {"techreborn:silver_nugget", "3x3", "techreborn:silver_ingot", 64})
table.insert(condenseTable, {"techreborn:silver_ingot", "3x3", "techreborn:silver_storage_block", 64})
table.insert(condenseTable, {"techreborn:lead_nugget", "3x3", "techreborn:lead_ingot", 64})
table.insert(condenseTable, {"techreborn:lead_ingot", "3x3", "techreborn:lead_storage_block", 64})
table.insert(condenseTable, {"techreborn:platinum_nugget", "3x3", "techreborn:platinum_ingot", 64})
table.insert(condenseTable, {"techreborn:platinum_ingot", "3x3", "techreborn:platinum_storage_block", 64})
table.insert(condenseTable, {"techreborn:aluminum_nugget", "3x3", "techreborn:aluminum_ingot", 64})
table.insert(condenseTable, {"techreborn:aluminum_ingot", "3x3", "techreborn:aluminum_storage_block", 64})
table.insert(condenseTable, {"techreborn:chrome_nugget", "3x3", "techreborn:chrome_ingot", 64})
table.insert(condenseTable, {"techreborn:chrome_ingot", "3x3", "techreborn:chrome_storage_block", 64})
table.insert(condenseTable, {"techreborn:iridium_nugget", "3x3", "techreborn:iridium_ingot", 64})
table.insert(condenseTable, {"techreborn:iridium_ingot", "3x3", "techreborn:iridium_storage_block", 64})
table.insert(condenseTable, {"techreborn:titanium_nugget", "3x3", "techreborn:titanium_ingot", 64})
table.insert(condenseTable, {"techreborn:titanium_ingot", "3x3", "techreborn:titanium_storage_block", 64})
table.insert(condenseTable, {"techreborn:tungsten_nugget", "3x3", "techreborn:tungsten_ingot", 64})
table.insert(condenseTable, {"techreborn:tungsten_ingot", "3x3", "techreborn:tungsten_storage_block", 64})

return{
condenseTable = condenseTable
}