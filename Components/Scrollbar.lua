--[[

	Scrollbar component
	
	You MUST pass a terminal object to be the "parent" window



	Developed with love by @Watsuprico
]]


local paramters = {...}
if (paramters[1] == nil) then
	error("Parameter #1, parentWindow, expected type table (terminal) got nil.");
	return;
end
if (type(paramters[1]) ~= "table") then
	error("Parameter #1, parentWindow, expected type table (terminal) got type " .. type(paramters[1]));
	return;
end
if (type(paramters[1].getSize) ~= "function") then
	error("Parameter #1, parentWindow, expected a terminal object but got a table (not a valid terminal object).");
	return;
end


local ParentMaxX, ParentMaxY = paramters[1].getSize();


local Scrollbar = {
	["ParentWindow"] = paramters[1],
	["Design"] = {
		["TrackBackground"] = colors.lightGray;
		["TrackForeground"] = colors.white;

		["KnobBackground"] = colors.gray;
		["KnobForeground"] = colors.white;
		["KnobText"] = "¦";
		
		["ArrowsBackground"] = colors.white;
		["ArrowsForeground"] = colors.black;
		["UpArrow"] = "", -- ▲ (30)
		["DownArrow"] = "", -- ▼ (31)
		["LeftArrow"] = "", -- ◄ (17)
		["RightArrow"] = "", -- ► (16)

	},
	["Children"] = {},

	["VerticalScrollbar"] = {
		["PosX"] = ParentMaxX,
		["PosY"] = 1,
		["Width"] = 1,
		["Height"] = ParentMaxY,
		["RightAligned"] = true,

		["ScrollPosition"] = 1,
		["PercentVisible"] = 1,
		["KnobHeight"] = ParentMaxY-2,
		["KnobNegativeSpace"] = 0,

		["KnobY"] = 0,
		-- the track size (not covered by the knob) * % scrolled . 100% scrolled means the knobY is the same as the track size without the knob (putting it at the bottom)
		

		["Visible"] = false,
		["FireEvent"] = function() end, -- Event handler
		["Window"] = nil,
	},
	["HorizontalScrollbar"] = {
		["PosX"] = 1,
		["PosY"] = 1,
		["Width"] = ParentMaxX,
		["Height"] = 1,
		["BottomAligned"] = true,

		["ScrollPosition"] = 1,
		["PercentVisible"] = 1,
		["KnobHeight"] = ParentMaxX-2,
		["KnobNegativeSpace"] = 0,

		["KnobX"] = 0,
		-- the track size (not covered by the knob) * % scrolled . 100% scrolled means the knobX is the same as the track size without the knob (putting it at the right)
		

		["Visible"] = false,
		["FireEvent"] = function() end, -- Event handler
		["Window"] = nil,
	},

	["Content"] = {
		["PosX"] = 1,
		["PosY"] = 1,
		["Width"] = ParentMaxX, -- Max width - Vscrollbar width
		["Height"] = ParentMaxY, -- Max height - Hscrollbar width
		["Window"] = nil,
	},

	["ContentContainer"] = { -- This way the content window does not clip our scrollbars
		["PosX"] = 1,
		["PosY"] = 1,
		["Width"] = ParentMaxX, -- Max width - Vscrollbar width
		["Height"] = ParentMaxY, -- Max height - Hscrollbar width
		["Window"] = nil,
	}
};


if Scrollbar.VerticalScrollbar.RightAligned then
	Scrollbar.VerticalScrollbar.PosX = ParentMaxX;
end
Scrollbar.VerticalScrollbar.Window = window.create(Scrollbar.ParentWindow,
	Scrollbar.VerticalScrollbar.PosX,
	Scrollbar.VerticalScrollbar.PosY,
	Scrollbar.VerticalScrollbar.Width,
	Scrollbar.VerticalScrollbar.Height,
	Scrollbar.VerticalScrollbar.Visible);


