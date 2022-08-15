if _silence == nil then
	-- print(_version,modinfo.name) --Show current version of lib
end

local old_lib = mods.lib or {} 


if old_lib._libStopWorking then
	old_lib._libStopWorking()
end

local IS_ACTIVE = true 

local function _libStopWorking()
	IS_ACTIVE = nil
end

local function GetGlobal(gname,default)
	local res=_G.rawget(_G,gname)
	if res == nil and default ~= nil then
		_G.rawset(_G,gname,default)
		return default
	else
		return res
	end
end

if not mods.player_preinit_fns then
	mods.player_preinit_fns={}
	--Dirty hack
	local old_MakePlayerCharacter = _G.require("prefabs/player_common")
	local function new_MakePlayerCharacter(...)
		local inst=old_MakePlayerCharacter(...)
		for _,v in ipairs(mods.player_preinit_fns) do
			v(inst)
		end
		return inst
	end
	_G.package.loaded["prefabs/player_common"] = new_MakePlayerCharacter
end

function AddPlayersPreInit(fn)
	table.insert(mods.player_preinit_fns,fn)
end

local player_postinit_fns = {}
function AddPlayersPostInit(fn)
	table.insert(player_postinit_fns,fn)
end

local done_players = {}
AddPlayersPreInit(function(inst)
	local s = inst.prefab or inst.name
	if not done_players[s] then
		done_players[s] = true
		AddPrefabPostInit(s,function(inst)
			for _,v in ipairs(player_postinit_fns) do
				v(inst)
			end
		end)
	end
end)

local player_afterinit_fns = {}
function AddPlayersAfterInit(fn)
	table.insert(player_afterinit_fns,fn)
end
AddPlayersPostInit(function(inst) 
	if #player_afterinit_fns > 0 then
		inst:DoTaskInTime(0,function(inst)
			for i=1,#player_afterinit_fns do
				player_afterinit_fns[i](inst)
			end
		end)
	end
end)



local world_init_fns = {} --old_lib.world_init_fns or {} 

local function AddWorldPostInit(fn) 
	table.insert(world_init_fns,fn)
end
local was_forest
local function world_init(inst)
	if was_forest then
		return
	end
	was_forest = true
	for i=1,#world_init_fns do
		world_init_fns[i](inst)
	end
end
AddPrefabPostInit("world",world_init)

local EmptyFunction = function() end

local static = old_lib.static or {} 

local _mods = old_lib._mods or {}


local TheSim=_G.TheSim
local TheNet=_G.TheNet
local require=_G.require
local SpawnPrefab=_G.SpawnPrefab
local p=GetGlobal("p",EmptyFunction) --import from Cheats
local arr=GetGlobal("arr",EmptyFunction) --import from Cheats
local SetSharedLootTable=_G.SetSharedLootTable
local Vector3=_G.Vector3
local SEASONS = _G.SEASONS
local FUELTYPE = _G.FUELTYPE
local ACTIONS = _G.ACTIONS
local GetTime = _G.GetTime
local AllPlayers = _G.AllPlayers

local function GetWatchWorldStateFn(inst,event,num)
	num = num or 0
	local w = inst.worldstatewatching
	if w and w[event] then
		local count = #w[event] - num
		if count > 0 then
			local fn = w[event][count] 
			return fn, w[event], count
		end
	end
	return EmptyFunction, false
end

