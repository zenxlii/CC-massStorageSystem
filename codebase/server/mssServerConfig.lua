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
table.insert(condenseTable, {"minecraft:iron_nugget", "3x3", "minecraft:iron_ingot", 64})
table.insert(condenseTable, {"minecraft:iron_ingot", "3x3", "minecraft:iron_block", 64})
table.insert(condenseTable, {"minecraft:gold_nugget", "3x3", "minecraft:gold_ingot", 64})
table.insert(condenseTable, {"minecraft:gold_ingot", "3x3", "minecraft:gold_block", 64})
table.insert(condenseTable, {"create:copper_nugget", "3x3", "minecraft:copper_ingot", 64})
table.insert(condenseTable, {"minecraft:copper_ingot", "3x3", "minecraft:copper_block", 64})

return{
condenseTable = condenseTable
}