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

return{
condenseTable = condenseTable
}