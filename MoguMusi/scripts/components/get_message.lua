local Get_message = Class(function(self, inst)
    self.inst=inst

    self.bank=nil
    self.build=nil
    self.anim=nil
    self.zip=nil
    self.frame=nil
    self.facing=nil
    self.pos=nil
    self.scale=nil
    self.heading=nil

    self.userid=nil
    self.sg_current=nil
    self.last_action=nil
    self.last_action_name=nil

    self.rmb=nil
    self.rmb_name=nil
    self.lmb=nil
    self.lmb_name=nil

    self.tile=nil

    self.last_pos={}
    self.last_anim={}
    self.last_code={}
    --------------------------------------------------------物品
    self.item_prefab=nil
    self.item_zip=nil
    self.item_bank=nil
    self.item_build=nil
    self.item_anim=nil
    self.item_facing=nil
    self.item_pos=nil
    self.item_sg_cnt=nil

    self:OnLoad()
    inst:StartUpdatingComponent(self)
end)
function Get_message:Init()
    
end
function Get_message:Get_anim()
    if self.inst then
        local DebugString=self.inst.entity:GetDebugString()
        if DebugString then
            local bank,build,anim,zip,frame,facing=DebugString:match("bank: (.+) build: (.+) anim: ([^ .]+) anim/(.+).zip[^ .]+ Frame: (.+) Facing: ([^ .]+)\n")
            -- local pos,scale,heading=DebugString:match("Transform: Pos=(.+) Scale=(.+) Heading=([^ w]+)\n")
            local pos=DebugString:match("Transform: Pos=(.+) Scale")
            self.bank=bank or "?"
            self.build=build or "?"
            self.anim=anim or "?"
            self.frame=frame or "?"
            self.zip=zip or "?"
            self.facing=facing or "?"
            self.pos=pos or "?"
            -- self.scale=scale or "?"
            -- self.heading=heading or "?"
        end
    end
    if self.target then
        local DebugString=self.target.entity:GetDebugString()
        if DebugString then
            local bank,build,anim=DebugString:match("bank: (.+) build: (.+) anim: ([^ .]+)")
            -- local pos,scale,heading=DebugString:match("Transform: Pos=(.+) Scale=(.+) Heading=([^ w]+)\n")
            local zip,frame,facing=DebugString:match("anim/(.+).zip[^ .]+ Frame: (.+) Facing: ([^ .]+)\n")
            local pos=DebugString:match("Transform: Pos=(.+) Scale")
            self.item_prefab=self.target.prefab
            self.item_bank=bank or "?"
            self.item_build=build or "?"
            self.item_anim=anim or "?"
            self.item_frame=frame or "?"
            self.item_zip=zip or "?"
            self.item_facing=facing or "?"
            self.item_pos=pos or "?"
            -- self.scale=scale or "?"
            -- self.heading=heading or "?"
            -- print("物品信息为",DebugString,bank,build,anim,zip,frame,facing)
        end
    end
end
function Get_message:Get_sg()
    if self.inst then
        if self.inst.sg~=nil then
            self.sg_current=self.inst.sg.currentstate.name
        end
        if self.inst.components.playercontroller then
            local target=TheInput:GetHUDEntityUnderMouse() or nil
            local item
            if target and target.widget.parent then
                item = target.widget.parent.item
            end
            local tmp=self.inst:GetBufferedAction()
            local playeractionpicker=self.inst.components.playeractionpicker
            local playercontroller=self.inst.components.playercontroller
            local lmb, rmb = playeractionpicker:DoGetMouseActions()--or GetSceneActions(target, true)

        
            -- if item ~= nil and item.IsValid and item:IsValid() and item.replica.inventoryitem ~= nil then
            --     lmb, rmb = playeractionpicker:DoGetMouseActions(nil,item)--or GetSceneActions(target, true)
            -- end
            if item ~= nil and item.IsValid and item:IsValid() and item.replica.inventoryitem ~= nil then
                local actionpicker =self.inst.components.playeractionpicker
                local active_item = self.inst.replica.inventory:GetActiveItem()
                if active_item == nil then
                    local actions = actionpicker:GetInventoryActions(item,true)
                    if #actions > 0 then
                        rmb = actions[1]
                    end
                elseif active_item:IsValid() then
                    local actions = actionpicker:GetUseItemActions(item, active_item, true)
                    if #actions > 0 then
                        rmb = actions[1]
                    end
                end
            end
            -- return rmb
            self.lmb=nil
            self.lmb_name=nil
            self.rmb=nil
            self.rmb_name=nil
            for k,v in pairs(ACTIONS)do
                if tmp and (tmp.action==v or tmp==v) then
                    self.last_action=k
                    self.last_action_name=tmp:GetActionString()
                end
                if lmb and (lmb.action==v or lmb==v) then
                    self.lmb=k
                    self.lmb_name=lmb.GetActionString and lmb:GetActionString()
                end
                if rmb and (rmb.action==v or rmb==v) then
                    self.rmb=k
                    self.rmb_name=rmb.GetActionString and rmb:GetActionString()
                end
            end
        end
    end
    if self.target then
        if self.target.sg then
            local str=tostring(self.target.sg)
            self.item_sg_cnt=(str and str:match("state=\"([%w]+)\"")) or self.item_sg_cnt
        else
            self.item_sg_cnt="?"
        end
    end

