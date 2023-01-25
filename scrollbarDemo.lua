-- Scrollbar component demo

local maxX, maxY = term.getSize();
local x, y = 4, 4;
local width, height = 24, 13

-- local x, y = 1, 1;
-- local width, height = maxX, maxY;


local ParentWindow = window.create(term.current(),x,y,width,height, true);
term.clear()
ParentWindow.setBackgroundColor(colors.lime)
ParentWindow.clear()
local ParentMaxX, ParentMaxY = ParentWindow.getSize();

local Jello = loadfile("Jello.lua")();
local Scrollbar = Jello.Components.Scrollbar(ParentWindow);


local function drawContent(drawChar)
	Scrollbar.Content.Window.setBackgroundColor(colors.lightBlue);
	Scrollbar.Content.Window.clear();
	local i=0;
	Scrollbar.Content.Window.setCursorPos(1,1)
	local mX, mY = Scrollbar.Content.Window.getSize();
	while i<mY do
		for k in pairs(colors) do
			if type(colors[k]) == "number" then
				Scrollbar.Content.Window.setBackgroundColor(colors[k])
				Scrollbar.Content.Window.setTextColor((colors[k] == colors.white or colors[k] == colors.pink) and colors.black or colors.white)
				local leftText = "< line #" .. i .. " ";
				if (i < 256) and (drawChar) then
					leftText = "< char " .. i .. ": \""..string.char(i).."\" ";
				end
				Scrollbar.Content.Window.write(leftText);
				for iW=2, mX-(#leftText) do
					Scrollbar.Content.Window.write("-");
				end
				Scrollbar.Content.Window.write(">");
				i=i+1;
				Scrollbar.Content.Window.setCursorPos(1,i);
			end
		end
		if (mY>100) then
			term.setCursorPos(1,1)
			term.setBackgroundColor(colors.black)
			term.setTextColor(colors.yellow)
			term.write("drawing line: "..i);
		end
		sleep(0)
	end

	if (mY>100) then
		term.setCursorPos(1,1)
		term.clearLine();
		term.setTextColor(colors.lime)
		term.write("Done!");
		sleep(0.5);
		term.setCursorPos(1,1);
		term.clearLine();
	end
end

local function VerticalTest()
	Scrollbar.SetContentWindow(window.create(ParentWindow, 1, 1, ParentMaxX-1, 25, true))

	drawContent()

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

	drawContent()

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
	
	drawContent();

	sleep(.25)
	for i = 1, 25 do
		Scrollbar.VerticalScrollbar.Scroll(1);
		Scrollbar.HorizontalScrollbar.Scroll(1);
		sleep(.01)
	end
	for i = 1, 25 do
		Scrollbar.VerticalScrollbar.Scroll(-1);
		Scrollbar.HorizontalScrollbar.Scroll(-1);
		sleep(.01)
	end

	for i = 1, 25 do
		Scrollbar.VerticalScrollbar.Scroll(1);
		sleep(.025)
	end
	for i = 1, 25 do
		Scrollbar.HorizontalScrollbar.Scroll(1);
		sleep(.025)
	end
	for i = 1, 25 do
		Scrollbar.VerticalScrollbar.Scroll(-1);
		sleep(.025)
	end
	for i = 1, 25 do
		Scrollbar.HorizontalScrollbar.Scroll(-1);
		sleep(.025)
	end

	sleep(1)
end

local function noScrollTest()
	Scrollbar.SetContentWindow()
	
	drawContent()

	sleep(.25)
	for i = 1, 5 do
		Scrollbar.VerticalScrollbar.Scroll(1);
		Scrollbar.HorizontalScrollbar.Scroll(1);
		sleep(.05)
	end
	for i = 1, 5 do
		Scrollbar.VerticalScrollbar.Scroll(-1);
		Scrollbar.HorizontalScrollbar.Scroll(-1);
		sleep(.05)
	end
end


-- Test customization
local function customize()
	Scrollbar.HorizontalScrollbar.Design.TrackBackground = colors.lightBlue;
	Scrollbar.HorizontalScrollbar.Design.TrackForeground = colors.black;
	Scrollbar.HorizontalScrollbar.Design.TrackText = string.char(140);

	Scrollbar.HorizontalScrollbar.Design.KnobBackground = colors.black;
	Scrollbar.HorizontalScrollbar.Design.KnobForeground = colors.lightGray;
	Scrollbar.HorizontalScrollbar.Design.KnobText = "-";

	Scrollbar.HorizontalScrollbar.Design.ArrowsBackground = colors.green;
	Scrollbar.HorizontalScrollbar.Design.TrackForeground = colors.red;
	Scrollbar.HorizontalScrollbar.Design.LeftArrow = "<";
	Scrollbar.HorizontalScrollbar.Design.RightArrow = ">";


	-- Below is a horrible design!
	Scrollbar.VerticalScrollbar.Design.TrackBackground = colors.magenta;
	Scrollbar.VerticalScrollbar.Design.TrackForeground = colors.lightGray;
	Scrollbar.VerticalScrollbar.Design.TrackText = "#";

	Scrollbar.VerticalScrollbar.Design.KnobBackground = colors.white;
	Scrollbar.VerticalScrollbar.Design.KnobForeground = colors.black;
	Scrollbar.VerticalScrollbar.Design.KnobText = ":";

	Scrollbar.VerticalScrollbar.Design.ArrowsBackground = colors.purple;
	Scrollbar.VerticalScrollbar.Design.TrackForeground = colors.yellow;
	Scrollbar.VerticalScrollbar.Design.UpArrow = string.char(24);
	Scrollbar.VerticalScrollbar.Design.DownArrow = string.char(25);

	Scrollbar.HorizontalScrollbar.PosY = Scrollbar.HorizontalScrollbar.PosY-1;
	Scrollbar.HorizontalScrollbar.Height = 2;

	Scrollbar.VerticalScrollbar.PosX = Scrollbar.VerticalScrollbar.PosX-1;
	Scrollbar.VerticalScrollbar.Width = 2;

	Scrollbar.Redraw();
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

local function handleEvents()
	-- Vertical only
	-- Scrollbar.SetContentWindow(window.create(ParentWindow, 1, 1, ParentMaxX-1, 25, true))

	-- Horizontal only
	-- Scrollbar.SetContentWindow(window.create(ParentWindow, 1, 1, 35, ParentMaxY-1, true))

	-- Both
	Scrollbar.SetContentWindow(window.create(ParentWindow, 1, 1, 100, 500, true))
	-- Scrollbar.SetContentWindow(window.create(ParentWindow, 1, 1, 1000, 1000, true))
	
	drawContent(true);

	-- customize()

	while true do
		event = {coroutine.yield()};
		if (event[1] == "terminate") then
			error("terminate");
		else
			Scrollbar.HandleEvent(event);
		end
	end
end


local function checkAll()
	noScrollTest();
	VerticalTest();
	HorizontalTest();
	ComboTest();
	handleEvents();
	customize();
	ComboTest();
end

noScrollTest();
VerticalTest();
HorizontalTest();
ComboTest();
handleEvents();

-- customize();
-- noScrollTest();
-- VerticalTest();
-- HorizontalTest();
-- ComboTest();
-- handleEvents();

-- checkAll();

term.setCursorPos(1,19)
