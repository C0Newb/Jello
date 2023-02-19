-- Scrollbar component demo

local maxX, maxY = term.getSize();
local x, y = 2, 2;
local width, height = maxX-2, maxY-2;
-- local x, y = 4, 4;
-- local width, height = 24, 13
local ParentWindow = window.create(term.current(),x,y,width,height, true);
local ParentMaxX, ParentMaxY = ParentWindow.getSize();
term.setBackgroundColor(colors.pink)
term.clear()

local Jello = loadfile("Jello.lua")();
local Scrollbar = Jello.Components.Scrollbar(ParentWindow);

Scrollbar.AbsorbOutOfBoundsMouseEvents = true; -- This is because we use HandleEvent to pre-process events, if it's not blocked then we pass it to the shell

Scrollbar.SetContentWindow(window.create(ParentWindow, 1, 1, width+5, 150, true));



term.setCursorPos(4,4);
local og = term.current();
term.redirect(Scrollbar.Content.Window);
-- local programCoroutine = coroutine.create(function() while true do print(coroutine.yield()) end end);

local environment = {
	["_G"] = _G,
	["require"] = require,
	["shell"] = shell,
	["package"] = package,
	["Scrollbar"] = Scrollbar,
}
local programCoroutine = coroutine.create(function() os.run(environment, "/demos/scrollbarDemo.lua") end);
-- local programCoroutine = coroutine.create(function() os.run(environment, "/rom/programs/lua.lua") end);
-- local programCoroutine = coroutine.create(function() os.run(environment, "/rom/programs/shell.lua") end);

while true do
	event = {coroutine.yield()};
	if (event[1] == "terminate") then
		error("terminate");
	elseif (event[1] == "key" and event[2] == 281) then
		Jello.ScrollLock = not Jello.ScrollLock;

	elseif not (event[1] == "key_up" and event[2] == 281) then
		local blocked, corrected = Scrollbar.HandleEvent(event);
		-- Blocked is true if the scrollbar handled it, otherwise false and corrected is the event (with the mouse coordinates relative to the content window)
		if not blocked then
			term.redirect(Scrollbar.Content.Window);
			local okay, _ = coroutine.resume(programCoroutine, table.unpack(corrected, 1, corrected.n));
			if (coroutine.status(programCoroutine) == "dead") then
				break;
			end
			term.redirect(og);
			if not okay then
				error("Program error: " .. _);
				sleep(10)
				os.pullEventRaw("key")
			end
		end
	end
end


term.redirect(og);
term.setBackgroundColor(colors.black);
term.setTextColor(colors.white);
term.clear();
term.setCursorPos(1,1);