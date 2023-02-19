--[[

	Scheduler test

]]

local args = {...}
local useParallel = false;
local includeSpam = false;
for i = 1, #args do
	if (args[i] == "parallel") then
		useParallel = true;
	elseif (args[i] == "spam" or args[i] == "usespam") then
		includeSpam = true;
	end
end

local Jello = loadfile("Jello.lua")();
local Scheduler = Jello.CoreComponents.Scheduler();



local function tablecopy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end

-- The function we'll be threading (bounces a ball around)
local function bounceBall(term, colorData, sleepDuration)
	local mX, mY = term.getSize();
	local posX = 0;
	local posY = math.floor(mY/2);

	local oPosX = posX;
	local oPosY = posY;

	local xDirection = 1;
	local yDirection = .5;

	local backgroundColor = colors.black;
	local ballBackgroundColor = colors.white;
	local ballTextColor = colors.lightGray;

	if colorData ~= nil then
		if colorData.BackgroundColor ~= nil then
			backgroundColor = colorData.BackgroundColor;
		end
		if colorData.BallBackgroundColor ~= nil then
			ballBackgroundColor = colorData.BallBackgroundColor;
		end
		if colorData.BallTextColor ~= nil then
			ballTextColor = colorData.BallTextColor;
		end
	end

	term.setBackgroundColor(backgroundColor)
	term.clear()
	term.setCursorPos(1, 1);
	term.setBackgroundColor(colors.lightGray);
	term.clearLine();


	local function printTop(msg, xPos)
		term.setCursorPos(xPos, 1);
		term.setBackgroundColor(colors.lightGray);
		term.setTextColor(colors.white);
		term.clearLine();
		term.write(msg);
		term.setCursorPos(1, 1);
	end

	parallel.waitForAll(function()
		local clear = 0;
		local needToClear = false;
		while true do
			local event = {coroutine.yield()}
			if (event[1] == "key" or event[1] == "char") then
				printTop(event[2], 3);
				term.setBackgroundColor(colors.red);
				term.setTextColor(colors.yellow);
				term.write("K");
				needToClear = true;
				clear = 0;
			elseif (event[1] == "key_up") then
				printTop(event[2], 3);
				term.setBackgroundColor(colors.yellow);
				term.setTextColor(colors.black);
				term.write("U");
				needToClear = true;
				clear = 0;
			elseif (event[1] == "mouse_click") then
				printTop(event[2], 3);
				term.setBackgroundColor(colors.black);
				term.setTextColor(colors.pink);
				term.write("M");
				needToClear = true;
				clear = 0;
			elseif (event[1] == "ABC") then
				printTop(event[2], 3);
				term.setBackgroundColor(colors.white);
				term.setTextColor(colors.black);
				term.write("S");
				needToClear = true;
				clear = 0;
			elseif needToClear then
				if clear>100 then
					printTop("", 1);
					clear = 0;
					needToClear = false;
				else
					clear = clear + 1;
				end
			end

		end
	end, function()
		while true do
			term.setCursorPos(oPosX, oPosY);
			term.setBackgroundColor(backgroundColor)
			term.write(" ")
			term.setCursorPos(posX, posY);
			term.setBackgroundColor(ballBackgroundColor)
			term.setTextColor(ballTextColor);
			term.write(" ");

			local mX, mY = term.getSize();
			oPosX = posX;
			oPosY = posY;
			posX = posX + xDirection;
			posY = posY + yDirection;

			if posX > mX then
				posX = mX;
				xDirection = xDirection * -1;
			elseif posX <= 0 then
				posX = 1;
				xDirection = xDirection * -1;
			end

			if posY > mY then
				posY = mY;
				yDirection = yDirection * -1;
			elseif posY <= 2 then
				posY = 2;
				yDirection = yDirection * -1;
			end

			sleep(sleepDuration or 0);
		end
	end)
end

-- Creates the "windows" (terminal objects, each one will be in its own thread)
local windowA = window.create(term.current(), 1, 1, 10, 6, true);
local windowB = window.create(term.current(), 11, 1, 10, 6, true);
local windowC = window.create(term.current(), 21, 1, 10, 6, true);
local windowD = window.create(term.current(), 31, 1, 10, 6, true);
local windowE = window.create(term.current(), 41, 1, 10, 6, true);
local windowF = window.create(term.current(), 1, 7, 10, 6, true);
local windowG = window.create(term.current(), 11, 7, 10, 6, true);
local windowH = window.create(term.current(), 21, 7, 10, 6, true);
local windowI = window.create(term.current(), 31, 7, 10, 6, true);
local windowJ = window.create(term.current(), 41, 7, 10, 6, true);

