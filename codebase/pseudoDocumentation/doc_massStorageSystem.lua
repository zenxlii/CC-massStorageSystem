--[[
~~PURPOSE:~~
This application is designed to take an
arbitrarily-large heterogenous array of
storage inventories, and offer methods
to interact with this array effectively
as if it was just a single humongous
inventory.

Note that the intention of this is NOT
to be hyper-optimised, but rather serve
as a middle-man to then build  many
higher-level functions (such as "take a
specified amount of some item out of
storage and put them into a specified
inventory") in a way that the developer
understands and can work with.

~~MAJOR CHANGE IDEA:~~
Redo the manifest and the item movement
functions so that they don't reserve
individual items in a stack, or stacks
at all, instead just using allocated
totals.

~~TERMINOLOGY:~~
Errand:
A single tick-consuming operation, such
as .pushItems(), .list() or .craft().
The scan errand always takes two ticks,
however, as it does .list() and then
.size().

Task:
An operation consisting of one or more
errands that does a simple, single
thing, such as moving one stack of an
item into another inventory after
checking if there's space, or having
the server turtle do a crafting table
craft with items in storage and then
returning the results to storage.

Job:
A collection of an arbitrary number of
tasks that, when combined, satisfy some
higher-level objective, such as making
iron pickaxes from logs and iron blocks
that are to be sent to a specific
client turtle.

~~GOALS:~~
1. Keep track of a supplied table of
inventories, and store their contents
efficiently in-memory.

2. Have functions that, when supplied
with an encoded item name and an amount
of said item, returns a table with the
locations of exactly as many items as
was requested (does not move items by
itself).

3. Have a function to calculate the
totals of every item in the manifest,
because not updating the totals after
literally every change to system
storage is an optimisation and tasks
like inserting stuff into storage or
sorting things already in storage don't
require checking to see if we have
enough of any particular item
beforehand.

4. Uses a disk drive and floppy disk to
store files which serve as how requests
are sent to the server turtle, in turn
avoiding the need to receive rednet
messages in real-time while also
handling other tasks.

5. Communications that are sent from
the server turtle back to a client are
done with rednet messages as the client
enters a brief input lockout period
after any request is sent to the server
turtle.

6. The cut-down displayable manifest
copy that is accessible to clients is
stored on a floppy disk, and clients
can simply read this file to get a copy
of the manifest.

7. Uses a designated buffer inventory
between items coming into the system
and the system's storage inventories in
order to give the system a chance to
determine where they should go, while
still allowing for quick pulling of
external items into the sorting buffer.

~~FILE DETAILS:~~
>manifestFile
Is a greatly cut-down version of the
manifest that's held in-memory on the
server turtle, and is used to "send"
data to display on the client turtles.

>incomingRequests
Is a queue used for buffering jobs sent
by clients for the server to then
interpret and handle. Gets cleaned out
after the server has read the requests
in.

>busWork
Is a file that's used to store jobs to
be executed autonomously by the server,
such as simple I/O bus work (hence the
name busWork).

~~IMPLEMENTATION DETAILS:~~
>The Manifest
>>The manifest table is formatted as
follows:
>(encoded name)
This is the encoded name of the item
that this entry's data is for.
>>"total"
The in-inventory amount of this item in
the system.
>>"free"
The amount of this item that can be
used for a job made right this instant.
>>"reserved"
The amount of this item that has been
set aside for in-progress jobs.
>>"pending"
The amount of this item that is being
crafted but isn't in the system just
yet. This will redirect incoming items
from being "free" to being "reserved".
>>"displayName"
The display name for this item. Used
for user-facing purposes such as on
client turtles.
>>"maxStack"
The maximum stack size limit for this
item. Useful for speeding up the
process of stacking like items to save
on slots used or to prevent oversending
during I/O operations.
>>"data"
Reserved for where and how much of the
item is in a given inventory and slot.
>>>(integer)
A genInvs index corresponding to the
inventory that has the items in the
storage system.
>>>>(integer)
A slot number that has the relevant
item present. The value stored at this
key's position is the amount of the
item in this particular slot.

>Errand Execution Order
>>This is the order in which errands
are to be executed in.
1. Scan.
2. Push.
3. Craft.
4. Pull.
Each errand type will use a separate
batchedParallel() call as to ensure
that the execution order is consistent.
Only one craft errand can be run per
iteration.

>Task Table Structure
>>Each task in the task table is
structured as follows:
>(integer)
Used as the ID for the task in the task
list, is incremental but realistically
shouldn't run into problems with this.
>>"taskType"
Determines the type of task that this
is. Valid values are: "export",
"import", "craft", "supply", "output",
"get".
>>"target"
(export, import, supply, output, get 
only)
The inventory peripheral name that is
the target of this task.
>>"eName"
The encoded name of the item this task
is to specifically work with. Export,
Get and Output will move this item from
storage into the target. Import uses
this as an optional filter on what to
extract. Craft will produce this item
using the recipe for it in the recipe
table. Supply will keep this item in
stock in the target inventory.
>>"amount"
(export, craft, supply, output, get
only)
The amount of "eName" that this task is
to work with. Export uses this as the
amount to try to move every iteration.
Craft has this as the amount of the
desired item left to craft. Supply uses
this as the minimum amount of the item
to keep in the target inventory. Output
and Get have this as the amount of
items to extract in total.
]]