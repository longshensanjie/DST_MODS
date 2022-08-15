--[[
This is a huge monolithic file because mods are distributed as source code,
and I want this to behave like a single "plugin" that people can add to their mods,
without introducing the possibility of people getting some of it but missing pieces.
]]

--TODO: MAJOR update hooks into optionsscreen for redux, or whatever they are currently on when you get to this...
--TODO: check controller compatibility, focus hookups for the right panel
--TODO: maybe better handling of dirty options:
--	what happens when switching mods?
--	what about making mod settings changes, then going to normal settings and changing? (currently apply is separate)
--TODO: more documentation of the API
--TODO: check more edge cases to fix bugs?

--[[ Mod Settings Member Variables ]]--

local modsettings = {}
local modcontrols = {}
local modcontrols_lookup = {}

--[[ Mod Settings API ]]--

local ModSettings = {}

local mod_icon_prefabs = {}

local function CheckToLoadIcon(modname)
	-- Written with reference to ModsScreen:LoadModInfoPrefabs
	if modsettings[modname] == nil and modcontrols[modname] == nil then
		--In order to have the mod icons on the menu, we need to load them
		local info = KnownModIndex:GetModInfo(modname)
		if info and info.icon_atlas and info.iconpath then
			local modinfoassets = {
				Asset("ATLAS", info.icon_atlas),
				Asset("IMAGE", info.iconpath),
			}
			local prefab = Prefab("MODSCREEN_"..modname, nil, modinfoassets, nil)
			if mod_icon_prefabs then -- we haven't loaded them yet
				table.insert(mod_icon_prefabs, prefab)
			else
				RegisterPrefabs(prefab)
				TheSim:LoadPrefabs({prefab.name})
			end
		end
	end
end

local function GetModConfigTable(modname, configname)
	local config_options = KnownModIndex:LoadModConfigurationOptions(modname, TheNet:GetIsClient())
	for i,v in ipairs(config_options) do
		if v.name == configname then
			return v
		end
	end
end

ModSettings.AddSetting = function(modname, configname, callback, configdata)
	if modsettings[modname] == nil then
		CheckToLoadIcon(modname)
		modsettings[modname] = {}
	end
	if configdata == nil then
		configdata = GetModConfigTable(modname, configname)
	end
	if type(configdata) == "table" then
		configdata.callback = callback
		table.insert(modsettings[modname], configdata)
	end
end

--[[
Parameters:
	modname: The name of the mod. You can just pass in the variable modname from your modmain
	control_name: The name for the control. This must be unique within your mod.
	control_desc: The description for the control; this is what will show on the mod controls screen.
	default_key: The key string or id for the default button.
		You can pass in letters (upper or lowercase, it doesn't matter),
		or one of the ids from the KEY_... variables in constants.lua.
	handler: (optional) a function to run when the key is pressed or released (depending on down)
	down: (optional) whether to run the handler when the key is pressed (true) or released (false)
	
Usage:
1) (Recommended) with handler, which will let this set up the key handler registration and switching for you:
	local function ShoutHandler()
		-- Do shout
	end
	ModSettings.AddControl(modname, "shout", "Shout" "Z", ShoutHandler, false)
2) with no handler, in which case you should use the returned function to check the key:
	local IsShout = ModSettings.AddControl(modname, "shout", "Shout", "Z")
	function OnKeyPress(key, down)
		if IsShout(key) and not down then
			-- Do shout
		end
	end
3) Or both at once, since when you provide a handler it still returns the key checking function

