local testTable = {}
testTable[1] = {{"minecraft:stone",1},{"minecraft:dirt",5}}
testTable[2] = {{"minecraft:cobblestone",16},{"minecraft:iron_ingot",4}}
testTable[3] = 4
testTable[4] = "craftingTable"
testTable[5] = 2





testSerialise = textutils.serialise(testTable,{compact=true})
print(testSerialise)