if Scrollbar.HorizontalScrollbar.BottomAligned then
	Scrollbar.HorizontalScrollbar.PosY = ParentMaxY;
end
Scrollbar.HorizontalScrollbar.Window = window.create(Scrollbar.ParentWindow,
	Scrollbar.HorizontalScrollbar.PosX,
	Scrollbar.HorizontalScrollbar.PosY,
	Scrollbar.HorizontalScrollbar.Width,
	Scrollbar.HorizontalScrollbar.Height,
	Scrollbar.HorizontalScrollbar.Visible);


local setParentSize = function()
	ParentMaxX, ParentMaxY = Scrollbar.ParentWindow.getSize();
	if (Scrollbar.VerticalScrollbar.Visible == true) then
		ParentMaxX = ParentMaxX-1;
	end
	if (Scrollbar.HorizontalScrollbar.Visible == true) then
		ParentMaxY = ParentMaxY-1;
	end
end

-- Sets the content that is being scrolled. If empty, we create the window and return it
Scrollbar.SetContentWindow = function(windowObject)
	if (Scrollbar.VerticalScrollbar == nil) then Scrollbar.VerticalScrollbar = {} end
	if (Scrollbar.HorizontalScrollbar == nil) then Scrollbar.HorizontalScrollbar = {} end

	if (windowObject == nil) then
		Scrollbar.VerticalScrollbar.Visible = false;
		Scrollbar.VerticalScrollbar.Window.setVisible(false)
		Scrollbar.HorizontalScrollbar.Visible = false;
		Scrollbar.HorizontalScrollbar.Window.setVisible(false)
		
		ParentMaxX, ParentMaxY = Scrollbar.ParentWindow.getSize();
		Scrollbar.Content = {};
		Scrollbar.Content.PosX = 1;
		Scrollbar.Content.PosY = 1;
		Scrollbar.ContentContainer.Window = window.create(Scrollbar.ParentWindow, 1, 1, ParentMaxX, ParentMaxY, true);
		Scrollbar.Content.Window = window.create(Scrollbar.ContentContainer.Window, 1, 1, ParentMaxX, ParentMaxY, true);
		Scrollbar.Content.MaxX, Scrollbar.Content.MaxY = Scrollbar.Content.Window.getSize();
		return Scrollbar.Content.Window;
	end

	if (type(windowObject) ~= "table") then
		error("Parameter #1, windowObject, expected type table (terminal) got type " .. type(windowObject))
	end
	Scrollbar.Content.MaxX, Scrollbar.Content.MaxY = windowObject.getSize();
	ParentMaxX, ParentMaxY = Scrollbar.ParentWindow.getSize();


	Scrollbar.Content.PosY = 1;
	Scrollbar.Content.PosX = 1;

	-- Vertical
	if (Scrollbar.Content.MaxY > ParentMaxY) then
		Scrollbar.ContentContainer.Width = ParentMaxX-Scrollbar.VerticalScrollbar.Width;
		Scrollbar.VerticalScrollbar.Visible = true;
		Scrollbar.VerticalScrollbar.Window.setVisible(true)
		if (Scrollbar.VerticalScrollbar.RightAligned) then
			Scrollbar.ContentContainer.PosX = 1;
		else
			Scrollbar.ContentContainer.PosX = 2;
		end
	else
		Scrollbar.ContentContainer.Width = ParentMaxX;
		Scrollbar.VerticalScrollbar.Visible = false;
		Scrollbar.VerticalScrollbar.Window.setVisible(false)
	end

	-- Horizontal
	if (Scrollbar.Content.MaxX > ParentMaxX) then
		Scrollbar.ContentContainer.Height = ParentMaxY-Scrollbar.HorizontalScrollbar.Height;
		Scrollbar.HorizontalScrollbar.Visible = true;
		Scrollbar.HorizontalScrollbar.Window.setVisible(true)
		-- Add offset for scrollbar
		if (Scrollbar.HorizontalScrollbar.BottomAligned) then
			Scrollbar.ContentContainer.PosY = 1;
		else
			Scrollbar.ContentContainer.PosY = 2;
		end
	else
		Scrollbar.ContentContainer.Height = ParentMaxY;
		Scrollbar.HorizontalScrollbar.Visible = false;
		Scrollbar.HorizontalScrollbar.Window.setVisible(false)
	end

	Scrollbar.Content.Window = windowObject;
	Scrollbar.ContentContainer.Window = window.create(Scrollbar.ParentWindow, Scrollbar.ContentContainer.PosX, Scrollbar.ContentContainer.PosY, Scrollbar.ContentContainer.Width, Scrollbar.ContentContainer.Height, true);

	Scrollbar.Content.Window.reposition(Scrollbar.Content.PosX, Scrollbar.Content.PosY, Scrollbar.Content.MaxX, Scrollbar.Content.MaxY, Scrollbar.ContentContainer.Window);
	Scrollbar.Content.Window.setVisible(true);
	Scrollbar.ContentContainer.Window.redraw();
	Scrollbar.Content.Window.redraw();
