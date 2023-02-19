--[[

	Jello scheduler


	Developed with love by @Watsuprico
]]

local args = {...}
if (args[1] == nil) then
	error("Parameter #1, JelloAPI, expected type table (Jello) got nil.");
	return;
end
local Jello = args[1];


return function(...)
	local args = {...};
	local Scheduler = {};

	Scheduler.Threads = {}; -- Threads
	Scheduler.GlobalEventQueue = {}; -- If events are globally queue, they live here



	Scheduler.QueueEventsGlobally = true; -- Whether events queues are stored in the thread data or globally. This will speed things up significantly
	Scheduler.QueueSizeLimit = 25; -- Queue will be pushed to threads once growing to this size. (Once QueueSizeLimit number of events have been received, we push all queued events to the threads)
	Scheduler.QueueEvents = false; -- Disable, having this enabled adds overhead and slows it down. If disabled, two things above mean nothing.
	Scheduler.ExitOnNoThreads = true; -- Exits the main loop when all threads have stopped.
	Scheduler.NoThreadsHandler = nil; -- Function that is called when all threads close. This Scheduler object is passed as the first (and only) parameter. If you return true, the scheduler exits
	Scheduler.ExitOnEvent = false; -- Allows the scheduler to stop upon receiving a special event (Scheduler.ExitEvent)
	Scheduler.ExitEvent = "terminate"; -- If Scheduler.ExitOnEvent is true, this is the event that needs to be queued for the Scheduler to exit. When captured, scheduler returns "jello::scheduler::exitevent",Scheduler.ExitEvent



	-- Process provided arguments, must be in table format with each key representing a scheduler property
	if (type(args[1]) == "table") then
		local opt = args[1];
		if (type(opt["QueueEventsGlobally"]) == "boolean") then
			Scheduler.QueueEventsGlobally = opt["QueueEventsGlobally"];
		end

		if (type(opt["QueueEvents"]) == "boolean") then
			Scheduler.QueueEvents = opt["QueueEvents"];
		end
		if (type(opt["ExitOnNoThreads"]) == "boolean") then
			Scheduler.ExitOnNoThreads = opt["ExitOnNoThreads"];
		end
		if (type(opt["ExitOnEvent"]) == "boolean") then
			Scheduler.ExitOnEvent = opt["ExitOnEvent"];
		end

		if (type(opt["ExitEvent"]) == "string") then
			Scheduler.ExitEvent = opt["ExitEvent"];
		end

		if (type(opt["NoThreadsHandler"]) == "function") then
			Scheduler.NoThreadsHandler = opt["NoThreadsHandler"];
		end

		if (type(opt["QueueSizeLimit"]) == "number") then
			Scheduler.QueueSizeLimit = opt["QueueSizeLimit"];
		end
	end



	--[[

		Pushes an event to a thread given the threadId. Note, this does not check if the thread is dead before hand, please check that.

		Advance, do not call manually unless you're implementing your own looper.

		@tparam number Thread id to push the event to
		@tparam table Packed event (table, we use table.unpack to pass the event through)
	]]
	Scheduler.PushEventToThreadId = function(threadId, event)
		local thread = Scheduler.Threads[threadId];
		if (thread.Filter == nil or thread.Filter == event[1] or thread.Filter == "terminate") then
			local okay, coroutineYieldedData = coroutine.resume(thread.Coroutine, table.unpack(event, 1, event.n));
			if not okay then
				thread.status = "dead";
				if (type(thread.EventHandler) == "function") then
					thread.EventHandler("jello::thread::error", thread, table.unpack(coroutineYieldedData));
				end
			else
				thread.Filter = coroutineYieldedData;
			end
		end
	end

	--[[

		Push and events in the event queue to the thread's coroutine.

		Advance, do not call manually unless you're implementing your own looper.

		@tparam[opt=nil] table The event (packed) to be passed in (only works if Scheduler.QueueEvents is false)
	]]
	Scheduler.PushQueuedEventsToThreads = function(event)
		for tId, thread in pairs(Scheduler.Threads) do
			if thread.Status ~= "dead" then -- Found to be marginally quicker than calling coroutine.status() .... ok then
				if Scheduler.QueueEvents and event == nil then
					if Scheduler.QueueEventsGlobally then
						for i = 1, #Scheduler.GlobalEventQueue do
							Scheduler.PushEventToThreadId(tId, Scheduler.GlobalEventQueue[i]);
						end
					else
						for i = 1, #thread.EventQueue do
							Scheduler.PushEventToThreadId(tId, thread.EventQueue[i]);
						end
						thread.EventQueue = {};
					end
				elseif event ~= nil then
					Scheduler.PushEventToThreadId(tId, event);
				end
			else
				if (type(thread.EventHandler) == "function") then
					thread.ErrorHandler("jello::thread::dead", thread, table.unpack(coroutineYieldedData));
				end
				Scheduler.Threads[tId] = nil;
			end

			thread.Status = coroutine.status(thread.Coroutine);
		end

		-- Clear queue
		if Scheduler.QueueEventsGlobally then
			Scheduler.GlobalEventQueue = {}
		end
	end


	--[[

		Adds an event to the queue to be pushed to threads later by the scheduler.

		@tparam string|number Event, similar to what you would pass in os.queueEvent()

	]]
	Scheduler.QueueEvent = function(...)
		local event = {...}
		if Scheduler.QueueEvents then
			if Scheduler.QueueEventsGlobally then
				Scheduler.GlobalEventQueue[#Scheduler.GlobalEventQueue+1] = event;
			else
				for tId, thread in pairs(Scheduler.Threads) do
					if (thread.Status == "suspended") then
						thread.EventQueue[#thread.EventQueue+1] = event;
					end
				end
			end
		else
			Scheduler.PushQueuedEventsToThreads(event);
		end
	end

	local tS = os.clock()
	--[[
		Runs the event handler, captures coroutine.yield() and pushes those events to all threads in this.Threads

		To kick things off, we queue "jello::scheduler::run". This allows the coroutine.yield() to grab something and start each thread already added.
		This does not return, unless Scheduler.ExitOnEvent is true and Scheduler.ExitEvent and captured OR Scheduler.ExitOnNoThreads is true and all threads die

		@treturn string Exit reason
	]]
	Scheduler.Run = function()
		Scheduler.CurrentQueueSize=Scheduler.QueueSizeLimit;
		local event;
		os.queueEvent("jello::scheduler::run");
		while true do
			event = {coroutine.yield()};
			if (event[1] == Scheduler.ExitEvent and Scheduler.ExitOnEvent == true) then
				return "jello::scheduler::exitevent", event[1];
			else
				Scheduler.QueueEvent(table.unpack(event));
				if Scheduler.QueueEvents and Scheduler.CurrentQueueSize >= Scheduler.QueueSizeLimit then
					Scheduler.PushQueuedEventsToThreads();
					Scheduler.CurrentQueueSize = 0;
				end

				if #Scheduler.Threads <= 0 then
					if type(Scheduler.NoThreadsHandler) == "function" then
						if Scheduler.NoThreadsHandler(Scheduler) == true then
							return "jello::scheduler::nothreads";
						end
					elseif Scheduler.ExitOnNoThreads then
						return "jello::scheduler::nothreads";
					end
				end
			end

			Scheduler.CurrentQueueSize = Scheduler.CurrentQueueSize + 1;
		end
	end

	--[[

		Creates a new jello::scheduler::thread object

		@tparam thread Coroutine to run in this thread
		@tparam[opt=nil] function Event handler function that receives error codes or other thread related events (jello::thread::dead, jello::thread::killed, jello::thread::error).
		@treturn jello::scheduler::thread Thread that can then be added via RunThread()
	]]
	Scheduler.NewThread = function(coroutineObj, eventHandler)
		if type(coroutineObj) ~= "thread" then
			error("Parameter #1, coroutineObj, expected type 'thread' got '" .. type(coroutineObj) .. "'");
		end
		if type(eventHandler) ~= "function" and eventHandler ~= nil then
			error("Parameter #2, eventHandler, expected type 'function' got '" .. type(eventHandler) .. "'");
		end

		return {
			["Status"] = "suspended", -- coroutine.status(-) cache (slightly quicker)
			["Coroutine"] = coroutineObj,
			["EventQueue"] = {}, -- Events that will be pushed to the coroutine next resume
			["Filter"] = nil, -- Data passed by the coroutine when it yielded
			["EventHandler"] = eventHandler, -- Event handler (thread_died, thread_killed, thread_error)
		};
	end

	--[[

		Adds a jello::scheduler::thread to the this.Threads table, it'll be picked up in the next cycle.

		@tparam jello::scheduler::thread Thread to add to the list of Thread running
		@treturn number Thread id
	]]
	Scheduler.RunThread = function(thread)
		if (type(thread.Coroutine) ~= "thread") then
			error("thread.Coroutine expected type 'thread' got type " .. type(thread.Coroutine));
		end
		if (type(thread.EventHandler) ~= "function" and thread.EventHandler ~= nil) then
			error("thread.EventHandler expected type 'thread' got type " .. type(thread.Coroutine));
		end
		if (type(thread.EventQueue) ~= "table" or (Scheduler.QueueEvents == false or Scheduler.QueueEventsGlobally)) then
			-- If EventQueue not a table, set as a empty table
			-- If this will not be used, set as empty
			thread.EventQueue = {};
		end

		thread.Status = coroutine.status(thread.Coroutine);

		local threadIndex;
		for i = 1, #Scheduler.Threads+1 do
			if Scheduler.Threads[i] == nil then
				threadIndex = i;
				break;
			end
		end
		Scheduler.Threads[threadIndex] = thread;
		return threadIndex;
	end

	--[[

		Creates a new coroutine, new jello::scheduler::thread, and calls Scheduler.RunThread() to run said new thread.
		You pass the function you wish to run in this thread as the first parameter, any additional parameters are passed to the function you passed in.

		@tparam function Function that will run in the thread
		@tparam any Arguments to pass to your function
		@treturn[1] jello::scheduler::thread

	]]
	Scheduler.RunFunction = function(func, ...)
		local paramters = {...};
		if type(func) ~= "function" then
			error("Parameter #1, func, expected type 'function' got '" .. type(eventHandler) .. "'");
		end
		
		local thread = Scheduler.NewThread( coroutine.create(function() func(table.unpack(paramters)) end) );
		Scheduler.RunThread(thread);

		return thread;
	end



	return Scheduler;
end