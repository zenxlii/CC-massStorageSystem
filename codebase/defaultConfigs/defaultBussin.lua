local config = require("configFiles.config")
local importBuffer = config.importBuffer
local taskTable = {}

--Add tasks like the task below to
--taskTable.
local clientDumpImportTask = {}
clientDumpImportTask["taskType"] = "import"
clientDumpImportTask["target"] = importBuffer
clientDumpImportTask["specificSlots"] = false
table.insert(taskTable, clientDumpImportTask)
--Add your tasks below here!






return{
taskTable = taskTable
}