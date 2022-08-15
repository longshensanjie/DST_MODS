local _G = GLOBAL
local require = GLOBAL.require
local Vector3 = GLOBAL.Vector3
local GetInventoryItemAtlas = GLOBAL.GetInventoryItemAtlas
local FollowText = require "widgets/followtext"
local Image = require "widgets/image"
local setmetatable = _G.setmetatable
local getmetatable = _G.getmetatable
local rawset = _G.rawset
local rawget = _G.rawget

local ToolInfoAbled = true
local ToolMarkAbled = true
local ArrowColour = {255,255,255}

local Wgtstring = require "Wgtscripts/Wagstaff_tool_strings"
local requests = Wgtstring.requests
local removestr = Wgtstring.removestr
local DEFAULT_OFFSET = Vector3(0, -400, 0)


local function UpdateToolInfo(self, tool)
    local player = _G.ThePlayer

    if self.toolinfo == nil and player ~= nil and player.HUD ~= nil then
        self.toolinfo = player.HUD:AddChild(FollowText(self.font or _G.TALKINGFONT, self.fontsize or 35))
        self.toolinfo:SetHUD(player.HUD.inst)
        self.toolinfo.bg = self.toolinfo:AddChild(Image("images/hud.xml", "inv_slot.tex"))
        self.toolinfo.bg:SetScale(.2,.2,1)
        self.toolinfo.image = self.toolinfo:AddChild(Image())
        self.toolinfo.image:SetScale(.15,.15,1)
    end

    if self.toolinfo ~= nil then
        local offset = Vector3(0,150,0)
        self.toolinfo:SetOffset(self.offset_fn ~= nil and self.offset_fn(self.inst)-offset or self.offset-offset or DEFAULT_OFFSET-offset)
        self.toolinfo:SetTarget(self.inst)
    end

    if self.toolinfo.tool and self.toolinfo.tool ~= tool or not self.toolinfo.tool then
        self.toolinfo.tool = tool
        local name = tool..".tex"
        local atlas = "images/inventoryimages2.xml"
        self.toolinfo.image:SetTexture(atlas, name)
        self.toolinfo.bg:ScaleTo(.2, .75, .2)
        self.toolinfo.image:ScaleTo(.15, .6, .2)

        for k,v in pairs(self.wagstaff_tools) do
            --print("v.prefab=", v.prefab)
            if v.prefab == tool then
                local tint = v.toolmark.arrow.tint
                local from = {r = tint[1], g = tint[2], b = tint[3], a = tint[4]}
                local to = {r = 245/255, g = 86/255, b = 81/255, a = .7}
                v.toolmark.arrow:TintTo(from, to, .2)
                --print("将需要的工具颜色改变")
                break
            end
        end
    end

    if not self.toolinfo.shown then self.toolinfo:Show() end
end

local function onToolUnwanted(self)
    if not self.toolinfo then return end
    self.toolinfo.tool = nil
    self.toolinfo.bg:ScaleTo(.75, .2, .2)
    self.toolinfo.image:ScaleTo(.6, .15, .2, function()
        self.toolinfo:Kill()
        self.toolinfo = nil
    end)
end

local function modiwagstaff_npc(inst)
    --if _G.TheWorld.ismastersim then return end
    inst.components.talker.wagstaff_tools = {}
    local old_ontalkfn = inst.components.talker.ontalkfn
    inst.components.talker.ontalkfn = function(inst, data)
        if data.message and type(data.message) == "string" then
            --print("发明家说的话：", string.sub(data.message,1,10))
            for tool,strs in pairs(requests) do
                for k,v in pairs(strs) do
                    if data.message == v then
                        print("发明家需要：", tool)
                        UpdateToolInfo(inst.components.talker, tool)
                    end
                end
            end

            for _,strs in pairs(removestr) do
                for k,v in pairs(strs) do
                    if data.message == v then
                        onToolUnwanted(inst.components.talker)
                    end
                end
            end
        end

        if old_ontalkfn and type(old_ontalkfn) == "function" then
            old_ontalkfn(inst, data)
        end
    end
end

if ToolInfoAbled then
    AddPrefabPostInit("wagstaff_npc", modiwagstaff_npc)
end

