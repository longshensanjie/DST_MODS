local flymode = false
local ALLOWit = true
local last_recipe,last_skin,builder
local anims_nope = {"sink", "plank_hop", "xx", "xxx", "xxx_2"}
local anims_confined = {"frozen", "frozen_loop_pst", "distress", "distress_loop", "yawn", "dozy", "sleep_loop"}
local anims_build = {"build_pre", "build_loop"}
local anims_walk = {"run_pre", "idle_walk_pre"}

local function checkAnims(anims)
    for _,anim in pairs(anims) do
        if ThePlayer and ThePlayer.AnimState and ThePlayer.AnimState:IsCurrentAnimation(anim) then
            return true
        end
    end
	return false
end

local function SendSit()
    GLOBAL.TheNet:SendSlashCmdToServer("sit", true)
    ALLOWit = true
end

local IsCraft = false

local function TryCraft(check)   -- by Tony:Lazy Controls
    for recname, rec in pairs(AllRecipes) do
        if IsRecipeValid(recname)
            and recname ~= "armorgrass"
            and rec.placer == nil
            and rec.sg_state == nil
            and ThePlayer.replica.builder:KnowsRecipe(recname)
            and ThePlayer.replica.builder:CanBuild(recname) then
            if check then
                return true
            end
            if ThePlayer.components.builder then
                ThePlayer.components.builder:MakeRecipeFromMenu(rec)
            else
                ThePlayer.replica.builder:MakeRecipeFromMenu(rec)
            end
            return rec
        end
    end
end

local function monitorTask()
    if not flymode then return end
    if checkAnims(anims_nope) and ALLOWit then
        ALLOWit = false
        TryCraft()
    elseif not ALLOWit then
        SendSit()
    end
end

local function FindCanBeAttack(dis)
    -- body
    local pos = ThePlayer:GetPosition()
    local ents = TheSim:FindEntities(pos.x, 0, pos.z, dis, nil, {"DECOR", "FX", "INLIMBO", "NOCLICK", "player"})
    for _, ent in pairs(ents) do
        if ent and ent.replica.combat and ent.replica.combat.CanBeAttacked and ent.replica.combat:CanBeAttacked(ThePlayer) then
            return ent
        end
    end
end
local walk_flag = false
local attack_flag = false
local function RemoveControl()
    if not flymode then return end
    if checkAnims(anims_build) and IsCraft then
        -- 这里是给卡海打帝王蟹做了优化，如果在船上就会移动打断冰冻，海面上则不移动 用攻击队列打断
        if not ThePlayer:IsOnOcean(true) or (ThePlayer:GetCurrentPlatform() and ThePlayer:GetCurrentPlatform().prefab == "boat") then
            ThePlayer.components.playercontroller:RemoteDirectWalking(0.1, 0.1)
        else
            attack_flag = true
        end
        walk_flag = true
    end
    if checkAnims(anims_walk) and walk_flag or attack_flag then
        ThePlayer.components.playercontroller:RemoteStopWalking()
        IsCraft = false
        walk_flag = false   
        attack_flag = false 
    end
    if checkAnims(anims_confined) and not IsCraft then
        IsCraft = true
        TryCraft()
    end
end

local function IsSitAnim()
    for i = 1, 10 do
        anim = "emote_loop_sit".. i .. ""
        if ThePlayer and ThePlayer.AnimState and ThePlayer.AnimState:IsCurrentAnimation(anim) then
            return true
        end
    end
    return false
end

local function fn()
    if not InGame() then return end
    if GLOBAL.TheWorld:HasTag("cave") then
        GLOBAL.TheNet:SendSlashCmdToServer("rescue")
        return
    end
    local time_interval = 0.25
    if GLOBAL.TheInput:IsKeyDown(KEY_CTRL) then time_interval = 0.2 end
    -- if not (IsSitAnim() or ThePlayer:IsOnOcean(true)) then return end  -- 坐下表情时才能开启,禁止偷跑
    if not TryCraft(true) then TIP("卡海失败","red", "没有能搓的东西,请准备点材料") return end
    flymode = not flymode
    if looptask_swim then
        looptask_swim:Cancel()
        looptask_swim = nil
        looptask_free:Cancel()
        looptask_free = nil
    end                                        
    if flymode then
        SendRPCToServer(RPC.MovementPredictionEnabled)
        looptask_swim = ThePlayer:DoPeriodicTask(time_interval, monitorTask)  
        looptask_free = ThePlayer:DoPeriodicTask(FRAMES, RemoveControl)
    else                                                        
        SendRPCToServer(RPC.MovementPredictionDisabled)         
    end
    local say_str = time_interval == 0.25 and " 普通模式" or " 快速制作模式"
    if flymode then TIP("卡海启动", "yellow", "刷新间隔:".. time_interval .. say_str ..",上岸请关闭") 
    else TIP("卡海模式", "yellow", flymode) end
end

AddClassPostConstruct("components/builder_replica", function(self)
    local BuilderReplicaMakeRecipeFromMenu = self.MakeRecipeFromMenu
    self.MakeRecipeFromMenu = function(self, recipe, skin)
        last_recipe, last_skin = recipe, skin
        BuilderReplicaMakeRecipeFromMenu(self, recipe, skin)
    end
    local BuilderReplicaMakeRecipeAtPoint = self.MakeRecipeAtPoint
    self.MakeRecipeAtPoint = function(self, recipe, pt, rot, skin)
        last_recipe, last_skin = recipe, skin
        BuilderReplicaMakeRecipeAtPoint(self, recipe, pt, rot, skin)
    end
end)






if GetModConfigData("sw_wow") == "biubiu" then
    DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("balloonvest.tex"), "balloonvest.tex", "卡海", "卡海，每次上岸需重新启动", false, fn)
end
    
AddBindBtn("sw_wow", fn)