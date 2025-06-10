--Table of items that should be
--auto-condensed by the server program.
--The sub-table structure is as
--follows:
--1. Input encoded name.
--2. Recipe type.
--3. Output encoded name.
--4. Maximum batch craft size.
local condenseTable = {}
table.insert(condenseTable, {"minecraft:redstone", "3x3", "minecraft:redstone_block", 64})

return{
condenseTable = condenseTable
}