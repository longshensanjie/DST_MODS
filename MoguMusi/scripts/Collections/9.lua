-- 转载请在介绍页署名原作者【冰汽】

local _G = GLOBAL
local SHOW_RANGE_TIME = 30

local justlist = {"firesuppressor", "winona_catapult", "lightning_rod",
 "oceantree", "oceantreenut", "oceantree_pillar", "winch", "underwater_salvageable",
  "watertree_pillar","eyeturret"}

local booklist = {"book_gardening","book_sleep","book_horticulture", "book_birds", "book_silviculture", "book_brimstone", "book_tentacles", "panflute", "orangestaff"}

local function Inlist(sth, thelist)
	for i,v in ipairs(thelist) do
		if sth == v then
			return true
		end
	end
	return false
end


local function MakeC(sth, R, c1, c2, c3)
	local C = _G.CreateEntity()
	local tf = C.entity:AddTransform()
	local as = C.entity:AddAnimState()
	as:SetAddColour(c1,c2,c3, 0)
	tf:SetScale(R, R, R)

	as:SetBank("firefighter_placement")
	as:SetBuild("firefighter_placement")
	as:PlayAnimation("idle")
	as:SetOrientation(_G.ANIM_ORIENTATION.OnGround)
	as:SetLayer(_G.LAYER_BACKGROUND)
	as:SetSortOrder(3)
	C.persists = false

	C.entity:SetParent(sth.entity)

	return C
end


-- https://www.sioe.cn/yingyong/yanse-rgb-16/
local function ShowRange(sth)
	local n = sth.prefab
	local c
	if (n == "firesuppressor") or (n == "winona_catapult") then
		c = MakeC(sth, 1.55, 0,0,255)			-- 灭火器要纯蓝
	elseif n == "lightning_rod" then
		c = MakeC(sth, 2.53, 255,255,0)			-- 避雷针要纯黄
	elseif n == "oceantree" then
		c = MakeC(sth, 1.72, 255, 0, 0)			-- 长一半就纯红
	elseif n == "watertree_pillar" then
		c = MakeC(sth, 2.13, 0,0,255)			-- 大榕树要纯绿
	elseif n == "eyeturret" then
		c = MakeC(sth, 1.72, 0,0,0)				-- 眼球炮台黑色
	else
		c = MakeC(sth, 1.89, 255, 255, 255)		-- 平时就白色吧
	end
	if SHOW_RANGE_TIME > 0 then
		c:DoTaskInTime(SHOW_RANGE_TIME, function() c:Remove() end)
	end
end

local function Easy(master, num)
	return MakeC(master, num, 255,255,255)
end


local function ShowBookRange(master, book)
	local n = book.prefab
	local c = nil
	if (n == "book_birds") then
		c = Easy(master, 1.380)
	elseif n == "book_tentacles" then
		c = Easy(master, 1.127)
	elseif n == "book_brimstone" then
		c = Easy(master, 1.523)
	elseif n == "panflute" then
		c = Easy(master, 1.55)
	elseif n == "orangestaff" then
		c = Easy(master, 2.4)
	else
		c = Easy(master, 2.182)
	end
	if c then
		c:DoTaskInTime(4, function() c:Remove() end)
	end
end




local controller = _G.require "components/playercontroller"
local Click = controller.OnLeftClick
	function controller:OnLeftClick(down,...)
		if (not down) and self:UsingMouse() and self:IsEnabled() and not _G.TheInput:GetHUDEntityUnderMouse() then
			local item = _G.TheInput:GetWorldEntityUnderMouse()
			if item then
				if Inlist(item.prefab, justlist) then
					ShowRange(item)
				end
			end
		end
		return Click(self,down,...)
	end


local function IceFlingOnRemove(inst)
	local pos = _G.Point(inst.Transform:GetWorldPosition())
	local range_indicators = _G.TheSim:FindEntities(pos.x,pos.y,pos.z, 2, {"range_indicator"})
	for i,v in ipairs(range_indicators) do
		if v:IsValid() then
			v:Remove()
		end
	end
end

local function IceFlingOnShow(inst)
	local pos = _G.Point(inst.Transform:GetWorldPosition())
	local range_indicators_client = TheSim:FindEntities(pos.x,pos.y,pos.z, 2, {"range_indicator"})
	if #range_indicators_client < 1 then
		local range = _G.SpawnPrefab("range_indicator")
		range.Transform:SetPosition(pos.x, pos.y, pos.z)
	end
end

local function IceFlingPostInit(inst)
	inst:ListenForEvent("onremove", IceFlingOnRemove)
end

local function GetItemSlot(item)
    if not _G.ThePlayer and _G.ThePlayer.replica.inventory then return end
    for container,v in pairs(_G.ThePlayer.replica.inventory:GetOpenContainers()) do
        if container and container.replica and container.replica.container and container:HasTag("backpack") then
            local items_container = container.replica.container:GetItems()
            for k,v in pairs(items_container) do
                if v.prefab == item then
                    return container.replica.container
                end
            end
        end
    end
    for k,v in pairs(_G.ThePlayer.replica.inventory:GetItems()) do
        if v.prefab == item then
            return _G.ThePlayer.replica.inventory
        end
    end
end



-- 对这些prefab监听点击
for i,v in ipairs(justlist) do
	AddPrefabPostInit(v, IceFlingPostInit)
end

-- 对悬停物品监听
AddClassPostConstruct("widgets/hoverer", function(self)
	local showstring = self.text.SetString
	self.text.SetString = function(text, str)
		local target = _G.TheInput:GetHUDEntityUnderMouse()
		if target ~= nil then
			target = target.widget ~= nil and target.widget.parent ~= nil and target.widget.parent.item
		else
			target = _G.TheInput:GetWorldEntityUnderMouse()
		end
		if target and target.GUID and Inlist(target.prefab, booklist) then
			if GetItemSlot(target.prefab) then
				ShowBookRange(_G.ThePlayer, target)
			else
				ShowBookRange(target, target)
			end
		end
		return showstring(text, str)
	end

end)