end



-- Vertical
Scrollbar.VerticalScrollbar.RecalulateValues = function()
	ParentMaxX, ParentMaxY = Scrollbar.ParentWindow.getSize();
	cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
	if (cMaxY > ParentMaxY) then
		Scrollbar.VerticalScrollbar.Visible = true;
		Scrollbar.VerticalScrollbar.Window.setVisible(true)
	else
		Scrollbar.VerticalScrollbar.Visible = false;
		Scrollbar.VerticalScrollbar.Window.setVisible(false)
	end

	if (Scrollbar.HorizontalScrollbar.Visible == true) then
		ParentMaxY = ParentMaxY-1;
	end

	Scrollbar.VerticalScrollbar.PercentVisible = ParentMaxY/(cMaxY);
	Scrollbar.VerticalScrollbar.TrackSize = (ParentMaxY-2);
	Scrollbar.VerticalScrollbar.KnobHeight = math.floor( (Scrollbar.VerticalScrollbar.TrackSize*Scrollbar.VerticalScrollbar.PercentVisible) + 0.5 );
	Scrollbar.VerticalScrollbar.KnobNegativeSpace = (Scrollbar.VerticalScrollbar.TrackSize)-Scrollbar.VerticalScrollbar.KnobHeight;
	
	--[[
		get the total number of line NOT visible: (cMaxY-ParentMaxY)
		get the total number of lines on top: currentScrollPos-1
		scroll %: -(numberOfLinesOnTop/numberOfLinesNotVisible)
	]]
	Scrollbar.VerticalScrollbar.PercentScrolled = -(Scrollbar.VerticalScrollbar.ScrollPosition-1)/(cMaxY-ParentMaxY);

	-- How much of the negative space (track without knob) is above us? (how far down are we)
	Scrollbar.VerticalScrollbar.KnobY = 2+math.floor( (Scrollbar.VerticalScrollbar.KnobNegativeSpace)*Scrollbar.VerticalScrollbar.PercentScrolled +.5);


	
end

