--[[


	Jello GUI

	
	To load this API, do:
	local jelloAPI = loadfile("Jello.lua")();
	
	Then to load a component, you would do:
	local ScrollbarView = jelloAPI.Components.ScrollbarView();

	For Scheduler:
	local Scheduler = jelloAPI.CoreComponents.Scheduler();


	----

	Naming conversion similar to C# (PascalCase except parameters).

	MIT License


	Developed with love by @Watsuprico


]]


-- Put everything into this:
local Jello = {
	["Version"] = "0.1.0",

	["Components"] = {},
	["CoreComponents"] = {},

	["ScrollLock"] = false,

	["Config"] = {
		["Mouse"] = {
			["PrimaryButton"] = 1,
			["SecondaryButton"] = 2,
			["ScrollAmount"] = 2,
		},
	},
};



local function tablecopy(t)
  local t2 = {}
  for k, v in pairs(t) do
    t2[k] = v
  end
  return t2
end



-- Load components
local componentFiles = fs.list("/Components/");
for i = 1, #componentFiles do
	local okay, err = pcall(function() 
		local componentFile = componentFiles[i];
		if #componentFile >= 5 then
			if componentFile:sub(-4) == ".lua" then
				local componentName = componentFile:sub(0, -5);
				local component = loadfile("/Components/" .. componentFile)(Jello);
				Jello.Components[componentName] = component;
			end
		end
	end)
	if not okay then
		print(err);
	end
end

local coreComponentFiles = fs.list("/CoreComponents/");
for i = 1, #coreComponentFiles do
	local okay, err = pcall(function() 
		local coreComponentFile = coreComponentFiles[i];
		if #coreComponentFile >= 5 then
			if coreComponentFile:sub(-4) == ".lua" then
				local coreComponentName = coreComponentFile:sub(0, -5);
				local coreComponent = loadfile("/CoreComponents/" .. coreComponentFile)(Jello);
				Jello.CoreComponents[coreComponentName] = coreComponent;
			end
		end
	end)
	if not okay then
		print(err);
	end
end


if (Jello.CoreComponents.Scheduler ~= nil) then
	--[[
		Creates a copy of the JelloScheduler from Jello.CoreComponents.Scheduler

		@treturn JelloScheduler
	]]
	Jello.GetScheduler = function()
		return tablecopy(Jello.CoreComponents.Scheduler());
	end
end

-- Return API:
return Jello;