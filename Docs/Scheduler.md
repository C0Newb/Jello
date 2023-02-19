# Name
Scheduler allows you to run multiple functions at the same time easily. This has a few advantages to the `parallel` API and working with raw coroutines, such as being able to dynamically add and remove running threads.


Scheduler has some drawbacks, however. One notable on is that this is not "true multitasking" or multi-threading. Normally a scheduler would only allow a thread to run for X amount of time, and then a CPU interrupt would be thrown, causing the scheduler to switch out the running thread and switch in a new thread. CC does not have interrupts, to my knowledge, but does have events. Only issue is that these events are not received until `coroutine.yield()` is called by the currently running coroutine. What this mean is that a thread can run for as long as it wants until it calls `coroutine.yield()` (typically via `sleep()`). No there _is_ a runtime limit built into CC itself, these are the "max time without yield" errors you'll see sometimes. With that said, that can take seconds, so thread execution times are not synchronized between threads and it is up to the individual thread to release control back to the scheduler.



Here's the `/Demos/schedulerDemo.lua`:
![Demo](https://user-images.githubusercontent.com/55852895/219934203-3b764357-a6e9-479e-9d4e-cc63084da076.gif)




To create a new instance of this, use:
```lua
local Jello = loadfile("Jello.lua")();

local Name = Jello.Components.Name(args);
```
`args` is optional and is a table allowing you to quickly set the public properties. An example of what you can pass is as follows:
```lua
{
	["QueueEventsGlobally"] = true,
	["QueueSizeLimit"] = 25,
	["QueueEvents"] = false,
	["ExitOnNoThreads"] = true,
	["NoThreadsHandler"] = nil,
	["ExitOnEvent"] = false,
	["ExitEvent"] = "terminate",
}
```




### Scheduler Thread
Threads are a special "type" (table) with the following properties:
```lua
{
	["Status"] = "suspended", -- coroutine.status(-) cache (slightly quicker)
	["Coroutine"] = coroutineObj, -- Coroutine
	["EventQueue"] = {}, -- Events that will be pushed to the coroutine next resume
	["Filter"] = nil, -- Data passed by the coroutine when it yielded
	["EventHandler"] = eventHandler, -- Event handler, will be called when a thread event occurs (thread_died, thread_killed, thread_error). First parameter is the event (thread::error, thread::killed, thread::died), followed by the thread table (what you're looking at) and lastly the error (second return from calling coroutine.resume(<thread>, <event>)).
}
```



## Properties
_Private properties/methods are only accessible by the component itself. These are stored locally with the component. Public properties/methods are stored in the component's table, which is returned to you when you create a new instance of the component (that is, ComponentName.PropertyName)_\
_All public names are in PascalCase._

### Private
`Jello`: (type: `Jello`) - Parent Jello instance.


### Public
`Threads`: (type `Thread[]`) - Holds all thread data.
```lua
{
	[0] = {
		["Status"] = "suspended", -- coroutine.status(-) cache (slightly quicker)
		["Coroutine"] = coroutineObj, -- Coroutine
		["EventQueue"] = {}, -- Events that will be pushed to the coroutine next resume
		["Filter"] = nil, -- Data passed by the coroutine when it yielded
		["EventHandler"] = eventHandler, -- Event handler, will be called when a thread event occurs (thread_died, thread_killed, thread_error). First parameter is the event (thread::error, thread::killed, thread::died), followed by the thread table (what you're looking at) and lastly the error (second return from calling coroutine.resume(<thread>, <event>)).
	},
}
```



`GlobalEventQueue`: (type `Table, {}`) - If events are globally queue, they live here


`QueueEventsGlobally`: (type `boolean`, default `false`) - Whether events queues are stored in the thread data or globally. This will speed things up significantly


`QueueSizeLimit`: (type `number`, default `25`) - Queue will be pushed to threads once growing to this size. (Once QueueSizeLimit number of events have been received, we push all queued events to the threads)


`QueueEvents`: (type `boolean`, default `false`) - Disable, having this enabled adds overhead and slows it down. If disabled, two things above mean nothing. If enable this will queue up events rather than pushing them to threads once received. This would make it so events are pushed to the threads once `QueueSizeLimit` number of events have been received.


`ExitOnNoThreads`: (type `boolean`, default `true`) - Exits the main loop when all threads have stopped.


`NoThreadsHandler`: (type `function`, default `nil`) - Function that is called when all threads close. This Scheduler object is passed as the first (and only) parameter. If you return true, the scheduler exits


`ExitOnEvent`: (type `boolean`, default `false`) - Allows the scheduler to stop upon receiving a special event (defined in `.ExitEvent`).


`ExitEvent`: (type `string`, default `"terminate"`) -  If `.ExitOnEvent` is true, this is the event that needs to be queued for the Scheduler to exit. When captured, scheduler returns "jello::scheduler::exitevent" on the `Scheduler.Run()`.





## Methods
### Private
_None_


### Public
#### PushEventToThreadId
```lua
local function PushEventToThreadId = function(threadId, event): void
```
Pushes an event to a thread given the threadId. Note, this does not check if the thread is dead before hand, please check that.\
Advance, do not call manually unless you're implementing your own looper.

`threadId`: (type: `number`) - Thread id to push the event to.\
`event`: (type `table`) - Packed event (table, we use table.unpack to pass the event through).




### PushQueuedEventsToThreads
```lua
local function PushQueuedEventsToThreads = function(event): void
```
Push and events in the event queue to the thread's coroutine.\
Advance, do not call manually unless you're implementing your own looper.

`event` (type `table`, default `nil`) - The event (packed) to be passed in (only works if `Scheduler.QueueEvents` is false).




### QueueEvent
```lua
local function QueueEvent = function(...): void
```
Adds an event to the queue to be pushed to threads later by the scheduler.

`...`: (type: `string` or `number`) - Event, similar to what you would pass in `os.queueEvent()`.




### NewThread
```lua
local function NewThread = function(coroutineObj, eventHandler): void
```
Creates a new `jello::scheduler::thread` object. _(See [Scheduler Thread](#Scheduler%20Thread) for more info)._

`coroutineObj`: (type `thread`) - Coroutine to run in this thread.
`eventHandler`: (type `function`, default `nil`) - Event handler function that receives error codes or other thread related events (`jello::thread::dead`, `jello::thread::killed`, `jello::thread::error`).

Returns a `jello::scheduler::thread` thread that can then be added via RunThread().



### RunThread
```lua
local function RunThread = function(thread): void
```
Adds a jello::scheduler::thread to the this.Threads table, it'll be picked up in the next cycle.

`thread`: (type `jello::scheduler::thread`) - Thread to add to the list of Thread running.

Returns a `number` representing the new thread id.



### RunFunction
```lua
local function RunFunction = function(func, ...): void
```
Creates a new coroutine, new `jello::scheduler::thread`, and calls `Scheduler.RunThread()` to run said new thread.\
You pass the function you wish to run in this thread as the first parameter, any additional parameters are passed to the function you passed in.

`func`: (type: `function`) - Function that will run in the thread (as the thread).
`...`: (type: any) - Arguments to pass to your function.

Returns a `jello::scheduler::thread` (the thread has already been added to the threads list).





#### Run
```lua
local function Run = function(): void
```
The main loop! Runs the event handler, captures `coroutine.yield()` and pushes those events to all threads in `Scheduler.Threads`.

You call this to run your threads!

To kick things off, we queue `"jello::scheduler::run"`. This allows the `coroutine.yield()` to grab something and start each thread already added.\
This does not return, unless `Scheduler.ExitOnEvent` is true and `Scheduler.ExitEvent` and captured OR `Scheduler.ExitOnNoThreads` is true and all threads die.

This will return a few strings (all as one returned value):\
(`"jello::scheduler::exitevent`, `Scheduler.ExitEvent`): If `Scheduler.ExitOnEvent` is true and we receive the event set in `Scheduler.ExitEvent`, we exit the looper.

(`"jello::scheduler::nothreads`): Once there are no more threads to run (either they've been removed are have died), this is returned. We call the `Scheduler.NoThreadsHandler(Scheduler)` first, and if it is a valid function and returns `true` then you'll get this `"jello::scheduler::nothreads` return. Otherwise you get nothing (in the case `Scheduler.NoThreadsHandler(Scheduler)` handled things) or if there is no valid no threads handler.