local function ontoolmarkshow(self, fn)
    local tint = self.arrow.tint
    local from = {r = tint[1], g = tint[2], b = tint[3], a = 0}
    local to = {r = tint[1], g = tint[2], b = tint[3], a = .7}
    self.arrow:TintTo(from, to, .3, function()
        if fn and fn(type) == "function" then fn() end
    end)
    self:Show()
end

local function ontoolmarkhide(self, fn)
    local tint = self.arrow.tint
    local from = {r = tint[1], g = tint[2], b = tint[3], a = .7}
    local to = {r = tint[1], g = tint[2], b = tint[3], a = 0}
    self.arrow:TintTo(from, to, .3, function()
        self:Hide()
        if fn and fn(type) == "function" then fn() end
    end)
end

local function ontoolremove(inst)
    if inst.toolmark then
        inst.toolmark:onHide(function() inst.toolmark:Kill() end)
    end
    if inst.wagstaff and inst.wagstaff.components and inst.wagstaff.components.talker and inst.wagstaff.components.talker.wagstaff_tools then
        if inst.wagstaff.components.talker.wagstaff_tools[inst] then
            inst.wagstaff.components.talker.wagstaff_tools[inst] = nil
        end
    end
end

local function modiwagstaff_tool(inst)
    --if _G.TheWorld.ismastersim then return end
    local player = _G.ThePlayer
    if player ~= nil and player.HUD ~= nil then
        inst.toolmark = player.HUD:AddChild(FollowText(inst.font or _G.TALKINGFONT, inst.fontsize or 35))
        inst.toolmark:SetHUD(player.HUD.inst)
        local offset = Vector3(0,-220,0)
        inst.toolmark:SetOffset(DEFAULT_OFFSET-offset)
        inst.toolmark:SetTarget(inst)
        inst.toolmark.arrow = inst.toolmark:AddChild(Image("images/wgt_arrow.xml", "wgt_arrow.tex"))
        inst.toolmark.arrow:SetScale(.25,.25,1)
        inst.toolmark.arrow:SetTint(ArrowColour[1]/255, ArrowColour[2]/255, ArrowColour[3]/255,0)
        inst.toolmark.onShow = ontoolmarkshow
        inst.toolmark.onHide = ontoolmarkhide

        inst.toolmark:onShow()

        inst:DoPeriodicTask(2, function()
            local arrow = inst.toolmark.arrow
            local origin = Vector3(0,0,0)
            local diff = Vector3(0,-5,0)
            arrow:MoveTo(origin, diff, .4)
            inst:DoTaskInTime(.41, function() arrow:MoveTo(diff, origin, .3) end)
        end)

        inst:DoPeriodicTask(.2, function()
            local held = true
            if inst.replica and inst.replica.inventoryitem then held = inst.replica.inventoryitem:IsHeld() end
            --print(held)
            if held and inst.toolmark.shown then
                inst.toolmark:Hide()
            elseif not held and not inst.toolmark.shown then
                inst.toolmark:onShow()
            end
        end)

        inst:DoTaskInTime(.1, function()
            inst.wagstaff = _G.FindEntity(inst, 30, nil, {"wagstaff_npc"})
            --print("是否找到发明家：", inst.wagstaff)
            if inst.wagstaff and inst.wagstaff.components and inst.wagstaff.components.talker then
                --print("注册工具")
                inst.wagstaff.components.talker.wagstaff_tools[inst] = inst
                if inst.wagstaff.components.talker.toolinfo and inst.prefab == inst.wagstaff.components.talker.toolinfo.tool then
                    local tint = inst.toolmark.arrow.tint
                    local from = {r = tint[1], g = tint[2], b = tint[3], a = tint[4]}
                    local to = {r = 245/255, g = 86/255, b = 81/255, a = .7}
                    inst.toolmark.arrow:TintTo(from, to, .2)
                end
            end

            
            if inst.prefab then
                local id = inst.prefab:gsub('%D+', "")
                if id and tonumber(id) and GLOBAL.STRINGS and GLOBAL.STRINGS.NAMES then
                    GLOBAL.STRINGS.NAMES["WAGSTAFF_TOOL_"..id.."_LAYMAN"] = GLOBAL.STRINGS.NAMES["WAGSTAFF_TOOL_"..id]
                end
            end

        end)

        inst:ListenForEvent("onremove", ontoolremove)
    end
end

if ToolMarkAbled then
    for i = 1,5 do AddPrefabPostInit("wagstaff_tool_"..i, modiwagstaff_tool) end
end