-- Scrollbar component demo

local maxX, maxY = term.getSize();
local ParentWindow = window.create(term.current(), 4,4,24,13, true);
term.clear()
ParentWindow.setBackgroundColor(colors.lime)
ParentWindow.clear()
local ParentMaxX, ParentMaxY = ParentWindow.getSize();

local Jello = loadfile("Jello.lua")();
local Scrollbar = Jello.Components.Scrollbar(ParentWindow);

local function VerticalTest()
	Scrollbar.SetContentWindow(window.create(ParentWindow, 1, 1, ParentMaxX-1, 25, true))

	Scrollbar.VerticalScrollbar.Draw();
	Scrollbar.Content.Window.setBackgroundColor(colors.lightBlue);
	Scrollbar.Content.Window.clear();
	local i=0;
	Scrollbar.Content.Window.setCursorPos(1,1)
	while i<ParentMaxY+10 do
		for k in pairs(colors) do
			if type(colors[k]) == "number" then
				Scrollbar.Content.Window.setBackgroundColor(colors[k])
				Scrollbar.Content.Window.clearLine()
				Scrollbar.Content.Window.write(i);
				i=i+1;
				Scrollbar.Content.Window.setCursorPos(1,i);
			end
		end
		sleep(0)
	end

	sleep(.25)
	for i = 1, 25 do
		Scrollbar.VerticalScrollbar.Scroll(1);
		sleep(.05)
	end
	for i = 1, 25 do
		Scrollbar.VerticalScrollbar.Scroll(-1);
		sleep(.05)
	end

	sleep(1)
end

local function HorizontalTest()
	Scrollbar.SetContentWindow(window.create(ParentWindow, 1, 1, 35, ParentMaxY-1, true))

	Scrollbar.HorizontalScrollbar.Draw();
	Scrollbar.Content.Window.setBackgroundColor(colors.lightBlue);
	Scrollbar.Content.Window.clear();
	local i=0;
	Scrollbar.Content.Window.setCursorPos(1,1)
	while i<ParentMaxY+10 do
		for k in pairs(colors) do
			if type(colors[k]) == "number" then
				Scrollbar.Content.Window.setBackgroundColor(colors[k])
				Scrollbar.Content.Window.clearLine()
				Scrollbar.Content.Window.write(i);
				i=i+1;
				Scrollbar.Content.Window.setCursorPos(1,i);
			end
		end
		sleep(0)
	end
	Scrollbar.Content.Window.setCursorPos(1,1)
	Scrollbar.Content.Window.setBackgroundColor(colors.purple)
	Scrollbar.Content.Window.setTextColor(colors.orange)
	Scrollbar.Content.Window.write("A.B.C.D.E.F.G.H.I.J.K.L.M.N.O. END|");

	sleep(.25)
	for i = 1, 25 do
		Scrollbar.HorizontalScrollbar.Scroll(1);
		sleep(.05)
	end
	for i = 1, 25 do
		Scrollbar.HorizontalScrollbar.Scroll(-1);
		sleep(.05)
	end

	sleep(1)
end

local function ComboTest()
	Scrollbar.SetContentWindow(window.create(ParentWindow, 1, 1, 35, 25, true))
	Scrollbar.Content.Window.setBackgroundColor(colors.lightBlue);
	Scrollbar.Content.Window.clear();
	local i=0;
	Scrollbar.Content.Window.setCursorPos(1,1)
	while i<ParentMaxY+10 do
		for k in pairs(colors) do
			if type(colors[k]) == "number" then
				Scrollbar.Content.Window.setBackgroundColor(colors[k])
				Scrollbar.Content.Window.clearLine()
				Scrollbar.Content.Window.write(i);
				i=i+1;
				Scrollbar.Content.Window.setCursorPos(1,i);
			end
		end
		sleep(0)
	end
	Scrollbar.Content.Window.setCursorPos(1,1)
	Scrollbar.Content.Window.setBackgroundColor(colors.purple)
	Scrollbar.Content.Window.setTextColor(colors.orange)
	Scrollbar.Content.Window.write("A.B.C.D.E.F.G.H.I.J.K.L.M.N.O. END|");

	Scrollbar.VerticalScrollbar.Draw();
	Scrollbar.HorizontalScrollbar.Draw();

	sleep(.25)
	for i = 1, 25 do
		Scrollbar.VerticalScrollbar.Scroll(1);
		sleep(.05)
	end
	for i = 1, 25 do
		Scrollbar.HorizontalScrollbar.Scroll(1);
		sleep(.05)
	end
	for i = 1, 25 do
		Scrollbar.VerticalScrollbar.Scroll(-1);
		sleep(.05)
	end
	for i = 1, 25 do
		Scrollbar.HorizontalScrollbar.Scroll(-1);
		sleep(.05)
	end
end

local function noScrollTest()
	Scrollbar.SetContentWindow()
	Scrollbar.Content.Window.setBackgroundColor(colors.lightBlue);
	Scrollbar.Content.Window.clear();
	local i=0;
	Scrollbar.Content.Window.setCursorPos(1,1)
	while i<ParentMaxY+10 do
		for k in pairs(colors) do
			if type(colors[k]) == "number" then
				Scrollbar.Content.Window.setBackgroundColor(colors[k])
				Scrollbar.Content.Window.clearLine()
				Scrollbar.Content.Window.write(i);
				i=i+1;
				Scrollbar.Content.Window.setCursorPos(1,i);
			end
		end
		sleep(0)
	end
	Scrollbar.Content.Window.setCursorPos(1,1)
	Scrollbar.Content.Window.setBackgroundColor(colors.purple)
	Scrollbar.Content.Window.setTextColor(colors.orange)
	Scrollbar.Content.Window.write("A.B.C.D.E.F.G.H.I.J.K.L.M.N.O. END|");

	Scrollbar.VerticalScrollbar.Draw();
	Scrollbar.HorizontalScrollbar.Draw();

	sleep(.25)
	for i = 1, 5 do
		Scrollbar.VerticalScrollbar.Scroll(1);
		sleep(.05)
	end
	for i = 1, 5 do
		Scrollbar.HorizontalScrollbar.Scroll(1);
		sleep(.05)
	end
	for i = 1, 5 do
		Scrollbar.VerticalScrollbar.Scroll(-1);
		sleep(.05)
	end
	for i = 1, 5 do
		Scrollbar.HorizontalScrollbar.Scroll(-1);
		sleep(.05)
	end
	sleep(1)
end



noScrollTest();
VerticalTest();
HorizontalTest();
ComboTest();
term.setCursorPos(1,19)
