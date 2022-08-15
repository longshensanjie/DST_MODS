if GetModConfigData("sw_debugger") == "shutup" then
    return
end
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})--GLOBAL 相关照抄
TUNING.MEMORY_BM_NUM=30
TUNING.ANIM_BM_LEN=3
TUNING.KEY_BM_HELP= GetModConfigData("sw_OBC") and GetModConfigData("OBC_SWITCH_KEY_1") or 111
TUNING.BM_ALLOW=true

local str= ""
STRINGS.BM_HELP={}
STRINGS.BM_HELP.BUTTONS={
    shield={
        close_tip="关闭",
    },
    transfer={
        text="[传送]    ".."\n".."[视野]    ".."\n".."[动画]    ",
        tip="设定传送位置\n改变你的视野",
        close_tip="关闭",
        transfer_button="传送",
        transfer_error="输入错误",
        transfer_undo="上一个记录",
        transfer_undo_left="前一个记录",
        transfer_undo_right="后一个记录",
        right="+1",
        left="-1",
        clean="恢复默认视角",
        updtate="持续更新视角",
        transfer_360="旋转",
        transfer_360_tip="视角360度旋转",
        transfer_360_stop="停止",
        tgtpos=str.."设定鼠标目标",
        structure="地面:",
        hand="装备:",
        player="人物:",
        flower="隐藏头发:"
    },
    mouse_item={
        text="鼠标下prefab的信息"
    },
    item={
        close_tip="关闭"
    },
    code={
        text="[代码]    ",
        tip="执行代码",
        spawn="生成",
        spawn_num="数量:",
        sound="播放",
        sound_volume="音量:",
    }
}
STRINGS.BM_HELP.HINT={
    no_player="无法获取当前玩家"
}
AddPlayerPostInit(function (inst)
    inst:DoTaskInTime(0,function (inst)
        inst:AddComponent("get_message")
    end)

end)
local function InGame()
    return ThePlayer and ThePlayer.HUD and not ThePlayer.HUD:HasInputFocus()
end
--因为忘记把textedit放在screens里面，导致只能用这种蠢法子来屏蔽按钮的事件
local keys = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","W","X","Y","Z","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"}
local keylist = {}
local string = ""
for i = 1, #keys do
    keylist[GLOBAL["KEY_"..keys[i]]] = true
end
local old_input=TheInput.OnRawKey
TheInput.OnRawKey=function (self,key,down)
    if TUNING.BM_ALLOW or not keylist[key] then
        old_input(self,key,down)
    end
end

local Bm_menu=require("widgets/help_bm")
AddClassPostConstruct("widgets/controls", function (self)
    local function whatever()
        if InGame() then
            if self.Bm_menu_show then
                self.Bm_menu:Hide()
                self.Bm_menu.shield:Hide()
                self.Bm_menu_show=false
            else
                self.Bm_menu:Show()
                self.Bm_menu.shield:Show()
                self.Bm_menu_show=true
            end
        end
    end
    self.owner:DoTaskInTime(0.5,function ()
        if self.owner and self.owner:HasTag("player") then
            self.Bm_menu=self:AddChild(Bm_menu(self.owner))
            self.Bm_menu_show=false
            self.Bm_menu:Hide()
            self.Bm_menu:MoveToBack()
            -- TheInput:AddKeyUpHandler(TUNING.KEY_BM_HELP, function ()
            --     local target=TheInput:GetWorldEntityUnderMouse() or nil
            --     if target and target:IsValid() then
            --         self.Bm_menu:SetTarget(target)
            --     end
            -- end)
        end
    end)
    DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("cartographydesk.tex"), "cartographydesk.tex", "调试菜单", "查看实体代码贴图（更换角色后该功能失灵【标记：待修复】）", true, whatever)
end)