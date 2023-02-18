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
		-- If this scrollbar is a child component of a different element, DO NOT set this to true!
		["AbsorbOutOfBoundsMouseEvents"] = false, -- Whether mouse events that occurred outside of the parent window are "handled" or captured by us.
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
			["Window"] = nil,
		},

		["ContentContainer"] = { -- This way the content window does not clip our scrollbars
			["PosX"] = 1,
			["PosY"] = 1,
			["Width"] = ParentMaxX-1, -- Max width - Vscrollbar width
			["Height"] = ParentMaxY-1, -- Max height - Hscrollbar width
			["Window"] = nil,
		},

		["ScrollOnDrag"] = true, -- Scroll the content as you're dragging the knob (if disabled, content is scrolled when the mouse button is let up (mouse_up))
	};

	if Scrollbar.VerticalScrollbar.RightAligned then
		Scrollbar.VerticalScrollbar.PosX = ParentMaxX;
	else
		Scrollbar.VerticalScrollbar.PosX = 1;
	end
	Scrollbar.VerticalScrollbar.Window = window.create(Scrollbar.ParentWindow,
		Scrollbar.VerticalScrollbar.PosX,
		Scrollbar.VerticalScrollbar.PosY,
		Scrollbar.VerticalScrollbar.Width,
		Scrollbar.VerticalScrollbar.Height,
		Scrollbar.VerticalScrollbar.Visible);


	if Scrollbar.HorizontalScrollbar.BottomAligned then
		Scrollbar.HorizontalScrollbar.PosY = ParentMaxY;
	else
		Scrollbar.HorizontalScrollbar.PosY = 1;
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
		return ParentMaxX, ParentMaxY
	end

	-- Common scroll code
	local function scroll(bar, amount)
		bar.ScrollPosition = bar.ScrollPosition + amount;
		Scrollbar.Content.Window.reposition(Scrollbar.HorizontalScrollbar.ScrollPosition, Scrollbar.VerticalScrollbar.ScrollPosition);
		Scrollbar.Content.Window.redraw();
		for id, child in ipairs(Scrollbar.Children) do -- This way nested scrollbars have priority
			if (child ~= nil) then
				if (type(child.HandleEvent) == "function") then
					child.HandleEvent("jello::scroll", amount);
				end
			end
		end
		bar.RecalculateValues();
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

		local function windowScroll(ogScroll)
			local function scroll(amount)
				if amount > 0 and not Scrollbar.IsAtBottom() then
					Scrollbar.Scroll(amount)
					ogScroll(amount)
				end
				return ogScroll(amount)
			end
			return scroll
		end

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

			Scrollbar.Content.Window.scroll = windowScroll(Scrollbar.Content.Window.scroll)
			return Scrollbar.Content.Window;
		end

		if (type(windowObject) ~= "table") then
			error("Parameter #1, windowObject, expected type table (terminal) got type " .. type(windowObject))
		end
		Scrollbar.Content.MaxX, Scrollbar.Content.MaxY = windowObject.getSize();
		ParentMaxX, ParentMaxY = Scrollbar.ParentWindow.getSize();


		Scrollbar.Content.PosY = 1;
		Scrollbar.Content.PosX = 1;

		local xOffset, yOffset = 0, 0;
		if (Scrollbar.Content.MaxY > ParentMaxY) then
			xOffset = -1;
		end
		if (Scrollbar.Content.MaxX > ParentMaxX) then
			yOffset = -1;
		end

		-- Vertical
		if (Scrollbar.Content.MaxY > ParentMaxY+xOffset) then
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
		if (Scrollbar.Content.MaxX > ParentMaxX+xOffset) then
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
		Scrollbar.Content.Window.scroll = windowScroll(Scrollbar.Content.Window.scroll)
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

	-- Recalculates the scrollbar values, such as PosX, PosY, height, width, position, track size, knob size, and more. These are the sizes of elements of the scrollbar and where they are.
	Scrollbar.VerticalScrollbar.RecalculateValues = function()
		ParentMaxX, ParentMaxY = Scrollbar.ParentWindow.getSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();

		local yOffset = (Scrollbar.HorizontalScrollbar.Visible) and Scrollbar.HorizontalScrollbar.Height or 0;
		if (cMaxY > ParentMaxY-yOffset) then
			Scrollbar.VerticalScrollbar.Visible = true;
			Scrollbar.VerticalScrollbar.Window.setVisible(true)
		else
			Scrollbar.VerticalScrollbar.Visible = false;
			Scrollbar.VerticalScrollbar.Window.setVisible(false)
		end

		if (Scrollbar.HorizontalScrollbar.Visible == true) or (cMaxY>ParentMaxY+Scrollbar.VerticalScrollbar.Width-1) then
			ParentMaxY = ParentMaxY - Scrollbar.HorizontalScrollbar.Height;
			if (Scrollbar.HorizontalScrollbar.BottomAligned) then
				Scrollbar.VerticalScrollbar.PosY = 1;
			else
				Scrollbar.VerticalScrollbar.PosY = 2;
			end
		else
			Scrollbar.VerticalScrollbar.PosY = 1;
		end
		if Scrollbar.VerticalScrollbar.RightAligned then
			Scrollbar.VerticalScrollbar.PosX = ParentMaxX-Scrollbar.VerticalScrollbar.Width+1;
			Scrollbar.ContentContainer.PosX = 1;
		else
			Scrollbar.VerticalScrollbar.PosX = 1;
			Scrollbar.ContentContainer.PosX = 2;
		end

		Scrollbar.VerticalScrollbar.Height = ParentMaxY;
		Scrollbar.ContentContainer.Height = ParentMaxY;

		Scrollbar.VerticalScrollbar.PercentVisible = ParentMaxY/(cMaxY);
		Scrollbar.VerticalScrollbar.TrackSize = (Scrollbar.VerticalScrollbar.Height-2);
		Scrollbar.VerticalScrollbar.KnobSize = math.floor( (Scrollbar.VerticalScrollbar.TrackSize*Scrollbar.VerticalScrollbar.PercentVisible) + 0.5 );
		if (Scrollbar.VerticalScrollbar.KnobSize < 1) then Scrollbar.VerticalScrollbar.KnobSize = 1; end -- At least 1px
		Scrollbar.VerticalScrollbar.KnobNegativeSpace = (Scrollbar.VerticalScrollbar.TrackSize)-Scrollbar.VerticalScrollbar.KnobSize;
		
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
	-- Draws the up arrow, using the design settings at `Scrollbar.VerticalScrollbar.Design`.
	Scrollbar.VerticalScrollbar.DrawUpArrow = function()
		-- Up arrow
		local oX, oY = term.getCursorPos()
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
		term.setCursorPos(oX, oY)
	end
	-- Draws the down arrow, using the design settings at `Scrollbar.VerticalScrollbar.Design`.
	Scrollbar.VerticalScrollbar.DrawDownArrow = function()
		-- Down Arrow
		local oX, oY = term.getCursorPos()
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
			Scrollbar.VerticalScrollbar.Window.setCursorPos(iW, (ParentMaxY-1)+1);
			Scrollbar.VerticalScrollbar.Window.write(downArrow);
		end
		term.setCursorPos(oX, oY)
	end
	-- Draws both arrows using `Scrollbar.VerticalScrollbar.DrawUpArrow()` and `Scrollbar.VerticalScrollbar.DrawDownArrow()`.
	Scrollbar.VerticalScrollbar.DrawArrows = function()
		Scrollbar.VerticalScrollbar.DrawUpArrow();
		Scrollbar.VerticalScrollbar.DrawDownArrow();
	end
	-- Draws the track, which sits between the arrow buttons and behind the knob.
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
	-- Draws the knob, which sits somewhere between the arrow buttons, is inside the track, and shows the current scroll position. This is what you drag around to scroll.
	Scrollbar.VerticalScrollbar.DrawKnob = function()
		local oX, oY = term.getCursorPos()
		Scrollbar.VerticalScrollbar.DrawTrack();
		local knobText = setKnobDesign(true);
		for iH = 0, Scrollbar.VerticalScrollbar.KnobSize-1 do
			for iW = 1, Scrollbar.VerticalScrollbar.Width do -- Allows the text to be printed on all sides if scrollbar width >1
				Scrollbar.VerticalScrollbar.Window.setCursorPos(iW,Scrollbar.VerticalScrollbar.KnobY+iH);
				Scrollbar.VerticalScrollbar.Window.write(knobText);
			end
		end
		term.setCursorPos(oX, oY)
	end


	-- Print
	-- (Re)Draws all components of the scrollbar. If the scrollbar is moving positions or shrinking, we'll attempt to clean up things before doing so.
	-- This will move the scrollbar if necessary and then call `DrawArrows()` and `DrawKnob()`.
	Scrollbar.VerticalScrollbar.Draw = function()
		Scrollbar.VerticalScrollbar.RecalculateValues();
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


	-- Scrolls vertically by a given amount. If amount is negative, the contents will scroll up. If the scroll amount is outside the amount left to scroll, we'll scroll whatever we can for that direction.
	Scrollbar.VerticalScrollbar.Scroll = function(amount)
		if amount == nil then amount = 1 end
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
	-- Scrolls the vertical scrollbar to a % value. So, for example, if you want to scroll halfway down, provide .5 for "scroll to 50%".
	Scrollbar.VerticalScrollbar.ScrollToPercent = function(percent)
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		local gotoScrollPosition = -math.floor(math.floor( ((percent*(cMaxY-ParentMaxY))*100) + .5)/100)+1;
		local scrollDelta = Scrollbar.VerticalScrollbar.ScrollPosition-gotoScrollPosition
		Scrollbar.VerticalScrollbar.Scroll(scrollDelta);
	end
	-- Scrolls the content up by the vertical size of the content (a page length) minus the number of lines scrolled by the scroll wheel.
	-- So, if you have a content window 9 lines tall, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content up by 7 lines (if possible).
	Scrollbar.VerticalScrollbar.PageUp = function()
		local ccMaxX, ccMaxY = Scrollbar.ContentContainer.Window.getSize();
		Scrollbar.VerticalScrollbar.Scroll(-(ccMaxY-math.abs(Jello.Config.Mouse.ScrollAmount)));
	end
	Scrollbar.VerticalScrollbar.PageDown = function()
		local ccMaxX, ccMaxY = Scrollbar.ContentContainer.Window.getSize();
		Scrollbar.VerticalScrollbar.Scroll(ccMaxY-math.abs(Jello.Config.Mouse.ScrollAmount));
	end



	-- Horizontal
	-- Recalculates the scrollbar values, such as PosX, PosY, height, width, position, track size, knob size, and more. These are the sizes of elements of the scrollbar and where they are.
	Scrollbar.HorizontalScrollbar.RecalculateValues = function()
		ParentMaxX, ParentMaxY = Scrollbar.ParentWindow.getSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();

		local xOffset = (Scrollbar.VerticalScrollbar.Visible) and Scrollbar.VerticalScrollbar.Width or 0;
		if (cMaxX > ParentMaxX-xOffset) then
			Scrollbar.HorizontalScrollbar.Visible = true;
			Scrollbar.HorizontalScrollbar.Window.setVisible(true)
		else
			Scrollbar.HorizontalScrollbar.Visible = false;
			Scrollbar.HorizontalScrollbar.Window.setVisible(false)
		end
		
		if (Scrollbar.VerticalScrollbar.Visible == true) or (cMaxX>ParentMaxX+Scrollbar.HorizontalScrollbar.Height-1) then
			ParentMaxX = ParentMaxX-Scrollbar.VerticalScrollbar.Width;
			if (Scrollbar.VerticalScrollbar.RightAligned) then
				Scrollbar.HorizontalScrollbar.PosX = 1;
			else
				Scrollbar.HorizontalScrollbar.PosX = 2;
			end
		else
			Scrollbar.HorizontalScrollbar.PosX = 1;
		end

		if Scrollbar.HorizontalScrollbar.BottomAligned then
			Scrollbar.HorizontalScrollbar.PosY = ParentMaxY-Scrollbar.HorizontalScrollbar.Height+1;
			Scrollbar.ContentContainer.PosY = 1;
		else
			Scrollbar.HorizontalScrollbar.PosY = 1;
			Scrollbar.ContentContainer.PosY = 2;
		end



		Scrollbar.HorizontalScrollbar.Width = ParentMaxX;
		Scrollbar.ContentContainer.Width = ParentMaxX;
		
		-- HorizontalScrollbar
		Scrollbar.HorizontalScrollbar.PercentVisible = (ParentMaxX/cMaxX);
		Scrollbar.HorizontalScrollbar.TrackSize = (Scrollbar.HorizontalScrollbar.Width-2);
		Scrollbar.HorizontalScrollbar.KnobSize = math.floor( (Scrollbar.HorizontalScrollbar.TrackSize*Scrollbar.HorizontalScrollbar.PercentVisible) + 0.5 );
		if (Scrollbar.HorizontalScrollbar.KnobSize < 1) then Scrollbar.HorizontalScrollbar.KnobSize = 1; end -- At least 1px
		Scrollbar.HorizontalScrollbar.KnobNegativeSpace = (Scrollbar.HorizontalScrollbar.TrackSize)-Scrollbar.HorizontalScrollbar.KnobSize;
		
		--[[
			get the total number of line NOT visible: (cMaxY-ParentMaxY)
			get the total number of lines on top: currentScrollPos-1
			scroll %: -(numberOfLinesOnTop/numberOfLinesNotVisible)
		]]
		Scrollbar.HorizontalScrollbar.PercentScrolled = -(Scrollbar.HorizontalScrollbar.ScrollPosition-1)/(cMaxX-ParentMaxX);

		-- How much of the negative space (track without knob) is above us? (how far down are we)
		Scrollbar.HorizontalScrollbar.KnobX = 2+math.floor( (Scrollbar.HorizontalScrollbar.KnobNegativeSpace)*Scrollbar.HorizontalScrollbar.PercentScrolled +.5);
	end



	-- Draws the left arrow button, using the design settings at `Scrollbar.HorizontalScrollbar.Design`.
	Scrollbar.HorizontalScrollbar.DrawLeftArrow = function()
		-- Left arrow
		local oX, oY = term.getCursorPos()
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
		term.setCursorPos(oX, oY)
	end
	-- Draws the right arrow button, using the design settings at `Scrollbar.HorizontalScrollbar.Design`.
	Scrollbar.HorizontalScrollbar.DrawRightArrow = function()
		-- Right arrow
		local oX, oY = term.getCursorPos()
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
			Scrollbar.HorizontalScrollbar.Window.setCursorPos((ParentMaxX-1)+1,iH);
			Scrollbar.HorizontalScrollbar.Window.write(rightArrowText);
		end
		term.setCursorPos(oX, oY)
	end
	-- Draws both arrow buttons using `Scrollbar.HorizontalScrollbar.DrawLeftArrow()` and `Scrollbar.HorizontalScrollbar.DrawRightArrow()`.
	Scrollbar.HorizontalScrollbar.DrawArrows = function()
		Scrollbar.HorizontalScrollbar.DrawLeftArrow()
		Scrollbar.HorizontalScrollbar.DrawRightArrow();
	end
	-- Draws the track, which sits between the arrow buttons and behind the knob.
	Scrollbar.HorizontalScrollbar.DrawTrack = function()
		local trackText = setTrackDesign(false);
		for iW = 1, Scrollbar.HorizontalScrollbar.TrackSize do
			for iH = 1, Scrollbar.HorizontalScrollbar.Height do -- Allows the text to be printed on all sides if scrollbar height >1
				Scrollbar.HorizontalScrollbar.Window.setCursorPos(iW+1,iH);
				Scrollbar.HorizontalScrollbar.Window.write(trackText);
			end
		end
	end
	-- Draws the knob, which sits somewhere between the arrow buttons, is inside the track, and shows the current scroll position. This is what you drag around to scroll.
	-- This will call `Scrollbar.HorizontalScrollbar.DrawTrack()` before doing anything.
	Scrollbar.HorizontalScrollbar.DrawKnob = function()
		local oX, oY = term.getCursorPos()
		Scrollbar.HorizontalScrollbar.DrawTrack();
		local knobText = setKnobDesign(false);
		for i = 0, Scrollbar.HorizontalScrollbar.KnobSize-1 do
			for iH = 1, Scrollbar.HorizontalScrollbar.Height do -- Allows the text to be printed on all sides if scrollbar height >1
				Scrollbar.HorizontalScrollbar.Window.setCursorPos(Scrollbar.HorizontalScrollbar.KnobX+i,iH);
				Scrollbar.HorizontalScrollbar.Window.write(knobText);
			end
		end
		term.setCursorPos(oX, oY)
	end
	-- (Re)Draws all components of the scrollbar. If the scrollbar is moving positions or shrinking, we'll attempt to clean up things before doing so.
	-- This will move the scrollbar if necessary and then call `DrawArrows()` and `DrawKnob()`.
	Scrollbar.HorizontalScrollbar.Draw = function()
		Scrollbar.HorizontalScrollbar.RecalculateValues();
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


	-- Scrolls horizontally by a given amount. If amount is negative, the contents will scroll right. If the scroll amount is outside the amount left to scroll, we'll scroll whatever we can for that direction.
	Scrollbar.HorizontalScrollbar.Scroll = function(amount)
		if amount == nil then amount = 1 end
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
	-- Scrolls the horizontal scrollbar to a % value. So, for example, if you want to scroll halfway to the right, provide .5 for "scroll to 50%".
	Scrollbar.HorizontalScrollbar.ScrollToPercent = function(percent)
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		local gotoScrollPosition = -math.floor(math.floor( ((percent*(cMaxX-ParentMaxX))*100) + .5)/100)+1;
		local scrollDelta = Scrollbar.HorizontalScrollbar.ScrollPosition-gotoScrollPosition

		Scrollbar.HorizontalScrollbar.Scroll(scrollDelta);
	end
	-- Scrolls the content left by the horizontal size of the content (a page width) minus the number of lines scrolled by the scroll wheel.
	-- So, if you have a content window 9 lines wide, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content left by 7 lines (if possible).
	Scrollbar.HorizontalScrollbar.PageLeft = function()
		local ccMaxX, ccMaxY = Scrollbar.ContentContainer.Window.getSize();
		Scrollbar.HorizontalScrollbar.Scroll(-(ccMaxX-math.abs(Jello.Config.Mouse.ScrollAmount)));
	end
	-- Scrolls the content right by the horizontal size of the content (a page width) minus the number of lines scrolled by the scroll wheel.
	-- So, if you have a content window 9 lines tall, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content right by 7 lines (if possible).
	Scrollbar.HorizontalScrollbar.PageRight = function()
		local ccMaxX, ccMaxY = Scrollbar.ContentContainer.Window.getSize();
		Scrollbar.HorizontalScrollbar.Scroll(ccMaxX-math.abs(Jello.Config.Mouse.ScrollAmount));
	end


	-- Detached

	-- (Re)Draw both scrollbars
	Scrollbar.Draw = function()
		local oX, oY = term.getCursorPos()
		Scrollbar.VerticalScrollbar.Draw();
		Scrollbar.HorizontalScrollbar.Draw();
		term.setCursorPos(oX, oY)
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


	-- Scroll the content to the up by a given amount.
	Scrollbar.ScrollUp = function(amount)
		if (type(amount) ~= "number") then amount = -1 end
		if (amount > 0) then amount = amount*-1; end
		Scrollbar.VerticalScrollbar.Scroll(amount)
	end
	-- Scroll the content to the down by a given amount.
	Scrollbar.ScrollDown = function(amount)
		if (type(amount) ~= "number") then amount = 1 end
		if (amount < 0) then amount = amount*-1; end
		Scrollbar.VerticalScrollbar.Scroll(amount)
	end
	-- Scroll the content to the left by a given amount.
	Scrollbar.ScrollLeft = function(amount)
		if (type(amount) ~= "number") then amount = -1 end
		if (amount > 0) then amount = amount*-1; end
		Scrollbar.HorizontalScrollbar.Scroll(amount)
	end
	-- Scroll the content to the right by a given amount.
	Scrollbar.ScrollRight = function(amount)
		if (type(amount) ~= "number") then amount = 1 end
		if (amount < 0) then amount = amount*-1; end
		Scrollbar.HorizontalScrollbar.Scroll(amount)
	end

	-- Scrolls to the top of the content.
	Scrollbar.ScrollToTop = function()
		Scrollbar.VerticalScrollbar.Scroll(-(1-Scrollbar.VerticalScrollbar.ScrollPosition))
	end
	-- Scrolls to the bottom of the content.
	Scrollbar.ScrollToBottom = function()
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		local amount = (ParentMaxY-cMaxY+1) - Scrollbar.VerticalScrollbar.ScrollPosition
		Scrollbar.VerticalScrollbar.Scroll(-amount)
	end

	-- Scrolls all the way to the far most left position.
	Scrollbar.ScrollToFarLeft = function()
		Scrollbar.HorizontalScrollbar.Scroll(-(1-Scrollbar.HorizontalScrollbar.ScrollPosition))
	end
	-- Scrolls all the way to the far most right position.
	Scrollbar.ScrollToFarRight = function()
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		local amount = (ParentMaxX-cMaxX+1) - Scrollbar.HorizontalScrollbar.ScrollPosition
		Scrollbar.HorizontalScrollbar.Scroll(-amount)
	end


	-- Whether the content is scroll all the way to the top.
	Scrollbar.IsAtTop = function()
		return Scrollbar.VerticalScrollbar.ScrollPosition==1
	end
	-- Whether the content is scroll all the way to the bottom.
	Scrollbar.IsAtBottom = function()
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		return (Scrollbar.VerticalScrollbar.ScrollPosition == (ParentMaxY-cMaxY+1))
	end
	-- Whether the content is scroll all the way to the far left.
	Scrollbar.IsAtFarLeft = function()
		return Scrollbar.HorizontalScrollbar.ScrollPosition==1
	end
	-- Whether the content is scroll all the way to the far right.
	Scrollbar.IsAtFarRight = function()
		setParentSize();
		local cMaxX, cMaxY = Scrollbar.Content.Window.getSize();
		return (Scrollbar.HorizontalScrollbar.ScrollPosition == (ParentMaxX-cMaxX+1))
	end

	-- Negative for up/left
	-- Scroll the content vertically and horizontally via one function call. A number less than 0 means either up (verticalAmount) or to the left (horizontalAmount).
	Scrollbar.Scroll = function(verticalAmount, horizontalAmount)
		Scrollbar.VerticalScrollbar.Scroll(verticalAmount)
		if horizontalAmount ~= nil then
			Scrollbar.HorizontalScrollbar.Scroll(horizontalAmount)
		end
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

	-- Calculates the coordinates of various items given the mouse_click x and y value. This is to correct the mouse position in relation to the content window's position and size.
	local function getCoordinates(x, y)
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

		local vK1Offset = 0;
		local hK1Offset = 0;
		if (not Scrollbar.VerticalScrollbar.RightAligned) then hK1Offset = 1; end
		if (not Scrollbar.HorizontalScrollbar.BottomAligned) then vK1Offset = 1; end

		-- Vertical scrollbar
		cords.vSbX1 = Scrollbar.VerticalScrollbar.PosX; -- far left
		cords.vSbY1 = Scrollbar.VerticalScrollbar.PosY; -- top
		cords.vSbX2 = cords.vSbX1 + Scrollbar.VerticalScrollbar.Width-1; -- far right
		cords.vSbY2 = cords.vSbY1 + Scrollbar.VerticalScrollbar.Height-1; -- bottom
		cords.vSbK1 = Scrollbar.VerticalScrollbar.KnobY + vK1Offset;
		cords.vSbK2 = cords.vSbK1+Scrollbar.VerticalScrollbar.KnobSize-1;

		-- Horizontal scrollbar
		cords.hSbX1 = Scrollbar.HorizontalScrollbar.PosX; -- far left
		cords.hSbY1 = Scrollbar.HorizontalScrollbar.PosY; -- top
		cords.hSbX2 = cords.hSbX1 + Scrollbar.HorizontalScrollbar.Width-1; -- far right
		cords.hSbY2 = cords.hSbY1 + Scrollbar.HorizontalScrollbar.Height-1; -- bottom
		cords.hSbK1 = Scrollbar.HorizontalScrollbar.KnobX + hK1Offset;
		cords.hSbK2 = cords.hSbK1+Scrollbar.HorizontalScrollbar.KnobSize-1;

		return cords;
	end

	-- A simple helper function to check if the mouse_click was inside the parent window bounds.
	local function coordinatesInsideParentWindow(cords)
		if (type(cords) ~= "table") then return false end
		return (cords.mX >= cords.pWX1 and cords.mX <= cords.pWX2) and (cords.mY >= cords.pWY1 and cords.mY <= cords.pWY2);
	end
	-- A simple helper function to check if the mouse_click was inside the content container bounds.
	local function coordinatesInsideContentContainer(cords)
		if (type(cords) ~= "table") then return false end
		return (cords.mX >= cords.cWX1 and cords.mX <= cords.cWX2) and (cords.mY >= cords.cWY1 and cords.mY <= cords.cWY2);
	end
	-- A simple helper function to check if the mouse_click was inside the vertical scrollbar bounds.
	local function coordinatesInsideVerticalScrollbar(cords)
		if (type(cords) ~= "table") then return false end
		return (cords.mX >= cords.vSbX1 and cords.mX <= cords.vSbX2) and (cords.mY >= cords.vSbY1 and cords.mY <= cords.vSbY2);
	end
	-- A simple helper function to check if the mouse_click was inside the horizontal scrollbar bounds.
	local function coordinatesInsideHorizontalScrollbar(cords)
		if (type(cords) ~= "table") then return false end
		return (cords.mX >= cords.hSbX1 and cords.mX <= cords.hSbX2) and (cords.mY >= cords.hSbY1 and cords.mY <= cords.hSbY2);
	end

	-- Marks both scrollbar and their components as not activate (not being interacted with).
	local function deactivateAll()
		Scrollbar.VerticalScrollbar.KnobActive = false;
		Scrollbar.VerticalScrollbar.TrackActive = false;
		Scrollbar.VerticalScrollbar.UpArrowActive = false;
		Scrollbar.VerticalScrollbar.DownArrowActive = false;
		Scrollbar.VerticalScrollbar.Draw();
		Scrollbar.HorizontalScrollbar.KnobActive = false;
		Scrollbar.HorizontalScrollbar.TrackActive = false;
		Scrollbar.HorizontalScrollbar.LeftArrowActive = false;
		Scrollbar.HorizontalScrollbar.RightArrowActive = false;
		Scrollbar.HorizontalScrollbar.Draw();
	end
	--[[

		Handle event is similar to queueEvent, you pass events, such as term_resize or mouse_click, to the scrollbar to handle

		@tparam table The event inside a table (with additional arguments) that you wish the scrollbar to handle
	]]
	Scrollbar.HandleEvent = function(...)
		event = {...}
		if (#event <= 0) then
			return;
		end
		if (type(event[1]) == "table") then -- ??
			event = event[1]
		end

		setParentSize();

		local function getContentRelativeEventCoordinates()
			local cords = getCoordinates(event[3], event[4]);
			return {event[1], event[2], cords.mX-Scrollbar.HorizontalScrollbar.ScrollPosition+1, cords.mY-Scrollbar.VerticalScrollbar.ScrollPosition+1}
			-- Don't block, but return the correct cords
		end

		local eventName = event[1];
		if (eventName == "mouse_up") then
			if (Scrollbar.VerticalScrollbar.KnobActive) then
				-- Scroll the content
				local percent = ((Scrollbar.VerticalScrollbar.KnobY-2)/Scrollbar.VerticalScrollbar.KnobNegativeSpace);
				Scrollbar.VerticalScrollbar.ScrollToPercent(percent);
				
				deactivateAll()
				return true
			elseif (Scrollbar.HorizontalScrollbar.KnobActive) then
				-- Scroll the content
				local percent = ((Scrollbar.HorizontalScrollbar.KnobX-2)/Scrollbar.HorizontalScrollbar.KnobNegativeSpace);
				Scrollbar.HorizontalScrollbar.ScrollToPercent(percent);

				deactivateAll()
				return true
			elseif (Scrollbar.VerticalScrollbar.UpArrowActive or Scrollbar.VerticalScrollbar.DownArrowActive) then
				deactivateAll()
				return true
			elseif (Scrollbar.HorizontalScrollbar.LeftArrowActive or Scrollbar.HorizontalScrollbar.RightArrowActive) then
				deactivateAll()
				return true
			elseif (Scrollbar.VerticalScrollbar.TrackActive) then
				deactivateAll()
				return true
			elseif (Scrollbar.HorizontalScrollbar.TrackActive) then
				deactivateAll()
				return true
			end

		elseif (eventName == "mouse_scroll") then
			local cords = getCoordinates(event[3], event[4]);
			if (coordinatesInsideParentWindow(cords)) then -- Within the Scrollbar parent
				-- Run it by the children first
				for id, child in ipairs(Scrollbar.Children) do -- This way nested scrollbars have priority
					if (child ~= nil) then
						if (type(child.HandleEvent) == "function") then
							if child.HandleEvent(getContentRelativeEventCoordinates()) == true then
								return true
							end
						end
					end
				end
				if ((Scrollbar.HorizontalScrollbar.Visible and not Scrollbar.VerticalScrollbar.Visible) or coordinatesInsideHorizontalScrollbar(cords)) then
					-- Scroll horizontally IF cursor over the horizontal scrollbar OR horizontal scrolling is that is available
					if (event[2]>0) then
						-- Going right
						if Scrollbar.IsAtFarRight() then
							return false, getContentRelativeEventCoordinates() -- Do not capture this event
						end
					else
						if Scrollbar.IsAtFarLeft() then
							return false, getContentRelativeEventCoordinates() -- Do not capture this event
						end
					end
					Scrollbar.HorizontalScrollbar.Scroll(event[2] * Jello.Config.Mouse.ScrollAmount);
					return true
				elseif (Scrollbar.VerticalScrollbar.Visible) then
					-- Check if we're ignoring this (since we're maxed out)
					if (event[2]>0) then
						-- Going down
						if Scrollbar.IsAtBottom() then
							return false, getContentRelativeEventCoordinates() -- Do not capture this event
						end
					else
						if Scrollbar.IsAtTop() then
							return false, getContentRelativeEventCoordinates() -- Do not capture this event
						end
					end

					Scrollbar.VerticalScrollbar.Scroll(event[2] * Jello.Config.Mouse.ScrollAmount);
					return true
				end
			end


		elseif (eventName == "mouse_click") and (event[2] == Jello.Config.Mouse.PrimaryButton) then -- Mouse 1 (primary) click
			local cords = getCoordinates(event[3], event[4]);
			if (coordinatesInsideParentWindow(cords)) then
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
							return true
						elseif (cords.mY == cords.vSbY2) then -- Clicked the down arrow
							Scrollbar.VerticalScrollbar.DownArrowActive = true;
							Scrollbar.VerticalScrollbar.DrawDownArrow();
							Scrollbar.VerticalScrollbar.Scroll(1);
							return true
						elseif (cords.mY >= cords.vSbK1 and cords.mY <= cords.vSbK2) then
							Scrollbar.VerticalScrollbar.KnobActive = true;
							Scrollbar.VerticalScrollbar.KnobActiveY = cords.vSbK1-cords.mY; -- Top of knob - mouse y
							Scrollbar.VerticalScrollbar.DrawKnob();
							return true
						elseif (cords.mY > cords.vSbY1 and cords.mY < cords.vSbK1) then
							-- Page up
							Scrollbar.VerticalScrollbar.TrackActive = true;
							Scrollbar.VerticalScrollbar.DrawKnob();
							Scrollbar.PageUp();
							return true
						elseif (cords.mY > cords.vSbK2 and cords.mY < cords.vSbY2) then
							-- Page down
							Scrollbar.VerticalScrollbar.TrackActive = true;
							Scrollbar.VerticalScrollbar.DrawKnob();
							Scrollbar.PageDown();
							return true
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
							return true
						elseif (cords.mX == cords.hSbX2) then -- Clicked the right arrow
							Scrollbar.HorizontalScrollbar.RightArrowActive = true;
							Scrollbar.HorizontalScrollbar.DrawRightArrow();
							Scrollbar.HorizontalScrollbar.Scroll(1);
							return true
						elseif (cords.mX >= cords.hSbK1 and cords.mX <= cords.hSbK2) then
							Scrollbar.HorizontalScrollbar.KnobActive = true;
							Scrollbar.HorizontalScrollbar.KnobActiveX = cords.hSbK1-cords.mX; -- Top of knob - mouse y
							Scrollbar.HorizontalScrollbar.DrawKnob();
							return true
						elseif (cords.mX > cords.hSbX1 and cords.mX < cords.hSbK1) then
							-- Page left
							Scrollbar.HorizontalScrollbar.TrackActive = true;
							Scrollbar.HorizontalScrollbar.DrawKnob();
							Scrollbar.PageLeft();
							return true
						elseif (cords.mX > cords.hSbK2 and cords.mX < cords.hSbX2) then
							-- Page right
							Scrollbar.HorizontalScrollbar.TrackActive = true;
							Scrollbar.HorizontalScrollbar.DrawKnob();
							Scrollbar.PageRight();
							return true
						end
					end
				end
			end

		elseif (eventName == "mouse_drag") then
			local cords = getCoordinates(event[3], event[4]);
			-- if (not coordinatesInsideParentWindow(cords)) then return end

			if (Scrollbar.VerticalScrollbar.KnobActive and (cords.mY >= cords.cWY1 and cords.mY <= cords.cWY2)) then
				local upOffet = (Scrollbar.HorizontalScrollbar.BottomAligned) and 1 or 0;
				local downOffset = (Scrollbar.HorizontalScrollbar.BottomAligned) and 0 or 1;
				local y = cords.mY + Scrollbar.VerticalScrollbar.KnobActiveY - downOffset;

				if (y < cords.vSbY1+upOffet) then -- Too far up
					y = cords.vSbY1+upOffet;
				elseif (y > (cords.vSbY2)-Scrollbar.VerticalScrollbar.KnobSize-downOffset) then -- Too far down
					y = (cords.vSbY2)-Scrollbar.VerticalScrollbar.KnobSize-downOffset;
				end
				Scrollbar.VerticalScrollbar.KnobY = y;
				if (Scrollbar.ScrollOnDrag) then
					local percent = ((Scrollbar.VerticalScrollbar.KnobY-2)/Scrollbar.VerticalScrollbar.KnobNegativeSpace);
					Scrollbar.VerticalScrollbar.ScrollToPercent(percent);
				end
				Scrollbar.VerticalScrollbar.DrawKnob();
				return true

			elseif (Scrollbar.HorizontalScrollbar.KnobActive and (cords.mX >= cords.cWX1 and cords.mX <= cords.cWX2)) then
				-- Scroll left/right
				local leftOffset = (Scrollbar.VerticalScrollbar.RightAligned) and 1 or 0;
				local rightOffset = (Scrollbar.VerticalScrollbar.RightAligned) and 0 or 1;
				local x = cords.mX + Scrollbar.HorizontalScrollbar.KnobActiveX - rightOffset;

				if (x < cords.hSbX1+leftOffset) then -- Too far left
					x = cords.hSbX1+leftOffset;
				elseif (x > (cords.hSbX2)-Scrollbar.HorizontalScrollbar.KnobSize-rightOffset) then -- Too far right
					x = (cords.hSbX2)-Scrollbar.HorizontalScrollbar.KnobSize-rightOffset;
				end
				Scrollbar.HorizontalScrollbar.KnobX = x;
				if (Scrollbar.ScrollOnDrag) then
					local percent = ((Scrollbar.HorizontalScrollbar.KnobX-2)/Scrollbar.HorizontalScrollbar.KnobNegativeSpace);
					Scrollbar.HorizontalScrollbar.ScrollToPercent(percent);
				end
				Scrollbar.HorizontalScrollbar.DrawKnob();
				return true
			end

		elseif (eventName == "key") then
			if (Scrollbar.ComponentInFocus == nil) then
				if (event[2] == keys.pageUp) then
					Scrollbar.PageUp();
					return true
				elseif (event[2] == keys.pageDown) then
					Scrollbar.PageDown();
					return true
				elseif (Jello.ScrollLock) then
					if (event[2] == keys.left) then
						Scrollbar.ScrollLeft();
						return true
					elseif (event[2] == keys.up) then
						Scrollbar.ScrollUp();
						return true
					elseif (event[2] == keys.right) then
						Scrollbar.ScrollRight();
						return true
					elseif (event[2] == keys.down) then
						Scrollbar.ScrollDown();
						return true
					end
				end
			end
		elseif (eventName == "term_resize") then
			Scrollbar.redraw();
		end

		if (event[1] == "mouse_up" or event[1] == "mouse_click" or event[1] == "mouse_drag" or event[1] == "mouse_scroll") then
			local cords = getCoordinates(event[3], event[4]);
			if (Scrollbar.AbsorbOutOfBoundsMouseEvents and not coordinatesInsideParentWindow(cords)) then
				return true -- We "handled" it (don't pass these coordinates on)
			end
			if (coordinatesInsideParentWindow(cords)) then
				for id, child in ipairs(Scrollbar.Children) do -- This way nested scrollbars have priority
					if (child ~= nil) then
						if (type(child.HandleEvent) == "function") then
							if child.HandleEvent(getContentRelativeEventCoordinates()) == true then
								return true
							end
						end
					end
				end
			end
			return false, getContentRelativeEventCoordinates()
		end

		for id, child in ipairs(Scrollbar.Children) do -- This way nested scrollbars have priority
			if (child ~= nil) then
				if (type(child.HandleEvent) == "function") then
					if child.HandleEvent(event) == true then
						return true
					end
				end
			end
		end

		return false, event -- We're not capturing this event
	end


	return Scrollbar;
end