-- Print
Scrollbar.VerticalScrollbar.Draw = function()
	Scrollbar.VerticalScrollbar.RecalulateValues();
	if (Scrollbar.VerticalScrollbar.Visible == false) then
		return;
	end
	local height = (ParentMaxY-Scrollbar.VerticalScrollbar.PosY)+1;
	Scrollbar.VerticalScrollbar.Window.setBackgroundColor(Scrollbar.Design.TrackBackground);
	Scrollbar.VerticalScrollbar.Window.clear();
	
	-- Up arrow
	Scrollbar.VerticalScrollbar.Window.setCursorPos(1,1);
	Scrollbar.VerticalScrollbar.Window.setBackgroundColor(Scrollbar.Design.ArrowsBackground);
	Scrollbar.VerticalScrollbar.Window.setTextColor(Scrollbar.Design.ArrowsForeground);
	Scrollbar.VerticalScrollbar.Window.write(Scrollbar.Design.UpArrow);

	-- Down Arrow
	Scrollbar.VerticalScrollbar.Window.setCursorPos(1,height);
	Scrollbar.VerticalScrollbar.Window.setBackgroundColor(Scrollbar.Design.ArrowsBackground);
	Scrollbar.VerticalScrollbar.Window.setTextColor(Scrollbar.Design.ArrowsForeground);
	Scrollbar.VerticalScrollbar.Window.write(Scrollbar.Design.DownArrow);

	-- Knob
	-- term.setCursorPos(1,1)
	-- term.setTextColor(colors.white)
	-- term.clearLine()
	-- term.write("h: " .. Scrollbar.VerticalScrollbar.KnobHeight .. " y: " .. Scrollbar.VerticalScrollbar.KnobY .. " %: " .. Scrollbar.VerticalScrollbar.PercentScrolled .. " kNS: " .. Scrollbar.VerticalScrollbar.KnobNegativeSpace .. " %Vis: " .. Scrollbar.VerticalScrollbar.PercentVisible);
	for i = 0, Scrollbar.VerticalScrollbar.KnobHeight-1 do
		Scrollbar.VerticalScrollbar.Window.setCursorPos(1,Scrollbar.VerticalScrollbar.KnobY+i);
		Scrollbar.VerticalScrollbar.Window.setBackgroundColor(Scrollbar.Design.KnobBackground);
		Scrollbar.VerticalScrollbar.Window.setTextColor(Scrollbar.Design.KnobForeground);
		Scrollbar.VerticalScrollbar.Window.write(Scrollbar.Design.KnobText);
	end

end

local function scroll(bar, amount)
	bar.ScrollPosition = bar.ScrollPosition + amount;
	Scrollbar.Content.Window.reposition(Scrollbar.HorizontalScrollbar.ScrollPosition, Scrollbar.VerticalScrollbar.ScrollPosition);
	Scrollbar.Content.Window.redraw();
	for id, component in ipairs(Scrollbar.Children) do
		if (Scrollbar.Children ~= nil) then
			Scrollbar.Children.FireEvent("jello::scrolled", amount);
		end
	end
	Scrollbar.HorizontalScrollbar.Draw();
	Scrollbar.VerticalScrollbar.Draw();
end

Scrollbar.VerticalScrollbar.Scroll = function(amount)
	amount = amount * -1;

	setParentSize();
	local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();

	if ((Scrollbar.VerticalScrollbar.ScrollPosition + amount) < (ParentMaxY-cMaxY+1)) or ((Scrollbar.VerticalScrollbar.ScrollPosition + amount) > 1) then
		return;
	end

	scroll(Scrollbar.VerticalScrollbar, amount);
end



-- Horizontal
Scrollbar.HorizontalScrollbar.RecalulateValues = function()
	ParentMaxX, ParentMaxY = Scrollbar.ParentWindow.getSize();
	local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();

	if (cMaxX > ParentMaxX) then
		Scrollbar.HorizontalScrollbar.Visible = true;
		Scrollbar.HorizontalScrollbar.Window.setVisible(true)
	else
		Scrollbar.HorizontalScrollbar.Visible = false;
		Scrollbar.HorizontalScrollbar.Window.setVisible(false)
	end
	
	if (Scrollbar.VerticalScrollbar.Visible == true) then
		ParentMaxX = ParentMaxX-1;
	end
	
	-- HorizontalScrollbar
	Scrollbar.HorizontalScrollbar.PercentVisible = (ParentMaxX/cMaxX);
	Scrollbar.HorizontalScrollbar.TrackSize = (ParentMaxX-2);
	Scrollbar.HorizontalScrollbar.KnobWidth = math.floor( (Scrollbar.HorizontalScrollbar.TrackSize*Scrollbar.HorizontalScrollbar.PercentVisible) + 0.5 );
	Scrollbar.HorizontalScrollbar.KnobNegativeSpace = (Scrollbar.HorizontalScrollbar.TrackSize)-Scrollbar.HorizontalScrollbar.KnobWidth;
	
	--[[
		get the total number of line NOT visible: (cMaxY-ParentMaxY)
		get the total number of lines on top: currentScrollPos-1
		scroll %: -(numberOfLinesOnTop/numberOfLinesNotVisible)
	]]
	Scrollbar.HorizontalScrollbar.PercentScrolled = -(Scrollbar.HorizontalScrollbar.ScrollPosition-1)/(cMaxX-ParentMaxX);

	-- How much of the negative space (track without knob) is above us? (how far down are we)
	Scrollbar.HorizontalScrollbar.KnobX = 2+math.floor( (Scrollbar.HorizontalScrollbar.KnobNegativeSpace)*Scrollbar.HorizontalScrollbar.PercentScrolled +.5);
