--[[

	Scrollbar component
	
	You MUST pass a terminal object to be the "parent" window.
	
	Verified to be working with resolutions up to 1000x1000



	Developed with love by @Watsuprico
]]

local args = {...}
if (args[1] == nil) then
	error("Parameter #1, JelloAPI, expected type table (Jello) got nil.");
	return;
end
local Jello = args[1];


return function(parentWindow)
	if (parentWindow == nil) then
		error("Parameter #1, parentWindow, expected type table (terminal) got nil.");
		return;
	end
	if (type(parentWindow) ~= "table") then
		error("Parameter #1, parentWindow, expected type table (terminal) got type " .. type(parentWindow));
		return;
	end
	if (type(parentWindow.getSize) ~= "function") then
		error("Parameter #1, parentWindow, expected a terminal object but got a table (not a valid terminal object).");
		return;
	end


	local ParentMaxX, ParentMaxY = parentWindow.getSize();


	local Scrollbar = {
		["ComponentInFocus"] = nil, -- Component currently in focus (us (nil) or a child)
		["ParentWindow"] = parentWindow,
		["Design"] = {
			-- Active means being click or activated (interacted with) in another manner
			["TrackBackground"] = colors.lightGray,
			["TrackForeground"] = colors.white,
			["ActiveTrackBackground"] = colors.gray,
			["ActiveTrackForeground"] = colors.lightGray,
			["TrackText"] = "", -- Strips, (127)
			["ActiveTrackText"] = nil,

			["KnobBackground"] = colors.gray,
			["KnobForeground"] = colors.white,
			["ActiveKnobBackground"] = colors.black,
			["ActiveKnobForeground"] = colors.lightGray,
			["KnobText"] = " ",
			["ActiveKnobText"] = " ",

			["ArrowsBackground"] = colors.white,
			["ArrowsForeground"] = colors.black,
			["ActiveArrowsBackground"] = colors.gray,
			["ActiveArrowsForeground"] = colors.white,

			["UpArrow"] = "", -- ▲ (30)
			["DownArrow"] = "", -- ▼ (31)
			["LeftArrow"] = "", -- ◄ (17)
			["RightArrow"] = "", -- ► (16)

			-- This is a special one. Whenever both scrollbars are visible, the spot where they intersect is empty (neither draw there).
			-- Issue is, it may contain the scroll button of one of the scrollbars, so we need to clear it out just in case. We clear it out with this color.
			-- Shared between both horizontal and vertical scrollbars.
			-- This also is not always set, if one of the scrollbars is shrinking, THEN that scrollbar draws to the portion it's about to loose.
			-- There ARE limitations on this, such as growing the vertical scrollbar's width AND growing the horizontal scrollbar's height.
			-- The clearing happens before we adjust the windows (and therefore enlarge the scrollbars).

			["EmptySpaceBackground"] = colors.black,
			["EmptySpaceForeground"] = colors.gray,
			["EmptySpaceText"] = string.char(127), -- 3x2 matrix,
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
			["TrackSize"] = ParentMaxY-2,
			["KnobNegativeSpace"] = 0,

			["KnobY"] = 0,
			-- the track size (not covered by the knob) * % scrolled . 100% scrolled means the knobY is the same as the track size without the knob (putting it at the bottom)
			
			["Design"] = {
				-- If a setting is nil, we pull from Scrollbar.Design dynamically (that is when we draw the elements)
				-- Changing these will override the Scrollbar.Design values
				["TrackBackground"] = nil,
				["TrackForeground"] = nil,
				["ActiveTrackBackground"] = nil,
				["ActiveTrackForeground"] = nil,
				["TrackText"] = nil,
				["ActiveTrackText"] = nil,

				["KnobBackground"] = nil,
				["KnobForeground"] = nil,
				["ActiveKnobBackground"] = nil,
				["ActiveKnobForeground"] = nil,
				["KnobText"] = nil,

				["ArrowsBackground"] = nil,
				["ArrowsForeground"] = nil,
				["ActiveArrowsBackground"] = nil,
				["ActiveArrowsForeground"] = nil,
				["UpArrow"] = nil,
				["DownArrow"] = nil,
			},

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
			["TrackSize"] = ParentMaxX-2,
			["KnobNegativeSpace"] = 0,

			["KnobX"] = 0,
			-- the track size (not covered by the knob) * % scrolled . 100% scrolled means the knobX is the same as the track size without the knob (putting it at the right)
			
			["Design"] = {
				-- If a setting is nil, we pull from Scrollbar.Design dynamically (that is when we draw the elements)
				-- Changing these will override the Scrollbar.Design values
				["TrackBackground"] = nil,
				["TrackForeground"] = nil,
				["ActiveTrackBackground"] = nil,
				["ActiveTrackForeground"] = nil,
				["TrackText"] = nil,
				["ActiveTrackText"] = nil,

				["KnobBackground"] = nil,
				["KnobForeground"] = nil,
				["ActiveKnobBackground"] = nil,
				["ActiveKnobForeground"] = nil,
				["KnobText"] = nil,

				["ArrowsBackground"] = nil,
				["ArrowsForeground"] = nil,
				["ActiveArrowsBackground"] = nil,
				["ActiveArrowsForeground"] = nil,
				["LeftArrow"] = nil,
				["RightArrow"] = nil,
			},

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
		},

		["ScrollOnDrag"] = true, -- Scroll the content as you're dragging the knob (if disabled, content is scrolled when the mouse button is let up (mouse_up))
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
		if (Scrollbar.HorizontalScrollbar.Visible == true) then
			ParentMaxY = ParentMaxY-Scrollbar.HorizontalScrollbar.Height;
		end
		if (Scrollbar.VerticalScrollbar.Visible == true) then
			ParentMaxX = ParentMaxX-Scrollbar.VerticalScrollbar.Width;
		end
	end

	-- Common scroll code
	local function scroll(bar, amount)
		bar.ScrollPosition = bar.ScrollPosition + amount;
		Scrollbar.Content.Window.reposition(Scrollbar.HorizontalScrollbar.ScrollPosition, Scrollbar.VerticalScrollbar.ScrollPosition);
		Scrollbar.Content.Window.redraw();
		for id, component in ipairs(Scrollbar.Children) do
			if (Scrollbar.Children ~= nil) then
				Scrollbar.Children.HandleEvent("jello::scrolled", amount);
			end
		end
		bar.RecalulateValues();
		bar.DrawKnob();
		-- Scrollbar.HorizontalScrollbar.Draw();
		-- Scrollbar.VerticalScrollbar.Draw();
	end



	local function setTrackDesign(vertical)
		local sb = (vertical) and Scrollbar.VerticalScrollbar or Scrollbar.HorizontalScrollbar;

		local trackBackground = sb.Design.TrackBackground or Scrollbar.Design.TrackBackground;
		local trackForeground = sb.Design.TrackForeground or Scrollbar.Design.TrackForeground;
		if (sb.TrackActive) then
			trackBackground = (sb.Design.ActiveTrackBackground or Scrollbar.Design.ActiveTrackBackground) or trackBackground;
			trackForeground = (sb.Design.ActiveTrackForeground or Scrollbar.Design.ActiveTrackForeground) or trackForeground;
		end

		sb.Window.setBackgroundColor(trackBackground);
		sb.Window.setTextColor(trackForeground);
		local trackText = (sb.Design.TrackText or Scrollbar.Design.TrackText);
		if (sb.TrackActive) then
			trackText = (sb.Design.ActiveTrackText or Scrollbar.Design.ActiveTrackText) or trackText;
		end
		if (#trackText < 1) then trackText = " " end -- To set the background
		return trackText:sub(0,1);
	end
	local function setKnobDesign(vertical)
		local sb = (vertical) and Scrollbar.VerticalScrollbar or Scrollbar.HorizontalScrollbar;

		local knobBackground = sb.Design.KnobBackground or Scrollbar.Design.KnobBackground;
		local knobForeground = sb.Design.KnobForeground or Scrollbar.Design.KnobForeground;
		if (sb.KnobActive) then
			knobBackground = (sb.Design.ActiveKnobBackground or Scrollbar.Design.ActiveKnobBackground) or knobBackground;
			knobForeground = (sb.Design.ActiveKnobForeground or Scrollbar.Design.ActiveKnobForeground) or knobForeground;
		end
		sb.Window.setBackgroundColor(knobBackground);
		sb.Window.setTextColor(knobForeground);
		local knobText = (sb.Design.KnobText or Scrollbar.Design.KnobText);
		if (sb.KnobActive) then
			knobText = (sb.Design.ActiveKnobText or Scrollbar.Design.ActiveKnobText) or knobText;
		end
		if (#knobText < 1) then trackText = " " end -- To set the background
		return knobText:sub(0,1);
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

		Scrollbar.VerticalScrollbar.Draw();
		Scrollbar.HorizontalScrollbar.Draw();
	end



	--[[

		Vertical

	]]

	Scrollbar.VerticalScrollbar.RecalulateValues = function()
		ParentMaxX, ParentMaxY = Scrollbar.ParentWindow.getSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		if (cMaxY > ParentMaxY) then
			Scrollbar.VerticalScrollbar.Visible = true;
			Scrollbar.VerticalScrollbar.Window.setVisible(true)
		else
			Scrollbar.VerticalScrollbar.Visible = false;
			Scrollbar.VerticalScrollbar.Window.setVisible(false)
		end

		if (Scrollbar.HorizontalScrollbar.Visible == true) then
			ParentMaxY = ParentMaxY - Scrollbar.HorizontalScrollbar.Height;
		end
		Scrollbar.VerticalScrollbar.Height = ParentMaxY;
		Scrollbar.ContentContainer.Height = ParentMaxY;

		Scrollbar.VerticalScrollbar.PercentVisible = ParentMaxY/(cMaxY);
		Scrollbar.VerticalScrollbar.TrackSize = (Scrollbar.VerticalScrollbar.Height-2);
		Scrollbar.VerticalScrollbar.KnobHeight = math.floor( (Scrollbar.VerticalScrollbar.TrackSize*Scrollbar.VerticalScrollbar.PercentVisible) + 0.5 );
		if (Scrollbar.VerticalScrollbar.KnobHeight < 1) then Scrollbar.VerticalScrollbar.KnobHeight = 1; end -- At least 1px
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


	-- Drawing
	Scrollbar.VerticalScrollbar.DrawUpArrow = function()
		-- Up arrow
		local upArrowBackground = Scrollbar.VerticalScrollbar.Design.ArrowsBackground or Scrollbar.Design.ArrowsBackground;
		local upArrowForeground = Scrollbar.VerticalScrollbar.Design.ArrowsForeground or Scrollbar.Design.ArrowsForeground;
		if (Scrollbar.VerticalScrollbar.UpArrowActive) then
			upArrowBackground = (Scrollbar.VerticalScrollbar.Design.ActiveArrowsBackground or Scrollbar.Design.ActiveArrowsBackground) or upArrowBackground;
			upArrowForeground = (Scrollbar.VerticalScrollbar.Design.ActiveArrowsForeground or Scrollbar.Design.ActiveArrowsForeground) or upArrowForeground;
		end
		Scrollbar.VerticalScrollbar.Window.setBackgroundColor(upArrowBackground);
		Scrollbar.VerticalScrollbar.Window.setTextColor(upArrowForeground);
		local upArrow = (Scrollbar.VerticalScrollbar.Design.UpArrow or Scrollbar.Design.UpArrow):sub(0,1);
		for iW = 1, Scrollbar.VerticalScrollbar.Width do
			Scrollbar.VerticalScrollbar.Window.setCursorPos(iW,1);
			Scrollbar.VerticalScrollbar.Window.write(upArrow);
		end
	end
	Scrollbar.VerticalScrollbar.DrawDownArrow = function()
		-- Down Arrow
		local downArrowBackground = Scrollbar.VerticalScrollbar.Design.ArrowsBackground or Scrollbar.Design.ArrowsBackground;
		local downArrowForeground = Scrollbar.VerticalScrollbar.Design.ArrowsForeground or Scrollbar.Design.ArrowsForeground;
		if (Scrollbar.VerticalScrollbar.DownArrowActive) then
			downArrowBackground = (Scrollbar.VerticalScrollbar.Design.ActiveArrowsBackground or Scrollbar.Design.ActiveArrowsBackground) or downArrowBackground;
			downArrowForeground = (Scrollbar.VerticalScrollbar.Design.ActiveArrowsForeground or Scrollbar.Design.ActiveArrowsForeground) or downArrowForeground;
		end
		Scrollbar.VerticalScrollbar.Window.setBackgroundColor(downArrowBackground);
		Scrollbar.VerticalScrollbar.Window.setTextColor(downArrowForeground);
		local downArrow = (Scrollbar.VerticalScrollbar.Design.DownArrow or Scrollbar.Design.DownArrow):sub(0,1);
		for iW = 1, Scrollbar.VerticalScrollbar.Width do
			Scrollbar.VerticalScrollbar.Window.setCursorPos(iW, (ParentMaxY-Scrollbar.VerticalScrollbar.PosY)+1);
			Scrollbar.VerticalScrollbar.Window.write(downArrow);
		end
	end
	Scrollbar.VerticalScrollbar.DrawArrows = function()
		Scrollbar.VerticalScrollbar.DrawUpArrow();
		Scrollbar.VerticalScrollbar.DrawDownArrow()
	end
	Scrollbar.VerticalScrollbar.DrawTrack = function()
		local trackText = setTrackDesign(true);
		for iH = 1, Scrollbar.VerticalScrollbar.TrackSize do
			Scrollbar.VerticalScrollbar.Window.setCursorPos(1,iH+1);
			Scrollbar.VerticalScrollbar.Window.clearLine();
			for iW = 1, Scrollbar.VerticalScrollbar.Width do -- Allows the text to be printed on all sides if scrollbar width >1
				Scrollbar.VerticalScrollbar.Window.setCursorPos(iW,iH+1);
				Scrollbar.VerticalScrollbar.Window.write(trackText);
			end
		end
	end
	Scrollbar.VerticalScrollbar.DrawKnob = function()
		Scrollbar.VerticalScrollbar.DrawTrack();
		local knobText = setKnobDesign(true);
		for i = 0, Scrollbar.VerticalScrollbar.KnobHeight-1 do
			for iW = 1, Scrollbar.VerticalScrollbar.Width do -- Allows the text to be printed on all sides if scrollbar width >1
				Scrollbar.VerticalScrollbar.Window.setCursorPos(iW,Scrollbar.VerticalScrollbar.KnobY+i);
				Scrollbar.VerticalScrollbar.Window.write(knobText);
			end
		end
	end


	-- Print
	Scrollbar.VerticalScrollbar.Draw = function()
		Scrollbar.VerticalScrollbar.RecalulateValues();
		if (Scrollbar.VerticalScrollbar.Visible == false) then
			return;
		end

		local scrollbarWindowMaxX, scrollbarWindowMaxY = Scrollbar.VerticalScrollbar.Window.getSize();
		if (Scrollbar.VerticalScrollbar.Width > scrollbarWindowMaxX) then -- Will the scrollbar window grow wider?
			-- Resize it to grow wider, then fix the empty space, then shrink the height
			Scrollbar.VerticalScrollbar.Window.reposition(Scrollbar.VerticalScrollbar.PosX, Scrollbar.VerticalScrollbar.PosY, Scrollbar.VerticalScrollbar.Width, scrollbarWindowMaxY);
		end
		if (Scrollbar.VerticalScrollbar.Height < scrollbarWindowMaxY) then -- Will the scrollbar window shrink?
			-- We have to clear out the space were neither scroll bar will draw
			-- While yes we could just do a .clear(), it ended up flashing the window (nasty). This is to get around that.
			Scrollbar.VerticalScrollbar.Window.setBackgroundColor(Scrollbar.Design.EmptySpaceBackground);
			Scrollbar.VerticalScrollbar.Window.setTextColor(Scrollbar.Design.EmptySpaceForeground);
			local emptyText = Scrollbar.Design.EmptySpaceText:sub(0,1)
			for iH = Scrollbar.VerticalScrollbar.Height, scrollbarWindowMaxY do
				for iW = 1, Scrollbar.VerticalScrollbar.Width do -- Allows the text to be printed on all sides if scrollbar width >1
					Scrollbar.VerticalScrollbar.Window.setCursorPos(iW,iH);
					Scrollbar.VerticalScrollbar.Window.write(emptyText);
				end
			end
			Scrollbar.ContentContainer.Window.reposition(Scrollbar.ContentContainer.PosX, Scrollbar.ContentContainer.PosY, Scrollbar.ContentContainer.Width, Scrollbar.ContentContainer.Height);
			Scrollbar.ContentContainer.Window.redraw();
		end
		Scrollbar.VerticalScrollbar.Window.reposition(Scrollbar.VerticalScrollbar.PosX, Scrollbar.VerticalScrollbar.PosY, Scrollbar.VerticalScrollbar.Width, Scrollbar.VerticalScrollbar.Height);

		Scrollbar.VerticalScrollbar.DrawArrows();
		Scrollbar.VerticalScrollbar.DrawKnob();
	end
	Scrollbar.VerticalScrollbar.Redraw = Scrollbar.VerticalScrollbar.Draw;


	Scrollbar.VerticalScrollbar.Scroll = function(amount)
		amount = math.floor(amount);
		amount = amount * -1;
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		if ((Scrollbar.VerticalScrollbar.ScrollPosition + amount) < (ParentMaxY-cMaxY+1)) then
			amount = (ParentMaxY-cMaxY+1) - Scrollbar.VerticalScrollbar.ScrollPosition; -- Scroll to bottom
		elseif ((Scrollbar.VerticalScrollbar.ScrollPosition + amount) > 1) then
			amount = 1-Scrollbar.VerticalScrollbar.ScrollPosition -- Scroll to top
		end
		if (amount == 0) then return; end
		scroll(Scrollbar.VerticalScrollbar, amount);
	end
	-- Scrolls the vertical scrollbar to a % value
	Scrollbar.VerticalScrollbar.ScrollToPercent = function(percent)
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		local gotoScrollPosition = -math.floor(math.floor( ((percent*(cMaxY-ParentMaxY))*100) + .5)/100)+1;
		local scrollDelta = Scrollbar.VerticalScrollbar.ScrollPosition-gotoScrollPosition
		Scrollbar.VerticalScrollbar.Scroll(scrollDelta);
	end
	Scrollbar.VerticalScrollbar.PageUp = function()
		setParentSize();
		Scrollbar.VerticalScrollbar.Scroll((-ParentMaxY-1));
	end
	Scrollbar.VerticalScrollbar.PageDown = function()
		setParentSize();
		Scrollbar.VerticalScrollbar.Scroll(ParentMaxY-1);
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
			ParentMaxX = ParentMaxX-Scrollbar.VerticalScrollbar.Width;
		end
		Scrollbar.HorizontalScrollbar.Width = ParentMaxX;
		Scrollbar.ContentContainer.Width = ParentMaxX;
		
		-- HorizontalScrollbar
		Scrollbar.HorizontalScrollbar.PercentVisible = (ParentMaxX/cMaxX);
		Scrollbar.HorizontalScrollbar.TrackSize = (Scrollbar.HorizontalScrollbar.Width-2);
		Scrollbar.HorizontalScrollbar.KnobWidth = math.floor( (Scrollbar.HorizontalScrollbar.TrackSize*Scrollbar.HorizontalScrollbar.PercentVisible) + 0.5 );
		if (Scrollbar.HorizontalScrollbar.KnobWidth < 1) then Scrollbar.HorizontalScrollbar.KnobWidth = 1; end -- At least 1px
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



	Scrollbar.HorizontalScrollbar.DrawLeftArrow = function()
		-- Left arrow
		local leftArrowBackground = Scrollbar.HorizontalScrollbar.Design.ArrowsBackground or Scrollbar.Design.ArrowsBackground;
		local leftArrowForeground = Scrollbar.HorizontalScrollbar.Design.ArrowsForeground or Scrollbar.Design.ArrowsForeground;
		if (Scrollbar.HorizontalScrollbar.LeftArrowActive) then
			leftArrowBackground = (Scrollbar.HorizontalScrollbar.Design.ActiveArrowsBackground or Scrollbar.Design.ActiveArrowsBackground) or leftArrowBackground;
			leftArrowForeground = (Scrollbar.HorizontalScrollbar.Design.ActiveArrowsForeground or Scrollbar.Design.ActiveArrowsForeground) or leftArrowForeground;
		end
		Scrollbar.HorizontalScrollbar.Window.setBackgroundColor(leftArrowBackground);
		Scrollbar.HorizontalScrollbar.Window.setTextColor(leftArrowForeground);
		local leftArrowText = (Scrollbar.HorizontalScrollbar.Design.LeftArrow or Scrollbar.Design.LeftArrow):sub(0,1);
		for iH = 1, Scrollbar.HorizontalScrollbar.Height do
			Scrollbar.HorizontalScrollbar.Window.setCursorPos(1,iH);
			Scrollbar.HorizontalScrollbar.Window.write(leftArrowText);
		end
	end
	Scrollbar.HorizontalScrollbar.DrawRightArrow = function()
		-- Right arrow
		local rightArrowBackground = Scrollbar.HorizontalScrollbar.Design.ArrowsBackground or Scrollbar.Design.ArrowsBackground;
		local rightArrowForeground = Scrollbar.HorizontalScrollbar.Design.ArrowsForeground or Scrollbar.Design.ArrowsForeground;
		if (Scrollbar.HorizontalScrollbar.RightArrowActive) then
			rightArrowBackground = (Scrollbar.HorizontalScrollbar.Design.ActiveArrowsBackground or Scrollbar.Design.ActiveArrowsBackground) or rightArrowBackground;
			rightArrowForeground = (Scrollbar.HorizontalScrollbar.Design.ActiveArrowsForeground or Scrollbar.Design.ActiveArrowsForeground) or rightArrowForeground;
		end
		Scrollbar.HorizontalScrollbar.Window.setBackgroundColor(rightArrowBackground);
		Scrollbar.HorizontalScrollbar.Window.setTextColor(rightArrowForeground);
		local rightArrowText = (Scrollbar.HorizontalScrollbar.Design.RightArrow or Scrollbar.Design.RightArrow):sub(0,1);
		for iH = 1, Scrollbar.HorizontalScrollbar.Height do
			Scrollbar.HorizontalScrollbar.Window.setCursorPos((ParentMaxX-Scrollbar.HorizontalScrollbar.PosX)+1,iH);
			Scrollbar.HorizontalScrollbar.Window.write(rightArrowText);
		end
	end
	Scrollbar.HorizontalScrollbar.DrawArrows = function()
		Scrollbar.HorizontalScrollbar.DrawLeftArrow()
		Scrollbar.HorizontalScrollbar.DrawRightArrow();
	end
	Scrollbar.HorizontalScrollbar.DrawTrack = function()
		local trackText = setTrackDesign(false);
		for iW = 1, Scrollbar.HorizontalScrollbar.TrackSize do
			for iH = 1, Scrollbar.HorizontalScrollbar.Height do -- Allows the text to be printed on all sides if scrollbar height >1
				Scrollbar.HorizontalScrollbar.Window.setCursorPos(iW+1,iH);
				Scrollbar.HorizontalScrollbar.Window.write(trackText);
			end
		end
	end
	Scrollbar.HorizontalScrollbar.DrawKnob = function()
		Scrollbar.HorizontalScrollbar.DrawTrack();
		local knobText = setKnobDesign(false);
		for i = 0, Scrollbar.HorizontalScrollbar.KnobWidth-1 do
			for iH = 1, Scrollbar.HorizontalScrollbar.Height do -- Allows the text to be printed on all sides if scrollbar height >1
				Scrollbar.HorizontalScrollbar.Window.setCursorPos(Scrollbar.HorizontalScrollbar.KnobX+i,iH);
				Scrollbar.HorizontalScrollbar.Window.write(knobText);
			end
		end
	end

	Scrollbar.HorizontalScrollbar.Draw = function()
		Scrollbar.HorizontalScrollbar.RecalulateValues();
		if (Scrollbar.HorizontalScrollbar.Visible == false) then
			return;
		end

		local scrollbarWindowMaxX, scrollbarWindowMaxY = Scrollbar.HorizontalScrollbar.Window.getSize();
		if (Scrollbar.HorizontalScrollbar.Height > scrollbarWindowMaxY) then -- Will the scrollbar window grow taller?
			-- Resize it to grow wider, then fix the empty space, then shrink the height
			Scrollbar.HorizontalScrollbar.Window.reposition(Scrollbar.HorizontalScrollbar.PosX, Scrollbar.HorizontalScrollbar.PosY, scrollbarWindowMaxX, Scrollbar.HorizontalScrollbar.Height);
		end
		if (Scrollbar.HorizontalScrollbar.Width < scrollbarWindowMaxX) then
			-- We have to clear out the space were neither scroll bar will draw
			Scrollbar.HorizontalScrollbar.Window.setBackgroundColor(Scrollbar.Design.EmptySpaceBackground);
			Scrollbar.HorizontalScrollbar.Window.setTextColor(Scrollbar.Design.EmptySpaceForeground);
			local emptyText = Scrollbar.Design.EmptySpaceText:sub(0,1)
			for iH = 1, Scrollbar.HorizontalScrollbar.Height do
				for iW = Scrollbar.HorizontalScrollbar.Width, scrollbarWindowMaxX do -- Allows the text to be printed on all sides if scrollbar width >1
					Scrollbar.HorizontalScrollbar.Window.setCursorPos(iW,iH);
					Scrollbar.HorizontalScrollbar.Window.write(emptyText);
				end
			end
			Scrollbar.ContentContainer.Window.reposition(Scrollbar.ContentContainer.PosX, Scrollbar.ContentContainer.PosY, Scrollbar.ContentContainer.Width, Scrollbar.ContentContainer.Height);
			Scrollbar.ContentContainer.Window.redraw();
		end
		Scrollbar.HorizontalScrollbar.Window.reposition(Scrollbar.HorizontalScrollbar.PosX, Scrollbar.HorizontalScrollbar.PosY, Scrollbar.HorizontalScrollbar.Width, Scrollbar.HorizontalScrollbar.Height);

		Scrollbar.HorizontalScrollbar.DrawArrows();
		Scrollbar.HorizontalScrollbar.DrawKnob();
	end
	Scrollbar.HorizontalScrollbar.Redraw = Scrollbar.HorizontalScrollbar.Draw;



	Scrollbar.HorizontalScrollbar.Scroll = function(amount)
		amount = math.floor(amount);
		amount = amount * -1;
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		if ((Scrollbar.HorizontalScrollbar.ScrollPosition + amount) < (ParentMaxX-cMaxX+1)) then
			amount = (ParentMaxX-cMaxX+1) - Scrollbar.HorizontalScrollbar.ScrollPosition; -- Scroll all the way to the right
		elseif ((Scrollbar.HorizontalScrollbar.ScrollPosition + amount) > 1) then
			amount = 1-Scrollbar.HorizontalScrollbar.ScrollPosition -- Scroll all the way to left
		end
		if (amount == 0) then return; end

		scroll(Scrollbar.HorizontalScrollbar, amount);
	end
	-- Scrolls the vertical scrollbar to a % value
	Scrollbar.HorizontalScrollbar.ScrollToPercent = function(percent)
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		local gotoScrollPosition = -math.floor(math.floor( ((percent*(cMaxX-ParentMaxX))*100) + .5)/100)+1;
		local scrollDelta = Scrollbar.HorizontalScrollbar.ScrollPosition-gotoScrollPosition

		Scrollbar.HorizontalScrollbar.Scroll(scrollDelta);
	end

	Scrollbar.HorizontalScrollbar.PageLeft = function()
		setParentSize();
		Scrollbar.HorizontalScrollbar.Scroll((-ParentMaxX-1));
	end
	Scrollbar.HorizontalScrollbar.PageRight = function()
		setParentSize();
		Scrollbar.HorizontalScrollbar.Scroll(ParentMaxX-1);
	end



	Scrollbar.Draw = function()
		Scrollbar.VerticalScrollbar.Draw();
		Scrollbar.HorizontalScrollbar.Draw();
	end
	Scrollbar.Redraw = Scrollbar.Draw;


	Scrollbar.PageUp = function()
		Scrollbar.VerticalScrollbar.PageUp();
	end
	Scrollbar.PageDown = function()
		Scrollbar.VerticalScrollbar.PageDown();
	end
	Scrollbar.PageLeft = function()
		Scrollbar.HorizontalScrollbar.PageLeft();
	end
	Scrollbar.PageRight = function()
		Scrollbar.HorizontalScrollbar.PageRight();
	end


	Scrollbar.ScrollUp = function(amount)
		if (type(amount) ~= "number") then amount = -1 end
		if (amount > 0) then amount = amount*-1; end
		Scrollbar.VerticalScrollbar.Scroll(amount)
	end
	Scrollbar.ScrollDown = function(amount)
		if (type(amount) ~= "number") then amount = 1 end
		if (amount < 0) then amount = amount*-1; end
		Scrollbar.VerticalScrollbar.Scroll(amount)
	end
	Scrollbar.ScrollLeft = function(amount)
		if (type(amount) ~= "number") then amount = -1 end
		if (amount > 0) then amount = amount*-1; end
		Scrollbar.HorizontalScrollbar.Scroll(amount)
	end
	Scrollbar.ScrollRight = function(amount)
		if (type(amount) ~= "number") then amount = 1 end
		if (amount < 0) then amount = amount*-1; end
		Scrollbar.HorizontalScrollbar.Scroll(amount)
	end

	-- Negative for up/left
	Scrollbar.Scroll = function(verticalAmount, horizontalAmount)
		Scrollbar.VerticalScrollbar.Scroll(verticalAmount)
		Scrollbar.HorizontalScrollbar.Scroll(horizontalAmount)
	end

	Scrollbar.VerticalScrollbar.GetScrollAmount = function()
		return Scrollbar.VerticalScrollbar.ScrollPosition-1;
	end
	Scrollbar.HorizontalScrollbar.GetScrollAmount = function()
		return Scrollbar.HorizontalScrollbar.ScrollPosition-1;
	end
	Scrollbar.GetScrollAmount = function()
		return Scrollbar.VerticalScrollbar.GetScrollAmount(), Scrollbar.HorizontalScrollbar.GetScrollAmount();
	end




	-- Handler


	local function getCordinates(x, y)
		local xParentOffset, yParentOffset = Scrollbar.ParentWindow.getPosition();
		local pMaxX, pMaxY = Scrollbar.ParentWindow.getSize();

		local cords = {};

		-- Normalize mouse coordinates to us
		cords.mX = x-xParentOffset+1;
		cords.mY = y-yParentOffset+1;

		-- Parent window
		cords.pWX1 = 1; -- far left
		cords.pWY1 = 1; -- top
		cords.pWX2 = cords.pWX1 + pMaxX - 1; -- far right
		cords.pWY2 = cords.pWY1 + pMaxY - 1; -- bottom

		-- Content
		cords.cWX1 = Scrollbar.ContentContainer.PosX; -- far left
		cords.cWY1 = Scrollbar.ContentContainer.PosY; -- top
		cords.cWX2 = Scrollbar.ContentContainer.PosX + Scrollbar.ContentContainer.Width-1; -- far right
		cords.cWY2 = Scrollbar.ContentContainer.PosY + Scrollbar.ContentContainer.Height-1; -- bottom

		-- Vertical scrollbar
		cords.vSbX1 = Scrollbar.VerticalScrollbar.PosX; -- far left
		cords.vSbY1 = Scrollbar.VerticalScrollbar.PosY; -- top
		cords.vSbX2 = cords.vSbX1 + Scrollbar.VerticalScrollbar.Width-1; -- far right
		cords.vSbY2 = cords.vSbY1 + Scrollbar.VerticalScrollbar.Height-1; -- bottom
		cords.vSbK1 = Scrollbar.VerticalScrollbar.KnobY;
		cords.vSbK2 = cords.vSbK1+Scrollbar.VerticalScrollbar.KnobHeight-1;

		-- Horizontal scrollbar
		cords.hSbX1 = Scrollbar.HorizontalScrollbar.PosX; -- far left
		cords.hSbY1 = Scrollbar.HorizontalScrollbar.PosY; -- top
		cords.hSbX2 = cords.hSbX1 + Scrollbar.HorizontalScrollbar.Width-1; -- far right
		cords.hSbY2 = cords.hSbY1 + Scrollbar.HorizontalScrollbar.Height-1; -- bottom
		cords.hSbK1 = Scrollbar.HorizontalScrollbar.KnobX;
		cords.hSbK2 = cords.hSbK1+Scrollbar.HorizontalScrollbar.KnobWidth-1;

		return cords;
	end

	local function coordinatesInsideParentWindow(cords)
		if (type(cords) ~= "table") then return false end
		return (cords.mX >= cords.pWX1 and cords.mX <= cords.pWX2) and (cords.mY >= cords.pWY1 and cords.mY <= cords.pWY2);
	end
	local function coordinatesInsideContentContainer(cords)
		if (type(cords) ~= "table") then return false end
		return (cords.mX >= cords.cWX1 and cords.mX <= cords.cWX2) and (cords.mY >= cords.cWY1 and cords.mY <= cords.cWY2);
	end
	local function coordinatesInsideVerticalScrollbar(cords)
		if (type(cords) ~= "table") then return false end
		return (cords.mX >= cords.vSbX1 and cords.mX <= cords.vSbX2) and (cords.mY >= cords.vSbY1 and cords.mY <= cords.vSbY2);
	end
	local function coordinatesInsideHorizontalScrollbar(cords)
		if (type(cords) ~= "table") then return false end
		return (cords.mX >= cords.hSbX1 and cords.mX <= cords.hSbX2) and (cords.mY >= cords.hSbY1 and cords.mY <= cords.hSbY2);
	end

	--[[

		Handle event is similar to queueEvent, you pass events, such as term_resize or mouse_click, to the scrollbar to handle

		@tparam table The event inside a table (with additional arguments) that you wish the scrollbar to handle
	]]
	Scrollbar.HandleEvent = function(event)
		term.setBackgroundColor(colors.black);
				term.setTextColor(colors.yellow);
		if (type(event) ~= "table") then
			error("Parameter #1, event, expected type table got type " .. type(event));
		end

		setParentSize();

		local eventName = event[1];
		if (eventName == "mouse_up") then
			if (Scrollbar.VerticalScrollbar.KnobActive) then
				Scrollbar.VerticalScrollbar.KnobActive = false;
				-- Scroll the content
				local percent = ((Scrollbar.VerticalScrollbar.KnobY-2)/Scrollbar.VerticalScrollbar.KnobNegativeSpace);
				Scrollbar.VerticalScrollbar.ScrollToPercent(percent);
				Scrollbar.VerticalScrollbar.Draw();
			elseif (Scrollbar.HorizontalScrollbar.KnobActive) then
				Scrollbar.HorizontalScrollbar.KnobActive = false;

				-- Scroll the content
				local percent = ((Scrollbar.HorizontalScrollbar.KnobX-2)/Scrollbar.HorizontalScrollbar.KnobNegativeSpace);
				Scrollbar.HorizontalScrollbar.ScrollToPercent(percent);
				Scrollbar.VerticalScrollbar.Draw();

				Scrollbar.HorizontalScrollbar.Draw();
			elseif (Scrollbar.VerticalScrollbar.UpArrowActive or Scrollbar.VerticalScrollbar.DownArrowActive) then
				Scrollbar.VerticalScrollbar.UpArrowActive = false;
				Scrollbar.VerticalScrollbar.DownArrowActive = false;
				Scrollbar.VerticalScrollbar.DrawArrows();
			elseif (Scrollbar.HorizontalScrollbar.LeftArrowActive or Scrollbar.HorizontalScrollbar.RightArrowActive) then
				Scrollbar.HorizontalScrollbar.LeftArrowActive = false;
				Scrollbar.HorizontalScrollbar.RightArrowActive = false;
				Scrollbar.HorizontalScrollbar.DrawArrows();
			elseif (Scrollbar.VerticalScrollbar.TrackActive) then
				Scrollbar.VerticalScrollbar.TrackActive = false;
				Scrollbar.VerticalScrollbar.DrawKnob();
			elseif (Scrollbar.HorizontalScrollbar.TrackActive) then
				Scrollbar.HorizontalScrollbar.TrackActive = false;
				Scrollbar.HorizontalScrollbar.DrawKnob();
			end

		elseif (eventName == "mouse_scroll") then
			local cords = getCordinates(event[3], event[4]);
			if (coordinatesInsideParentWindow(cords)) then -- Within the Scrollbar parent
				if ((Scrollbar.HorizontalScrollbar.Visible and not Scrollbar.VerticalScrollbar.Visible) or coordinatesInsideHorizontalScrollbar(cords)) then
					-- Scroll horizontally IF cursor over the horizontal scrollbar OR horizontal scrolling is that is available
					Scrollbar.HorizontalScrollbar.Scroll(event[2]);
				elseif (Scrollbar.VerticalScrollbar.Visible) then
					Scrollbar.VerticalScrollbar.Scroll(event[2]);
				end
			end

		elseif (eventName == "mouse_click") and (event[2] == Jello.Config.Mouse.PrimaryButton) then -- Mouse 1 (primary) click
			local cords = getCordinates(event[3], event[4]);
			if (not coordinatesInsideParentWindow(cords)) then return end

			-- Vertical first
			if (Scrollbar.VerticalScrollbar.Visible) then -- Check if click within VerticalScrollbar
				-- term.setCursorPos(1,1);
				-- term.setBackgroundColor(colors.black);
				-- term.setTextColor(colors.yellow);
				-- term.clearLine();
				-- term.write("vSbX1: " .. cords.vSbX1 .. " vSbX2: " .. cords.vSbX2 .. " vSbY1: " .. cords.vSbY1 .. " vSbY2: " .. cords.vSbY2 .. " x: " .. cords.mX .. " y: " .. cords.mY);
				-- term.write("vSbK1: " .. cords.vSbK1 .. " vSbK2: " .. cords.vSbK2 .. " x: " .. cords.mX .. " y: " .. cords.mY);

				if (coordinatesInsideVerticalScrollbar(cords)) then -- Within this scrollbar
					if (cords.mY == cords.vSbY1) then -- Clicked the up arrow
						Scrollbar.VerticalScrollbar.UpArrowActive = true;
						Scrollbar.VerticalScrollbar.DrawUpArrow();
						Scrollbar.VerticalScrollbar.Scroll(-1);
					elseif (cords.mY == cords.vSbY2) then -- Clicked the down arrow
						Scrollbar.VerticalScrollbar.DownArrowActive = true;
						Scrollbar.VerticalScrollbar.DrawDownArrow();
						Scrollbar.VerticalScrollbar.Scroll(1);
					elseif (cords.mY >= cords.vSbK1 and cords.mY <= cords.vSbK2) then
						Scrollbar.VerticalScrollbar.KnobActive = true;
						Scrollbar.VerticalScrollbar.KnobActiveY = cords.vSbK1-cords.mY; -- Top of knob - mouse y
						Scrollbar.VerticalScrollbar.DrawKnob();
					elseif (cords.mY > cords.vSbY1 and cords.mY < cords.vSbK1) then
						-- Page up
						Scrollbar.VerticalScrollbar.TrackActive = true;
						Scrollbar.VerticalScrollbar.DrawKnob();
						Scrollbar.VerticalScrollbar.PageUp();
					elseif (cords.mY > cords.vSbK2 and cords.mY < cords.hSbY2) then
						-- Page down
						Scrollbar.VerticalScrollbar.TrackActive = true;
						Scrollbar.VerticalScrollbar.DrawKnob();
						Scrollbar.VerticalScrollbar.PageDown();
					end
				end
			end


			-- Horizontal
			if (Scrollbar.HorizontalScrollbar.Visible) then -- Check if click within VerticalScrollbar
				if (coordinatesInsideHorizontalScrollbar(cords)) then -- Within this scrollbar
					if (cords.mX == cords.hSbX1) then -- Clicked the left arrow
						Scrollbar.HorizontalScrollbar.LeftArrowActive = true;
						Scrollbar.HorizontalScrollbar.DrawLeftArrow();
						Scrollbar.HorizontalScrollbar.Scroll(-1);
					elseif (cords.mX == cords.hSbX2) then -- Clicked the right arrow
						Scrollbar.HorizontalScrollbar.RightArrowActive = true;
						Scrollbar.HorizontalScrollbar.DrawRightArrow();
						Scrollbar.HorizontalScrollbar.Scroll(1);
					elseif (cords.mX >= cords.hSbK1 and cords.mX <= cords.hSbK2) then
						Scrollbar.HorizontalScrollbar.KnobActive = true;
						Scrollbar.HorizontalScrollbar.KnobActiveX = cords.hSbK1-cords.mX; -- Top of knob - mouse y
						Scrollbar.HorizontalScrollbar.DrawKnob();
					elseif (cords.mX > cords.hSbX1 and cords.mX < cords.hSbK1) then
						-- Page left
						Scrollbar.HorizontalScrollbar.TrackActive = true;
						Scrollbar.HorizontalScrollbar.DrawKnob();
						Scrollbar.HorizontalScrollbar.PageLeft();
					elseif (cords.mX > cords.hSbK2 and cords.mX < cords.hSbX2) then
						-- Page right
						Scrollbar.HorizontalScrollbar.TrackActive = true;
						Scrollbar.HorizontalScrollbar.DrawKnob();
						Scrollbar.HorizontalScrollbar.PageRight();
					end
				end
			end
		elseif (eventName == "mouse_drag") then
			local cords = getCordinates(event[3], event[4]);
			-- if (not coordinatesInsideParentWindow(cords)) then return end

			if (Scrollbar.VerticalScrollbar.KnobActive and (cords.mY >= cords.cWY1 and cords.mY <= cords.cWY2)) then
				local y = cords.mY + Scrollbar.VerticalScrollbar.KnobActiveY;
				if (y < cords.vSbY1+1) then
					y = cords.vSbY1+1;
				elseif (y > (cords.vSbY2)-Scrollbar.VerticalScrollbar.KnobHeight) then
					y = (cords.vSbY2)-Scrollbar.VerticalScrollbar.KnobHeight;
				end
				Scrollbar.VerticalScrollbar.KnobY = y;
				if (Scrollbar.ScrollOnDrag) then
					local percent = ((Scrollbar.VerticalScrollbar.KnobY-2)/Scrollbar.VerticalScrollbar.KnobNegativeSpace);
					Scrollbar.VerticalScrollbar.ScrollToPercent(percent);
				end
				Scrollbar.VerticalScrollbar.DrawKnob();

			elseif (Scrollbar.HorizontalScrollbar.KnobActive and (cords.mX >= cords.cWX1 and cords.mX <= cords.cWX2)) then
				-- Scroll left/right
				local x = cords.mX + Scrollbar.HorizontalScrollbar.KnobActiveX;
				if (x < cords.hSbX1+1) then
					x = cords.hSbX1+1;
				elseif (x > (cords.hSbX2)-Scrollbar.HorizontalScrollbar.KnobWidth) then
					x = (cords.hSbX2)-Scrollbar.HorizontalScrollbar.KnobWidth;
				end
				Scrollbar.HorizontalScrollbar.KnobX = x;
				if (Scrollbar.ScrollOnDrag) then
					local percent = ((Scrollbar.HorizontalScrollbar.KnobX-2)/Scrollbar.HorizontalScrollbar.KnobNegativeSpace);
					Scrollbar.HorizontalScrollbar.ScrollToPercent(percent);
				end
				Scrollbar.HorizontalScrollbar.DrawKnob();
			end

		elseif (eventName == "key") then
			if (Scrollbar.ComponentInFocus == nil) then
				if (event[2] == keys.pageUp) then
					Scrollbar.PageUp();
				elseif (event[2] == keys.pageDown) then
					Scrollbar.PageDown();
				elseif (event[2] == keys.left) then
					Scrollbar.ScrollLeft();
				elseif (event[2] == keys.up) then
					Scrollbar.ScrollUp();
				elseif (event[2] == keys.right) then
					Scrollbar.ScrollRight();
				elseif (event[2] == keys.down) then
					Scrollbar.ScrollDown();
				end
			end
		end
	end


	return Scrollbar;
end