local windowAColors = {
	["BackgroundColor"] = colors.lime;
	["BallBackgroundColor"] = colors.white;
	["BallTextColor"] = colors.lightGray;
};
local windowBColors = tablecopy(windowAColors);
windowBColors.BackgroundColor = colors.blue;
local windowCColors = tablecopy(windowAColors);
windowCColors.BackgroundColor = colors.orange;
local windowDColors = tablecopy(windowAColors);
windowDColors.BackgroundColor = colors.pink;
local windowEColors = tablecopy(windowAColors);
windowEColors.BackgroundColor = colors.purple;
local windowFColors = tablecopy(windowAColors);
windowFColors.BackgroundColor = colors.purple;
local windowGColors = tablecopy(windowAColors);
windowGColors.BackgroundColor = colors.pink;
local windowHColors = tablecopy(windowAColors);
windowHColors.BackgroundColor = colors.orange;
local windowIColors = tablecopy(windowAColors);
windowIColors.BackgroundColor = colors.blue;
local windowJColors = tablecopy(windowAColors);


local function spamFunction()
	if (includeSpam == false) then
		return;
	end
	print("Adding spam")
	local i = 1;
	while true do
		if (i/1000) == 1 then
			sleep(0.1);
			i = 0;
		end
		os.queueEvent("ABC", i);
		i=i+1;
	end
end

local function spawnThreads(runScrolldemo)
	if (not runScrolldemo) then
		print("Adding A")
		Scheduler.RunFunction(bounceBall, windowA, windowAColors, 0);
		print("Adding B")
		Scheduler.RunFunction(bounceBall, windowB, windowBColors, 0.15);
		print("Adding C");
		Scheduler.RunFunction(bounceBall, windowC, windowCColors, 0.3);
	else
		Scheduler.RunFunction(dofile, "/scrollbarDemo.lua")
	end
	print("Adding D");
	Scheduler.RunFunction(bounceBall, windowD, windowDColors, 0.15);
	print("Adding E");
	Scheduler.RunFunction(bounceBall, windowE, windowEColors, 0);

	if (not runScrolldemo) then
		print("Adding F")
		Scheduler.RunFunction(bounceBall, windowF, windowFColors, 0);
		print("Adding G")
		Scheduler.RunFunction(bounceBall, windowG, windowGColors, 0.15);
		print("Adding H");
		Scheduler.RunFunction(bounceBall, windowH, windowHColors, 0.3);
	end
	print("Adding I");
	Scheduler.RunFunction(bounceBall, windowI, windowIColors, 0.15);
	print("Adding J");
	Scheduler.RunFunction(bounceBall, windowJ, windowJColors, 0);
end

local function runUsingParallel()
	parallel.waitForAll(function() bounceBall(windowA, windowAColors, 0) end, function() bounceBall(windowB, windowBColors, 0.15) end,
		function() bounceBall(windowC, windowCColors, 0.3) end, function() bounceBall(windowD, windowDColors, 0.15) end,
		function() bounceBall(windowE, windowEColors, 0) end, function() bounceBall(windowF, windowFColors, 0) end,
		function() bounceBall(windowG, windowGColors, 0.15) end, function() bounceBall(windowH, windowHColors, 0.3) end,
		function() bounceBall(windowI, windowIColors, 0.15) end, function() bounceBall(windowJ, windowJColors, 0) end,
		function() spamFunction() end);
end

Scheduler.RunFunction(spamFunction)


Scheduler.NoThreadsHandler = function(scheduler)
	term.setCursorPos(1, 1)
	print("All threads closed!")
	print("Reopen all?")
	while true do
		local maybe = {os.pullEvent()};
		if (maybe[1] == "key" and (maybe[2] == keys.y or maybe[2] == keys.enter)) then
			spawnThreads();
			return false;
		elseif (maybe[1] == "key") then
			return true;
		end
		sleep(0)
	end
end

spawnThreads(true);

term.clear()
if useParallel == true then
	runUsingParallel();
else
	print(Scheduler.Run())
end