end
Scrollbar.HorizontalScrollbar.Draw = function()
	Scrollbar.HorizontalScrollbar.RecalulateValues();
	if (Scrollbar.HorizontalScrollbar.Visible == false) then
		return;
	end

	local width = (ParentMaxX-Scrollbar.HorizontalScrollbar.PosX)+1;
	Scrollbar.HorizontalScrollbar.Window.setBackgroundColor(Scrollbar.Design.TrackBackground);
	Scrollbar.HorizontalScrollbar.Window.clear();
	
	-- Right arrow
	Scrollbar.HorizontalScrollbar.Window.setCursorPos(1,1);
	Scrollbar.HorizontalScrollbar.Window.setBackgroundColor(Scrollbar.Design.ArrowsBackground);
	Scrollbar.HorizontalScrollbar.Window.setTextColor(Scrollbar.Design.ArrowsForeground);
	Scrollbar.HorizontalScrollbar.Window.write(Scrollbar.Design.RightArrow);

	-- Left arrow
	Scrollbar.HorizontalScrollbar.Window.setCursorPos(width,1);
	Scrollbar.HorizontalScrollbar.Window.setBackgroundColor(Scrollbar.Design.ArrowsBackground);
	Scrollbar.HorizontalScrollbar.Window.setTextColor(Scrollbar.Design.ArrowsForeground);
	Scrollbar.HorizontalScrollbar.Window.write(Scrollbar.Design.LeftArrow);

	-- Knob
	-- term.setCursorPos(1,2)
	-- term.setTextColor(colors.lightBlue)
	-- term.clearLine()
	-- term.write("w: " .. Scrollbar.HorizontalScrollbar.KnobWidth .. " x: " .. Scrollbar.HorizontalScrollbar.KnobX .. " %: " .. Scrollbar.HorizontalScrollbar.PercentScrolled .. " kNS: " .. Scrollbar.HorizontalScrollbar.KnobNegativeSpace .. " %Vis: " .. Scrollbar.HorizontalScrollbar.PercentVisible);
	for i = 0, Scrollbar.HorizontalScrollbar.KnobWidth-1 do
		Scrollbar.HorizontalScrollbar.Window.setCursorPos(Scrollbar.HorizontalScrollbar.KnobX+i,1);
		Scrollbar.HorizontalScrollbar.Window.setBackgroundColor(Scrollbar.Design.KnobBackground);
		Scrollbar.HorizontalScrollbar.Window.setTextColor(Scrollbar.Design.KnobForeground);
		Scrollbar.HorizontalScrollbar.Window.write(Scrollbar.Design.KnobText);
	end

end


Scrollbar.HorizontalScrollbar.Scroll = function(amount)
	amount = amount * -1;
	setParentSize();
	local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
	if ((Scrollbar.HorizontalScrollbar.ScrollPosition + amount) < (ParentMaxX-cMaxX+1)) or ((Scrollbar.HorizontalScrollbar.ScrollPosition + amount) > 1) then
		return;
	end

	scroll(Scrollbar.HorizontalScrollbar, amount);
end

return Scrollbar;