local function GetListener(inst,event,source,offset) --���������� ���������� �������
	--source - �������� (�������). ��, ��� ����������� � ��������� ��� ����������. ����� ����� (���� �� ������ ������).
	source = source or inst
	offset = offset or 0
	local w = inst.event_listeners --event_listening --���������, ��� � ��������� ���� "event_listeners"
	--arr(w)
	if w and w[event] then
		local fns = w[event][source]
		if fns ~= nil then
			if offset == -1 and #fns > 0 then
				return fns[1], fns, 1 --���������� � ������ 1.06
			elseif #fns > offset then
				local fn = fns[#fns-offset]
				return fn, fns, (#fns-offset)
			end
		end
	end
	return EmptyFunction, false
end


local saved_timers
local function SaveTimers(inst)
	saved_tasks = {}
	if inst.pendingtasks then
		for k,v in pairs(inst.pendingtasks) do
			saved_tasks[k]=true
		end
	end
end

local function GetLastTimer(inst)
	if inst.pendingtasks then
		for k,v in pairs(inst.pendingtasks) do
			if not saved_tasks[k] then
				return k
			end
		end
	end
end

local function GetLastTimerFn(inst)
	local timer = GetLastTimer(inst)
	return timer and timer.fn
end

local function AddHookOnLastTask(component_name, new_fn)
	local comp = require("components/"..component_name)
	local old_ctor = comp._ctor
	local old_fn
	function comp._ctor(self, inst, ...)
		SaveTimers(inst)
		old_ctor(self, inst, ...)
		local task = GetLastTimer(inst)
		old_fn = task.fn
		task.fn = function(...)
			old_fn(...)
			new_fn(...)
		end
	end
end

local function AddHookOnComponent(component_name, before_fn, after_fn)
	local comp = require("components/"..component_name)
	local old_ctor = comp._ctor
	function comp._ctor(self, inst, ...)
		if before_fn then
			before_fn(self,inst,old_ctor)
		end
		local res = old_ctor(self, inst, ...)
		if after_fn then
			after_fn(self,inst,old_ctor)
		end
		return res
	end
end

local cook_aliases=
{
	cookedsmallmeat = "smallmeat_cooked",
	cookedmonstermeat = "monstermeat_cooked",
	cookedmeat = "meat_cooked"
}
local cooking = require("cooking")
local ingredients = cooking.ingredients
local function GetTags(prefab) --���������� �������� �� ������
	if cook_aliases[prefab] and not ingredients[prefab] then
		prefab = cook_aliases[prefab] --������� �� �������, ������.
	end
	return ingredients[prefab] and ingredients[prefab].tags or {}
end


local data_players,w = old_lib.data_players or {}
local SaveOption = function(player,option_name,value)
	player.data_player[option_name] = value
end

local LoadOption = function(player,option_name)
	return player.data_player[option_name]
end

local GetOption = function(userid,option_name)
	return data_players[userid] and data_players[userid][option_name]
end

AddPlayersAfterInit(function(inst) --������� ���������� ������ � ����� ������� ������
	local data = data_players[inst.userid] --�� "after" �� �������� userid
	if not data then --� ������ ���
		data = {}
		data_players[inst.userid] = data
	end
	inst.data_player = data -----> ���� �������� ������ � ��� ��.
end)


local players_update_fns = {}
local players_update_MAXRANGE = 0 --������� ������������� ���������� (����� ����� ��������� ������������ ����).

local function InitializePlayersUpdate()
	--print("InitializePlayersUpdate")
	AddWorldPostInit(function(w)
		--print("My AddWorldPostInit")
		w:DoPeriodicTask(0.5 + math.random()*0.1,function(w)
			--print("upd0")
			if #AllPlayers > 1 then
				--print("upd1")
				local time_now = GetTime()
				for i=1,#AllPlayers-1 do
					local inst1 = AllPlayers[i]
					for j=i+1,#AllPlayers do
						local inst2 = AllPlayers[j]
						local dist = inst1:GetDistanceSqToInst(inst2)
						--print("upd2 = "..tostring(dist).." "..tostring(players_update_MAXRANGE))
						if dist <= players_update_MAXRANGE then --� �������� ������������ ���� �� ����� �������
							for fn,dst in pairs(players_update_fns) do
								if dist <= dst then
									--print("call fn")
									fn(inst1,inst2,dist,time_now)
								end
							end
						end
					end
				end
			end
		end)
	end)
end

local function RegisterPlayersUpdate(range,fn)
	--print("RegisterPlayersUpdate")
	if #players_update_fns == 0 then
		InitializePlayersUpdate() --��������� ������������� (�.�. ����, ��� ���������)
	end
	local new_range = range*range
	players_update_fns[fn] = new_range --����� �������� � �������, ���� ������ ��� �� �������.
	if new_range > players_update_MAXRANGE then
		players_update_MAXRANGE = new_range
	end
end

local function UnRegisterPlayersUpdate(fn)
	players_update_fns[fn] = nil
end



--mods.active_mods_by_name = {} --�������� ���� (������������� ������ �� ���������� �����). ���������������� ������ �� �������.
local function SearchForModsByName()
	if mods.active_mods_by_name then
		return --��� �������������������. ���� ������ ���������������.
	end
	mods.active_mods_by_name = {}
	if not (_G.KnownModIndex and _G.KnownModIndex.savedata and _G.KnownModIndex.savedata.known_mods) then
		print("ERROR COMMON LIB: Can't find KnownModIndex!")
		return
	end
	for name,mod in pairs(_G.KnownModIndex.savedata.known_mods) do
		if (mod.enabled or mod.temp_enabled or _G.KnownModIndex:IsModForceEnabled(name)) --��� �������
			and not mod.temp_disabled --� �� ��������
		then
			local real_name = mod.modinfo.name
			if real_name then
				mods.active_mods_by_name[real_name] = true
			end
		end
	end
end


local AddIngredientValues = function(names, tags, cancook, candry)
	for _,name in pairs(names) do
		if not ingredients[name] then --No breaking!
			ingredients[name] = { tags= {}}
		end
		if cancook and not ingredients[name.."_cooked"] then --No breaking!
			ingredients[name.."_cooked"] = {tags={}}
		end
		if candry and not ingredients[name.."_dried"] then --No breaking!
			ingredients[name.."_dried"] = {tags={}}
		end
		for k,v in pairs(tags) do
			ingredients[name].tags[k] = v
			if cancook then
				ingredients[name.."_cooked"].tags.precook = 1
				ingredients[name.."_cooked"].tags[k] = v
			end
			if candry then
				ingredients[name.."_dried"].tags.dried = 1
				ingredients[name.."_dried"].tags[k] = v
			end
		end
	end
end



local join_fns = {} --������� ������������� ������.
local split_fns = {} --������� ��������� ������.
local function ImproveStacks() --�������� �����.
	--print("ImproveStacks")
	if mods.improved_stacks ~= nil then --����� ������ ������. ������ ������ �����������.
		--print("existing improved_stacks")
		join_fns = mods.improved_stacks.join_fns
		split_fns = mods.improved_stacks.split_fns --���������� ������������ �������.
		return
	end
	mods.improved_stacks = {join_fns=join_fns,split_fns=split_fns} --print("init mods.improved_stacks")
	local comp_it = require "components/inventoryitem"
	
	local old_DiluteMoisture = comp_it.DiluteMoisture
	function comp_it:DiluteMoisture(item, count,...) --item ����� ������ (������ �����, �� �� ����) ����� �����������.
		--print("Custom DiluteMoisture")
		if IS_ACTIVE and item.components.stackable ~= nil then
			local stack1,stack2 = self.inst.components.stackable.stacksize, item.components.stackable.stacksize --������� ������.
			local new_total = stack1 + stack2 --����� ������ �����
			for i,fn in ipairs(join_fns) do
				--print("Calling custom fn...")
				fn(self.inst,item,stack1,stack2,new_total) --���������� ��������.
			end
		end
		return old_DiluteMoisture(self,item, count,...)
	end
	
	
	local comp_stack = require "components/stackable"
	local old_Get = comp_stack.Get
	function comp_stack:Get(num,...) --item will be retured. And self.inst probably removed...
		--print("Custom Get")
		local item = old_Get(self,num,...) --��������� ���� ������ ��������. �������� ������ �� ���!
		if IS_ACTIVE and item ~= self.inst then --��� ������, ���� ���������� ���� ���� �������, ��� ����������.
			for i,fn in ipairs(split_fns) do
				--print("Calling custom fn...")
				fn(item,self.inst,item.components.stackable.stacksize,self.inst.components.stackable.stacksize) --������������ �������
			end
		end
		return item --� �������� ������.
	end
end

--fn: comgine(a,b,num_a,num_b,num_total)
--print("Declaring RegisterJoinStacksFn")
local function RegisterJoinStacksFn(fn)
	--print("RegisterJoinStacksFn")
	if mods.improved_stacks == nil then
		--print("improved_stacks == nil")
		ImproveStacks()
	end
	table.insert(join_fns,fn)
end

--fn: get(new,old,num,num_old).
local function RegisterSplitStacksFn(fn)
	if mods.improved_stacks == nil then
		ImproveStacks()
	end
	table.insert(split_fns,fn)
end


local q = {

initialized_by = modinfo.name,


world_init_fns = world_init_fns,
AddWorldPostInit = AddWorldPostInit,
GetGlobal=GetGlobal,
EmptyFunction=EmptyFunction,
TheSim=TheSim,
TheNet=TheNet,
require=require,
SpawnPrefab=SpawnPrefab,
p=p,
arr=arr,
SetSharedLootTable=SetSharedLootTable,
Vector3=Vector3,
SEASONS = SEASONS,
FUELTYPE = FUELTYPE,
ACTIONS = ACTIONS,
GetTime = GetTime,
clock = _G.os.clock,
AllPlayers = AllPlayers,
SaveOption = SaveOption,
LoadOption = LoadOption,
GetOption = GetOption,
RegisterPlayersUpdate = RegisterPlayersUpdate,
UnRegisterPlayersUpdate = UnRegisterPlayersUpdate,
data_players = data_players, --������ ������� � ����. ����� ��� ���� ������ ������.
_mods = _mods, --����, ����� ����������� ������ ���������� (������ �� ������������ ���� � ������� ��������������� �������)
static = static or {

}, --End of static functions



FindUpvalue = function(fn, upvalue_name, member_check, no_print)
	local info = _G.debug.getinfo(fn, "u")
	local nups = info and info.nups
	if not nups then return end
	local getupvalue = _G.debug.getupvalue
	local s = ''
	--print("FIND "..upvalue_name.."; nups = "..nups)
	for i = 1, nups do
		local name, val = getupvalue(fn, i)
		s = s .. "\t" .. name .. ": " .. type(val) .. "\n"
		if (name == upvalue_name)
			and ((not member_check) or (type(val)=="table" and val[member_check] ~= nil)) --�������� ��������
		then
			--print(s.."FOUND "..tostring(val))
			return val, true
		end
	end
	if no_print == nil then
		print("CRITICAL ERROR: Can't find variable "..tostring(upvalue_name).."!")
		print(s)
	end
end,


AddPlayersPostInit = AddPlayersPostInit,
AddPlayersAfterInit = AddPlayersAfterInit,

GetWatchWorldStateFn = GetWatchWorldStateFn,
GetListener = GetListener,
SaveTimers = SaveTimers,
GetLastTimer = GetLastTimer,
GetLastTimerFn = GetLastTimerFn,
AddHookOnLastTask = AddHookOnLastTask,
AddHookOnComponent = AddHookOnComponent,
GetTags = GetTags,
SearchForModsByName = SearchForModsByName,
AddIngredientValues = AddIngredientValues,
RegisterJoinStacksFn = RegisterJoinStacksFn,
RegisterSplitStacksFn = RegisterSplitStacksFn,
_libStopWorking = _libStopWorking, --����������� ��������� ������������� �����.



ExportLib = function(env)
	for k,v in pairs(mods.lib) do
		env[k]=v
	end
	table.insert(_mods,env) --���������� ������������ ���� ����
end,


} --����� ��������� q
q.q = q --������ �� ���� ����, ����� �������� ��������� ������������ ���� � ������ ����������.

if TheNet:GetIsServer() then
	q.SERVER_SIDE = true
	if TheNet:IsDedicated() then
		--������ ������������ GetServerIsDedicated, �.�. ��� ���� �������� � �������, � �� � ������� ������.
		--����... �� ����. ��� ����� �� �������� ����� GetIsServer.
		q.DEDICATED_SIDE = true
	else
		q.CLIENT_SIDE = true --� ��� ������������ ������� ������ �������� "ismastersim".
		--������� ������������ ������ ��� ������������� ������� ����������, �� �������� � "return" ������� �� �������!!
	end
elseif TheNet:GetIsClient() then
	q.SERVER_SIDE = false
	q.CLIENT_SIDE = true
	q.ONLY_CLIENT_SIDE = true
end


local old_OnSaveWorld
local old_OnLoadWorld
local function new_OnSaveWorld(...)
	local data = old_OnSaveWorld(...)
	data.data_players = w.data_players
    return data
end

function new_OnLoadWorld(self,data)
	if data.data_players then
		w.data_players = data.data_players
		data_players = data.data_players
	end
	return old_OnLoadWorld(self,data)
end



AddPrefabPostInit("world",function(inst)
	w=inst --��������� ������������� ���� (����� �������� ���-����� ���������).
	if IS_ACTIVE == nil then --���. ����� ������ ���� ���������� ����� ������ ������.
		return --��� ����� � ��������.
	end
	w.data_players = data_players --���� ������ ������� (������������ ������������� �������� ����).
	--��������� ����������� ����������/�������� ������ ������
	if inst.components.worldstate then
		if inst.components.worldstate.OnSave == old_OnSaveWorld then --������ �� ������, �.�. �� ����.
			print("ERROR: worldstate is already patched in the same lib module!")
			return
		end
		old_OnSaveWorld = inst.components.worldstate.OnSave
		old_OnLoadWorld = inst.components.worldstate.OnLoad
		inst.components.worldstate.OnSave = new_OnSaveWorld
		inst.components.worldstate.OnLoad = new_OnLoadWorld
	else
		print("ERROR: no worldstate in TheWorld")
		q.SaveOption = EmptyFunction
		q.LoadOption = EmptyFunction
	end
	for i,v in ipairs(_mods) do
		v.TheWorld = inst
		v.w = inst
		v.state = inst.state --TheWorld.state
		v.ww = v.state
	end
end)

mods.lib = q