end

function Get_message:Get_tile()
    local map = TheWorld.Map
    local lx,ly,lz=self.inst.Transform:GetWorldPosition()
    if lx then
        local tile = map:GetTileAtPoint(lx,ly,lz)
        for k,v in pairs(GROUND) do
            if v == tile then
                self.tile =k
                break
            end
        end
    end
end

function Get_message:Play_anim(bank,build,anim,symbol,swap_symbol,structure,equipment,player,isflower)
    table.insert(self.last_anim,1,{bank=bank,build=build,anim=anim,symbol=symbol,swap_symbol=swap_symbol})
    while #self.last_anim>=TUNING.MEMORY_BM_NUM do
        self.last_anim[#self.last_anim]=nil
    end
    self:OnSave()
    bank=bank:match("([%w_]+)")
    build=build:match("([%w_]+)")
    anim=anim:match("([%w_]+)")
    swap_symbol=swap_symbol:match("([%w_]+)")
    symbol=symbol:match("([%w_]+)")
    if equipment then
        if symbol=="swap_hat" then
            if isflower then
                self.inst.AnimState:OverrideSymbol("swap_hat", build or "swap_hat", swap_symbol or "swap_hat")
                self.inst.AnimState:Show("HAT")
                self.inst.AnimState:Show("HAIR_HAT")
                self.inst.AnimState:Hide("HAIR_NOHAT")
                self.inst.AnimState:Hide("HAIR")
    
                self.inst.AnimState:Hide("HEAD")
                self.inst.AnimState:Show("HEAD_HAT")
            else
                self.inst.AnimState:OverrideSymbol("swap_hat", build or "swap_hat", swap_symbol or "swap_hat")
                self.inst.AnimState:Show("HAT")
                self.inst.AnimState:Hide("HAIR_HAT")
                self.inst.AnimState:Show("HAIR_NOHAT")
                self.inst.AnimState:Show("HAIR")
        
                self.inst.AnimState:Show("HEAD")
                self.inst.AnimState:Hide("HEAD_HAT")
            end
        elseif symbol== "swap_object" then
            self.inst.AnimState:OverrideSymbol(symbol,build or "swap_object",swap_symbol or "swap_object")
            self.inst.AnimState:Show("ARM_carry")
            self.inst.AnimState:Hide("ARM_normal")
        elseif symbol=="swap_body" then
            self.inst.AnimState:OverrideSymbol(symbol, build or "swap_body",swap_symbol or"swap_body")
        else
            self.inst.AnimState:OverrideSymbol(symbol or "swap_body",build or "swap_body",swap_symbol or "swap_body")
        end
    elseif player then
        if self.inst.AnimState then
            self.inst.AnimState:PlayAnimation(anim or "spearjab",true)
            local strfn="if player and player.sg then player.sg:Stop() player:DoTaskInTime(player.AnimState:GetCurrentAnimationLength()*"..
                TUNING.ANIM_BM_LEN..",function () player.sg:Start() end) end"
            self:SendCommand(string.format(self:Get_master() .. strfn, self:GetCharacter(self.inst.userid)))
        end
    else
        local item=SpawnPrefab("rocks")
        if item and item.AnimState then
            item.AnimState:SetBank(bank or "frog")
            item.AnimState:SetBuild(build or "frog")
            item.AnimState:PlayAnimation(anim or "idle",true)
            local x, _, z =self.inst.Transform:GetWorldPosition()
            if item.Transform then
                item.Transform:SetPosition(x,0,z)
            end
            item.persists = false--不保存
            if item.components and item.components.inventoryitem ~= nil and item.components.inventoryitem.canbepickedup then
                item.components.inventoryitem.canbepickedup = false
                item._restorepickup = true
            end
            item.persists = false--不保存
        end
        
    end
    -- print("信息为:",bank,build,anim,symbol,structure,hand,player)
end

function Get_message:Play_code(prefab,num,type_code)
    if not num then
        num=1
    end
    if type(prefab)=="string" and type(num)=="number" then
        if type_code=="spawn:" then
            local strfn="c_give("..prefab..","..num..")"
            self:SendCommand(strfn)
        elseif type_code=="sound:" then
            if self.last_sound==prefab then
                TheFocalPoint.SoundEmitter:KillSound(prefab)
                self.last_sound=nil
            else
                TheFocalPoint.SoundEmitter:KillSound(self.last_sound or "2")
                self.last_sound=prefab
                TheFocalPoint.SoundEmitter:PlaySound(prefab,prefab,num)
            end

        end
    end
end

function Get_message:Run_code(str)
    if type(str)=="string" then
        table.insert(self.last_code,1,{str=str})
        self:OnSave()
        while #self.last_code>=TUNING.MEMORY_BM_NUM do
            self.last_code[#self.last_code]=nil
        end
        self:SendCommand(str)
    end
end

function Get_message:Get_master()
    return 'local player = %s if player == nil then UserToPlayer("'..self.inst.userid..'").components.talker:Say("'..STRINGS.BM_HELP.HINT.no_player..'") end '
end

function Get_message:GetCharacter(userid)
    return "UserToPlayer('" .. userid .. "')"
end

function Get_message:SendCommand(fnstr)
    local x, _, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
    local is_valid_time_to_use_remote = TheNet:GetIsClient() and TheNet:GetIsServerAdmin()
    if is_valid_time_to_use_remote then
        TheNet:SendRemoteExecute(fnstr, x, z)
    else
        ExecuteConsoleCommand(fnstr)
    end
end
function Get_message:Get_integral(num)
    if type(num)=="string" then
        num=tostring(num)
    end
    if type(num)=="number" then
        num=math.modf(num*10)/10
        return num
    end
    return 0
end
function Get_message:Transfer(userid,x,y,z)
    if type(x)=="number" and type(y)=="number" and type(z)=="number" then
        local lx,ly,lz=self.inst.Transform:GetWorldPosition()
        table.insert(self.last_pos,1,{x=self:Get_integral(lx),y=self:Get_integral(ly),z=self:Get_integral(lz)})
        while #self.last_pos>=TUNING.MEMORY_BM_NUM do
            self.last_pos[#self.last_pos]=nil
        end
        self:OnSave()
        local fnstr="if player then if player.Physics then player.Physics:Teleport("..x..","..y..","..z..") else player.Transform:SetPosition("..x..","..y..","..z..") end end"
        self:SendCommand(string.format(self:Get_master() .. fnstr, self:GetCharacter(userid)))
    else
        self.inst.components.talker:Say(STRINGS.BM_HELP.BUTTONS.transfer.transfer_error)
    end
end

function Get_message:SetCamera(dt)
    
end
function Get_message:OnUpdate(dt)
    local target=TheInput:GetWorldEntityUnderMouse()
    if not target then
        target=TheInput:GetHUDEntityUnderMouse()
        if target then
            target=target.widget.parent and target.widget.parent.item
        end
    end
    if target and target.entity and (target.HasTag and not target:HasTag("player")) then
        self.target=target
    end
    -- item = target.widget.parent.item
    self:Get_anim()
    self:Get_sg()
    self:Get_tile()
end
function Get_message:OnSave()
    self.ans={
        last_pos=self.last_pos,
        last_anim=self.last_anim,
        last_code=self.last_code
    }
    local str = json.encode(self.ans)
    TheSim:SetPersistentString("bm_tmp_data", str,true)
end
function Get_message:OnLoad()
    TheSim:GetPersistentString("bm_tmp_data",function(load_success, str)
        if load_success then
            if str ~= nil and string.len(str) > 0 then
                self.ans =json.decode(str)
                self.last_pos=(self.ans and self.ans.last_pos) or {}
                self.last_anim=(self.ans and self.ans.last_anim) or {}
                self.last_code=(self.ans and self.ans.last_code) or {}
            end
        end
    end)
end
return Get_message