# Core Components
WindowManager: Where we host Window object in, allows Windows the be moved, minimized, etc

Taskbar: The action bar for the WindowManager. By default you have to create this, but WindowManager does have a function to create one for you.
Window: Similar to a window within a OS. This is container for other elements

Scheduler: Multitasking, handles coroutines


# Window Components
Stored inside the `/Components/` folder and under Jello.Components.\
To create a new instance of a component, do `myComponent = Jello.Components.ComponentName(...);` passing in any required parameters as specified in the component docs.

When loading these components, Jello passes the "Jello" table (itself). Doing this allows the components to access common and shared functions/properties. For example, users can adjust which mouse button is the "primary" one (change between left or right click being the primary action). This allows all components to behave in a similar manner and to have this behavior adjusted by a single setting.


Panel: A container for other Jello window components, allows you to group things together
Button: Clickable button
ScrollView: Think a panel but with a scroll bar (vertical and horizontal)
TextBox
ProgressBar

ImageView?




### Scrollbar
A simple scrollbar with child elements, content window, and event handlers for a vertical and horizontal scrollbar.
