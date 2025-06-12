# CC-massStorageSystem
A personal attempt at creating a Logistics Pipes/Refined Storage/Applied Energistics-like storage system with ComputerCraft.

# Current features include:
>A mouse-driven GUI for the client program.

>A search bar for said client program to make finding the items you want easier.

>A (hopefully) well-optimised server program which makes heavy use of parallel.waitForAll() to minimise the amount of ticks needed to do what it has been assigned to do.

>The ability to automatically combine stacks of the same item and condense items such as ingots into their block forms in the background to optimise for storage space.

>Full on-demand autocrafting capabilities (although only crafting table crafts currently have an implementation that can be used).

# Setup Requirements
1 (or more) Advanced Turtle(-s) as client(-s).\
1 Advanced Crafty Turtle as the server (might be able to get away with a standard Craft Turtle here, but that hasn't been tested).\
2 Disk Drives (one for storing manifestFile, the other for storing client and shared program files).\
2 Floppy Disks (one for each Disk Drive).\
At least 3 chest-like inventories (one is reserved for items pulled from the clients, one is reserved for items being sent to clients, and the rest are for general storage).\
Enough Wired Modems and Networking Cable to connect all of the peripherals to the same wired network.\
A willingness to work with software that has not yet been made easy-to-install and dive into the source code files to make setup changes.\

# Known Limitations
1. This storage system currently does not handle enchanted items, damaged items or potions very well (or items which keep a lot of data within NBT tags in general, such as machines that keep their inventories when picked up).
2. If anything other than the server turtle adds, removes, moves or otherwise alters the states of the general storage inventories while the server turtle is running mssServer.lua, then the in-memory manifest will no longer be representative of the actual states of the inventories and this can be rectified by terminating and running mssServer.lua again.
3. Storage system behaviour when there are very few to no empty slots of general storage remaining is currently unknown.
4. The on-disk manifestFile must be a single file and present on a single Disk Drive, which limits the size of manifestFile to 125KB (by default) if a Floppy Disk is inserted into that Disk Drive, or 1MB (by default) if any Computer is inserted into that Disk Drive, however this limitation should only come up when dealing with over 1200 distinct items (although the first limitation can make this problem come up sooner).

# (Rough and Temporary) Installation Guide
1. Ensure that you have everything mentioned in [Setup Requirements](#setup-requirements) available to you.
2. Place down your general storage inventories somewhere, making sure that exactly one Wired Modem is connected to each inventory (full block Wired Modems can connect to inventories on all of their sides, while the small ones can only connect to whatever block their model is physically touching) and that all of these Wired Modems are connected to one another through either other Wired Modems or Networking Cable.
3. Place down the Advanced Crafty Turtle and the two remaining inventories somewhere, preferably a bit separated from your general storage area and next to each other, as this should help with debugging issues if you have any later down the line, remembering to also connect these peripherals to Wired Modems and to the general storage peripheral network.
4. Also near the Advanced Crafty Turtle (recommended), place down the two Disk Drives and make sure they are hooked up to the wired network, before placing a Floppy Disk in each Disk Drive.
5. (to be continued)
