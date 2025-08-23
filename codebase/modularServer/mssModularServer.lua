--Imports
local configLinker = require("")
local config = require("configFiles.config")
local mssU = require(config.commonCodeDisk..".mssUtils")
local storeList = require("configFiles.storageList")
local bussin = require("configFiles.bussin")
--Constants
local batchSize = config.batchSize

local self = peripheral.find("modem").getNameLocal()

local genInvs = storeList.genInvs

local allInvs = genInvs

local manifestFile = config.manifestFile

local busWorkFile = config.busWorkFile

local importBuffer = config.importBuffer
local clientExportBuffer = config.clientExportBuffer

local requestsDir = config.requestsDir

local modemSide = config.modemSide

rednet.open(modemSide)