# Name
A vertical and horizontal scrollbar.

Allows you to have a terminal of any size displayed to the user and allow them to easily move around to see everything there is to see.


To create a new instance of this, use:
```lua
local Jello = loadfile("Jello.lua")();

local Scrollbar = Jello.Components.Scrollbar(parentWindow);
```
`parentWindow` must be a terminal object that you want the scrollbar component to draw to. This terminal must be dedicated for the scrollbar, nothing else should draw to it. If you wish to draw something to the same window, consider drawing to the scrollbar content window (i.e. the terminal being scrolled).


Then throw your content into `.Content.Window`, or use `.SetContentWindow(windowObject)`\
`windowObject` is any size terminal object that you wish the scrollbar to wrap around and enable scrolling for. This is the main content drawn, the thing users interact with. `windowObject` can be omitted/nil, if that is the case a new terminal object is created the size of the parent window (this makes both scrollbar not visible since they're not needed).


If one of the scrollbars are not needed, it is not drawn.



Tested for a terminal object of size 1000x1000. _Larger sizes are possible, however, you will run into issues drawing to such a massive terminal object. Performance is not hindered by the scrollbar component._


Scroll does not use the native `.scroll()` function provided by terminal objects. Doing so would cause content to be lost when scrolling up or to the right (requiring data to be redrawn).\
Instead, what happens is the scrollbar creates 3 windows: one for the vertical scrollbar, one for the horizontal scrollbar, and one to "contain" the content (named the ContentContainer). The `ContentContainer` window is set to the remainder of the parent window after the scrollbars are drawn (that is, width: `ParentMaxX-VerticalScrollbar.Width` and height: `ParentMaxY-HorizontalScrollbar.Height`).\
This container acts as a mask, as everything outside the width/height of the window is chopped off and now drawn. This prevents the content drawing over the scrollbars. Doing this greatly reduces the number of terminal function calls, and thus reducing jittering and screen flashes all while retaining all the content without needing to redraw.



## Events
These are the events emitted to children components
`jello::scroll`: Pushed to every child component (using `component.HandleEvent()`) to notify them we've scrolled the content window. Two argument 

## Properties
_Private properties/methods are only accessible by the component itself. These are stored locally with the component. Public properties/methods are stored in the component's table, which is returned to you when you create a new instance of the component (that is, Scrollbar.PropertyName)_\
_All public names are in PascalCase._

### Private
`Jello`: (type: `Jello`) - internal reference to the Jello API that loaded this component in. (Same as your `Jello`).
`ParentMaxX`: (type: `number`) - the width of the parent window (the window we draw to)
`ParentMaxY`: (type: `number`) - the height of the parent window



### Public
`ComponentInFocus`: Reserved, not used
`Children`: Reserved, not used
`AbsorbOutOfBoundsMouseEvents = False`: Boolean, whether mouse events that occur outside of the bounds of the scrollbar parent are discarded by the event handler. This would prevent click events being provided even if they're outside the parent (for example, x=-1 and y=-4). This should be enabled if you're using the `HandleEvent()` results to dictate sending events to programs running inside the scrollbar. If this scrollbar is a child component to another component, **DO NOT SET THIS TRUE** (that would lock all mouse events to this scrollbar)\

`Design`: Parent design (each scrollbar inherits their deign from here, but are free to override values). See Design.

`ParentWindow`: Terminal, the containing window the scrollbars are draw into

`ScrollOnDrag = true`: Boolean, if true the content scrolls while dragging the scroll knob. If false, content is scrolled when the mouse button is released (could improve performance).

`Content`:
	`PosX`: Number, read-only, where the content is positioned inside the content container. Set to `HorizontalScrollbar.ScrollPosition`\
	`PosY`: Number, read-only, where the content is positioned inside the content container. Set to `HorizontalScrollbar.ScrollPosition`\
	`Window`: Terminal, this is the window that is intended to be used by you to draw your item to. This is the window that is scrolled, use this for all terminal calls.

`ContentContainer`:
	`PosX = 1`: Number, read-only, left position of the content container relative to the parent window. Automatically set to the lowest number taking the vertical scrollbar's position and width into account (if left aligned).
	`PosY = 1`: Number, read-only, top position of the content container relative to the parent window. Automatically set, like PosX, but takes the horizontal scrollbar's position and height into account (if top aligned).
	`Width`: Number, read-only, width of the container automatically set to the width of the parent window minus the vertical scrollbar's width
	`Height`: Number, read-only, width of the container automatically set to the height of the parent window minus the horizontal scrollbar's height
	`Window`: Terminal, the masking window for the content window. That is, this is the parent of the content window.


`VerticalScrollbar`: Vertical scrollbar specific properties and values.\
	`PosX = ParentMaxX`: Number, left cursor position of the scrollbar (relative to the ParentWindow)\
	`PosY = 1`: Number, top cursor position of the scrollbar (relative to the ParentWindow)\
	`Width`: Number, width of the scrollbar\
	`Height = ParentMaxY`: Number, height of this scrollbar, automatically set to the height of the parent window with the height of the horizontal scrollbar (if visible) taken into account\
	`RightAligned = true`: Boolean, if true the scrollbar will be on the right side of the parent window. If false the scrollbar will be on the left side of the parent window.\
	`Visible = true`: Boolean, whether the scrollbar is drawn to the screen (if false, the content window will stretch to the parent window horizontally).\
	`Window`: Terminal object, read-only, **do not modify this**. The window the scrollbar is drawn in. This is then drawn to the parent window.\
	`ScrollPosition`: Number, read-only, represents the number of lines the content window has above the parent window. That is how far away the top of the content window is in relation to the content container window. If you scroll down two lines (click the scroll down button twice) this number would be -2, representing the content window is at y=-2 relative to the parent window. _Another way to think of this is the number of lines you scrolled but with a negative sign._\ Do not set this value, to scroll use `.VerticalScrollbar.Scroll(amount)`\
	`TrackSize`: Number, read-only, height of the scrollbar minus two (`.VerticalScrollbar.Height-2`). Size of the track (behind the knob).\
	`KnobSize`: Number, read-only, height of the scrolling knob `round(VerticalScrollbar.TrackSize * \VerticalScrollbar.PercentVisible)`. Will always be >=1.
	`KnobNegativeSpace`: Number, read-only, track space minus the knob height. How much of the track the knob does not cover.\
	`PercentVisible`: Number, read-only, parent height (accounting for the horizontal scrollbar) divided by the content height. That is, the percentage of content that can be displayed on screen at any given time.\
	`PercentScrolled = 0`: Number, read-only, a percentage representing the amount we've scroll down. 0% means we have not scrolled, 50% means we're halfway to the bottom, and 100% means we've scrolled all the way down and cannot scroll anymore. DO not set this value, to scroll to a percentage use `.VerticalScrollbar.ScrollToPercentage(percent)`, ensuring percent is a percent (.05 = 5%). The formula used to calculate this number is -(number of lines on top)/(number of lines not visible) or -(ScrollPosition-1)/(content window height - parent window height)\
	`KnobY`: Number, read-only, the Y coordinate of the top of the knob relative to the scrollbar's window. Calculated via: (`2 + round( KnobNegativeSpace * PercentScrolled )`) (the two represents the height of the scroll up/down buttons (1 each)).\

`HorizontalScrollbar`: Vertical scrollbar specific properties and values.\
	`PosX = 1`: Number, left cursor position of the scrollbar (relative to the ParentWindow)\
	`PosY = ParentMaxY`: Number, top cursor position of the scrollbar (relative to the ParentWindow)\
	`Width = ParentMaxX`: Number, width of the scrollbar, automatically set and takes the vertical scrollbar (if visible) into account\
	`Height = 1`: Number, height of this scrollbar.\
	`BottomAligned = true`: Boolean, if true the scrollbar will be on the bottom of the parent window. If false the scrollbar will be on the top side of the parent window.\
	`Visible = true`: Boolean, whether the scrollbar is drawn to the screen (if false, the content window will stretch to the parent window vertically).\
	`Window`: Terminal object, read-only, **do not modify this**. The window the scrollbar is drawn in. This is then drawn to the parent window.\
	`ScrollPosition`: Number, read-only, represents the number of lines the content window has to the left of the parent window. That is how far away the left side of the content window is in relation to the content container window. If you scroll right two lines (click the scroll right button twice) this number would be -2, representing the content window is at x=-2 relative to the parent window. _Another way to think of this is the number of lines you scrolled but with a negative sign._\ Do not set this value, to scroll use `.HorizontalScrollbar.Scroll(amount)`\
	`TrackSize`: Number, read-only, width of the scrollbar minus two (`.HorizontalScrollbar.Width-2`). Size of the track (behind the knob).\
	`KnobSize`: Number, read-only, width of the scrolling knob `round(HorizontalScrollbar.TrackSize * \HorizontalScrollbar.PercentVisible)`. Will always be >=1.
	`KnobNegativeSpace`: Number, read-only, track space minus the knob width. How much of the track the knob does not cover.\
	`PercentVisible`: Number, read-only, parent width (accounting for the horizontal scrollbar) divided by the content width. That is, the percentage of content that can be displayed on screen at any given time.\
	`PercentScrolled = 0`: Number, read-only, a percentage representing the amount we've scroll down. 0% means we have not scrolled, 50% means we're halfway to the bottom, and 100% means we've scrolled all the way down and cannot scroll anymore. DO not set this value, to scroll to a percentage use `.HorizontalScrollbar.ScrollToPercentage(percent)`, ensuring percent is a percent (.05 = 5%). The formula used to calculate this number is -(number of lines on top)/(number of lines not visible) or -(ScrollPosition-1)/(content window width - parent window width)\
	`KnobX`: Number, read-only, the X coordinate of the top of the knob relative to the scrollbar's window. Calculated via: (`2 + round( KnobNegativeSpace * PercentScrolled )`) (the two represents the width of the scroll up/down buttons (1 each)).\





## Methods
### Private
```lua
local function functionName(myParameter): void
```
`myParameter`: (type: `myParameterType`) - description



```lua
local function setParentSize(): number, number
```
Function calculates the size of the parent window, being sure to take into account the size of any visible scrollbars.\
Returns the ParentMaxX and ParentMaxY values.



```lua
local function scroll(bar, amount): void
```
Common scrolling code. Moves the content window, redraws it, sends the jello:scroll event to child elements, calls `bar.RecalculateValues()` and `bar.DrawKnob()` to update the scrollbar.\
`bar`: (type: `Scrollbar.HorizontalScrollbar` or `Scrollbar.VerticalScrollbar`) - which bar we're scrolling\
`amount`: (type: `number`) - the amount we're scrolling. A negative number means up/left.



```lua
local function setTrackDesign(vertical): string
```
Sets the background and foreground color for a scrollbar track (contains the knob) and returns the text to be displayed in the track.\
`vertical`: (type: `boolean`) - whether to use the vertical scrollbar or not. False means we set the horizontal scrollbar style.





```lua
local function setKnobDesign(vertical): string
```
Sets the background and foreground color for a scrollbar knob and returns the text to be displayed on the knob.\
`vertical`: (type: `boolean`) - whether to use the vertical scrollbar or not. False means we set the horizontal scrollbar style.





```lua
local function getCordinates(x, y): Table
```
Calculates the coordinates of various items given the mouse_click x and y value. This is to correct the mouse position in relation to the content window's position and size.\
`x`: (type: `number`) - mouse_click event x value.
`y`: (type: `number`) - mouse_click event y value.


Returns a table with the following values:\
`mX`: mouse X coordinate corrected for the parent window position.\
`mY`: mouse Y coordinate corrected for the parent window position.

`pWX1`: parent window far left X coordinate (always 1).\
`pWY1`: parent window top Y coordinate (always 1).\
`pWX2`: parent window far right X coordinate (pWX1 + parent width - 1).\
`pWY2`: parent window bottom Y coordinate (pWY1 + parent height - 1).

`cWX1`: content window far left X coordinate (Scrollbar.ContentContainer.PosX).\
`cWY1`: content window top Y coordinate (Scrollbar.ContentContainer.PosY).\
`cWX2`: content window far right X coordinate (cWX1 + Scrollbar.ContentContainer.Width - 1).\
`cWY2`: content window bottom Y coordinate (cWY1 + Scrollbar.ContentContainer.Height - 1).

`vSbX1`: vertical scrollbar far left X coordinate (Scrollbar.VerticalScrollbar.PosX).\
`vSbY1`: vertical scrollbar top Y coordinate (Scrollbar.VerticalScrollbar.PosY).\
`vSbX2`: vertical scrollbar far right X coordinate (vSbX1 + Scrollbar.VerticalScrollbar.Width-1).\
`vSbY2`: vertical scrollbar bottom Y coordinate (vSbY1 + Scrollbar.VerticalScrollbar.Height-1).\
`vSbK1`: vertical scrollbar knob top Y coordinate (Scrollbar.VerticalScrollbar.KnobY + vK1Offset). vK1Offset is 1 if the horizontal scrollbar is aligned to the bottom.\
`vSbK2`: vertical scrollbar knob bottom Y coordinate (vSbK1+Scrollbar.VerticalScrollbar.KnobSize-1)

`hSbX1`: horizontal scrollbar far left X coordinate (Scrollbar.HorizontalScrollbar.PosX).\
`hSbY1`: horizontal scrollbar top Y coordinate (Scrollbar.HorizontalScrollbar.PosY).\
`hSbX2`: horizontal scrollbar far right X coordinate (vSbX1 + Scrollbar.HorizontalScrollbar.Width-1).\
`hSbY2`: horizontal scrollbar bottom Y coordinate (vSbY1 + Scrollbar.HorizontalScrollbar.Height-1).\
`hSbK1`: horizontal scrollbar knob top Y coordinate (Scrollbar.HorizontalScrollbar.KnobY + vK1Offset). vK1Offset is 1 if the vertical scrollbar is top aligned.\
`hSbK2`: horizontal scrollbar knob bottom Y coordinate (vSbK1+Scrollbar.HorizontalScrollbar.KnobSize-1)


```lua
local function coordinatesInsideParentWindow(cords): boolean
```
A simple helper function to check if the mouse_click was inside the parent window bounds.\
`cords`: (type: `Table`) - The table returned by the `getCoordinates()` function.


```lua
local function coordinatesInsideContentContainer(cords): boolean
```
A simple helper function to check if the mouse_click was inside the content container bounds.\
`cords`: (type: `Table`) - The table returned by the `getCoordinates()` function.


```lua
local function coordinatesInsideVerticalScrollbar(cords): boolean
```
A simple helper function to check if the mouse_click was inside the vertical scrollbar bounds.\
`cords`: (type: `Table`) - The table returned by the `getCoordinates()` function.


```lua
local function coordinatesInsideHorizontalScrollbar(cords): boolean
```
A simple helper function to check if the mouse_click was inside the horizontal scrollbar bounds.\
`cords`: (type: `Table`) - The table returned by the `getCoordinates()` function.

```lua
local function deactivateAll(): void
```
Marks both scrollbar and their components as not activate (not being interacted with).


---


### Public
```lua
local function Scrollbar.Function(myParameter): void
```
`myParameter`: (type: `myParameterType`) - description



```lua
local function Scrollbar.SetContentWindow(windowObject): (void|Terminal)
```
Sets the content that is being scrolled. If empty, we create the window and return it.
`windowObject`: (type: `nil` or `Terminal`) - the window to be used as the content inside the scrollbar. The terminal being scrolled around. If empty, we create this.





```lua
local function Scrollbar.VerticalScrollbar.RecalculateValues(): void
```
Recalculates the scrollbar values, such as PosX, PosY, height, width, position, track size, knob size, and more. These are the sizes of elements of the scrollbar and where they are.


```lua
local function Scrollbar.VerticalScrollbar.DrawUpArrow(): void
```
Draws the up arrow, using the design settings at `Scrollbar.VerticalScrollbar.Design`.


```lua
local function Scrollbar.VerticalScrollbar.DrawDownArrow(): void
```
Draws the down arrow, using the design settings at `Scrollbar.VerticalScrollbar.Design`.


```lua
local function Scrollbar.VerticalScrollbar.DrawArrows(): void
```
Draws both arrows using `Scrollbar.VerticalScrollbar.DrawUpArrow()` and `Scrollbar.VerticalScrollbar.DrawDownArrow()`.


```lua
local function Scrollbar.VerticalScrollbar.DrawTrack(): void
```
Draws the track, which sits between the arrow buttons and behind the knob.


```lua
local function Scrollbar.VerticalScrollbar.DrawKnob(): void
```
Draws the knob, which sits somewhere between the arrow buttons, is inside the track, and shows the current scroll position. This is what you drag around to scroll.\
This will call `Scrollbar.VerticalScrollbar.DrawTrack()` before doing anything.


```lua
local function Scrollbar.VerticalScrollbar.Draw(): void
```
(Re)Draws all components of the scrollbar. If the scrollbar is moving positions or shrinking, we'll attempt to clean up things before doing so. This will move the scrollbar if necessary and then call `DrawArrows()` and `DrawKnob()`.


```lua
local function Scrollbar.VerticalScrollbar.Scroll(amount): void
```
Scrolls vertically by a given amount. If amount is negative, the contents will scroll up. If the scroll amount is outside the amount left to scroll, we'll scroll whatever we can for that direction.\
`amount`: (type: `number`) - how much to scroll vertically and in which direction (<0 for up and >0 for down).


```lua
local function Scrollbar.VerticalScrollbar.ScrollToPercent(percent): void
```
Scrolls the vertical scrollbar to a % value. So, for example, if you want to scroll halfway down, provide .5 for "scroll to 50%".\
`percent`: (type: `myParameterType`) - description


```lua
local function Scrollbar.VerticalScrollbar.PageUp(): void
```
Scrolls the content up by the vertical size of the content (a page length) minus the number of lines scrolled by the scroll wheel. So, if you have a content window 9 lines tall, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content up by 7 lines (if possible).


```lua
local function Scrollbar.VerticalScrollbar.PageDown(): void
```
Scrolls the content down by the vertical size of the content (a page length) minus the number of lines scrolled by the scroll wheel. So, if you have a content window 9 lines tall, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content down by 7 lines (if possible).


#### HorizontalScrollbar


```lua
local function Scrollbar.HorizontalScrollbar.RecalculateValues(): void
```
Recalculates the scrollbar values, such as PosX, PosY, height, width, position, track size, knob size, and more. These are the sizes of elements of the scrollbar and where they are.


```lua
local function Scrollbar.HorizontalScrollbar.DrawLeftArrow(): void
```
Draws the left arrow button, using the design settings at `Scrollbar.HorizontalScrollbar.Design`.


```lua
local function Scrollbar.HorizontalScrollbar.DrawRightArrow(): void
```
Draws the right arrow button, using the design settings at `Scrollbar.HorizontalScrollbar.Design`.


```lua
local function Scrollbar.HorizontalScrollbar.DrawArrows(): void
```
Draws both arrow buttons using `Scrollbar.HorizontalScrollbar.DrawLeftArrow()` and `Scrollbar.HorizontalScrollbar.DrawRightArrow()`.


```lua
local function Scrollbar.HorizontalScrollbar.DrawTrack(): void
```
Draws the track, which sits between the arrow buttons and behind the knob.


```lua
local function Scrollbar.HorizontalScrollbar.DrawKnob(): void
```
Draws the knob, which sits somewhere between the arrow buttons, is inside the track, and shows the current scroll position. This is what you drag around to scroll.\
This will call `Scrollbar.HorizontalScrollbar.DrawTrack()` before doing anything.


```lua
local function Scrollbar.HorizontalScrollbar.Draw(): void
```
(Re)Draws all components of the scrollbar. If the scrollbar is moving positions or shrinking, we'll attempt to clean up things before doing so. This will move the scrollbar if necessary and then call `DrawArrows()` and `DrawKnob()`.


```lua
local function Scrollbar.HorizontalScrollbar.Scroll(amount): void
```
Scrolls horizontally by a given amount. If amount is negative, the contents will scroll left. If the scroll amount is outside the amount left to scroll, we'll scroll whatever we can for that direction.\
`amount`: (type: `number`) - how much to scroll horizontally and in which direction (<0 for left and >0 for right).


```lua
local function Scrollbar.HorizontalScrollbar.ScrollToPercent(percent): void
```
Scrolls the horizontal scrollbar to a % value. So, for example, if you want to scroll halfway to the right, provide .5 for "scroll to 50%".\
`percent`: (type: `myParameterType`) - description


```lua
local function Scrollbar.HorizontalScrollbar.PageLeft(): void
```
Scrolls the content left by the horizontal size of the content (a page width) minus the number of lines scrolled by the scroll wheel. So, if you have a content window 9 lines wide, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content left by 7 lines (if possible).


```lua
local function Scrollbar.HorizontalScrollbar.PageRight(): void
```
Scrolls the content right by the horizontal size of the content (a page width) minus the number of lines scrolled by the scroll wheel. So, if you have a content window 9 lines tall, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content right by 7 lines (if possible).



---



```lua
local function Scrollbar.Draw(): void
```
(Re)Draw both scrollbars.




```lua
local function Scrollbar.PageUp(): void
```
Scrolls the content up by the vertical size of the content (a page length) minus the number of lines scrolled by the scroll wheel. So, if you have a content window 9 lines tall, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content up by 7 lines (if possible).

```lua
local function Scrollbar.PageDown(): void
```
Scrolls the content down by the vertical size of the content (a page length) minus the number of lines scrolled by the scroll wheel. So, if you have a content window 9 lines tall, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content down by 7 lines (if possible).

```lua
local function Scrollbar.PageLeft(): void
```
Scrolls the content left by the horizontal size of the content (a page width) minus the number of lines scrolled by the scroll wheel. So, if you have a content window 9 lines wide, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content left by 7 lines (if possible).

```lua
local function Scrollbar.PageRight(): void
```
Scrolls the content right by the horizontal size of the content (a page width) minus the number of lines scrolled by the scroll wheel. So, if you have a content window 9 lines tall, and the `Jello.Config.Mouse.ScrollAmount` is set to 2 (default), this will scroll the content right by 7 lines (if possible).




```lua
local function Scrollbar.ScrollUp(amount): void
```
Scroll the content to the up by a given amount.
`amount`: (type: `number`) - Scroll up by this much. Must be a positive number, if amount is more than possible we'll scroll whatever amount is left to scroll.

```lua
local function Scrollbar.ScrollDown(amount): void
```
Scroll the content to the down by a given amount.
`amount`: (type: `number`) - Scroll down by this much. Must be a positive number, if amount is more than possible we'll scroll whatever amount is left to scroll.

```lua
local function Scrollbar.ScrollLeft(amount): void
```
Scroll the content to the left by a given amount.
`amount`: (type: `number`) - Scroll left by this much. Must be a positive number, if amount is more than possible we'll scroll whatever amount is left to scroll.

```lua
local function Scrollbar.ScrollRight(amount): void
```
Scroll the content to the right by a given amount.
`amount`: (type: `number`) - Scroll right by this much. Must be a positive number, if amount is more than possible we'll scroll whatever amount is left to scroll.




```lua
local function Scrollbar.ScrollToTop(): void
```
Scrolls to the top of the content.

```lua
local function Scrollbar.ScrollToBottom(): void
```
Scrolls to the bottom of the content.

```lua
local function Scrollbar.ScrollToFarLeft(): void
```
Scrolls all the way to the far most left position.

```lua
local function Scrollbar.ScrollToFarRight(): void
```
Scrolls all the way to the far most right position.



```lua
local function Scrollbar.IsAtTop(): boolean
```
Whether the content is scroll all the way to the top.

```lua
local function Scrollbar.IsAtBottom(): boolean
```
Whether the content is scroll all the way to the bottom.

```lua
local function Scrollbar.IsAtFarLeft(): boolean
```
Whether the content is scroll all the way to the far left.

```lua
local function Scrollbar.IsAtFarRight(): boolean
```
Whether the content is scroll all the way to the far right.



```lua
local function Scrollbar.Scroll(verticalAmount, horizontalAmount): void
```
Scroll the content vertically and horizontally via one function call. A number less than 0 means either up (verticalAmount) or to the left (horizontalAmount).
`verticalAmount`: (type: `number`) - Scroll vertically by this amount. A number less than 0 means up, otherwise bottom.\
`horizontalAmount`: (type: `number`) - Scroll horizontally by this amount. A number less than 0 means left, otherwise to the right.

```lua
local function Scrollbar.VerticalScrollbar.GetScrollAmount(): number
```
Returns the scrollbar's ScrollPosition value subtracted by 1. This tells you which line number is at the top of the content window.

```lua
local function Scrollbar.HorizontalScrollbar.GetScrollAmount(): number
```
Returns the scrollbar's ScrollPosition value subtracted by 1. This tells you which character number is on the left side of the content window.

```lua
local function Scrollbar.GetScrollAmount(): number, number
```
Returns the value of `Scrollbar.VerticalScrollbar.GetScrollAmount()` and `Scrollbar.HorizontalScrollbar.GetScrollAmount()`.




```lua
local function Scrollbar.HandleEvent(): boolean, Table
```
Handles various OS events, such as `mouse_click`, `mouse_scroll`, `term_resize`, among others.\
If the event is captures, that is it clicks either a scrollbar, scrollbar component, or a child component, then the first return (the boolean) is true. This tells the caller to NOT continue processing the event as we have handled it.\
The second return is the relative mouse coordinates, (the return of `getCordinates()`), and is only provided IF we did NOT capture the event (first return is false).