Notes:
You can add both a down and an up handler for the same control name. If you do, it's best
to keep the rest of the parameters the same (everything except handler and down).
]]
ModSettings.AddControl = function(modname, control_name, control_desc, default_key, handler, down)
	if modcontrols[modname] == nil then
		CheckToLoadIcon(modname)
		modcontrols[modname] = {}
		modcontrols_lookup[modname] = {}
	end
	if type(default_key) == "number" then
		default_key = string.char(default_key)
	end
	default_key = default_key:upper()
	local saved_key = GetModConfigData(control_name, modname, true)
	if saved_key == false then saved_key = "" end
	if saved_key == nil then saved_key = default_key end
	if type(saved_key) == "number" then
		if saved_key <= 122 and saved_key >= 91 then
			saved_key = string.char(saved_key)
		else
			saved_key = "请设置按键为A-Z"
		end
	end
	saved_key = saved_key:upper()
	local control_data = modcontrols_lookup[modname][control_name]
	if not control_data then --We haven't added this one yet, make its table
		control_data = {
			name = control_name,
			label = control_desc,
			default = default_key,
			saved = saved_key,
			value = saved_key, -- value used for the current, unapplied value in the UI
		}
		table.insert(modcontrols[modname], control_data)
	else --just add in the new description and default key
		control_data.label = control_desc
		if control_data.saved == control_data.default then
			control_data.saved = default_key
		end
		control_data.default = default_key
	end
	if handler then
		if control_data[down] then
			-- There was an earlier binding for this key and direction, remove it
			local handler_category = down and "onkeydown" or "onkeyup"
			TheInput[handler_category]:RemoveHandler(control_data[down])
		end
		local AddKeyHandler = TheInput["AddKey"..(down and "Down" or "Up").."Handler"]
		control_data[down] = saved_key == "" and {fn = handler} --key is unbound
											  or AddKeyHandler(TheInput, saved_key:lower():byte(), handler)
	end
	modcontrols_lookup[modname][control_name] = control_data
	return function(key) return modcontrols_lookup[modname][control_name].saved:lower():byte() == key end
end

-- The following were not intended as part of the API, but the UI for this has slogged, so
-- exposing these to allow for external UIs (like Geometric Placement's)

ModSettings.GetControlsForMod = function(modname)
	local controls = {}
	for _,control in ipairs(modcontrols[modname] or {}) do 
		table.insert(controls, {
			name = control.name,
			label = control.label,
			default = control.default,
			value = control.value
		})
	end
	return controls
end

local function ReregisterControl(handler, key, down)
	local handler_fn = handler.fn
	if handler.event ~= nil then
		local handler_category = down and "onkeydown" or "onkeyup"
		TheInput[handler_category]:RemoveHandler(handler)
	end
	if key == "" then --this was unbinding the key
		-- return an "empty" handler that just preserves the callback function
		return {fn = handler_fn}
	end
	local AddKeyHandler = TheInput["AddKey"..(down and "Down" or "Up").."Handler"]
	return AddKeyHandler(TheInput, key:lower():byte(), handler_fn)
end

ModSettings.RebindControl = function(modname, control_name, binding)
	local control_data = modcontrols_lookup[modname] and modcontrols_lookup[modname][control_name]
	if not control_data then return end
	control_data.value = binding
	control_data.saved = binding
	for _, down in pairs({true, false}) do
		if control_data[down] then
			ReregisterControl(control_data[down], binding, down)
		end
	end
	local _print = print
	print = function() end --janky, but KnownModIndex functions kinda spam the logs
	local config = KnownModIndex:LoadModConfigurationOptions(modname, true)
	local settings = {}
	local namelookup = {} --so we don't have to scan through the options
	for i,v in ipairs(config) do
		namelookup[v.name] = i
		table.insert(settings, {name = v.name, label = v.label, options = v.options, default = v.default, saved = v.saved})
	end
	local setting_index = namelookup[control_name]
	if setting_index == nil then
		-- Maybe this isn't in the normal mod config; we should save it anyway
		table.insert(settings, {
			name = control_name,
			label = control_data.label or "",
			options = {},
			default = control_data.default,
		})
		setting_index = #settings
	end
	settings[setting_index].saved = control_data.saved
	--Note: don't need to include options that aren't in the menu,
	-- because they're already in there from the options load above
	KnownModIndex:SaveConfigurationOptions(function() end, modname, settings, true)
	print = _print --restore print functionality!
end

return ModSettings