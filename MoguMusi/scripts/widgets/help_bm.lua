local Image = require "widgets/image"
local Text = require "widgets/text"
local TextEdit = require "widgets/textedit"
local TextButton = require "widgets/textbutton"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local PopupDialogScreen = require "screens/redux/popupdialog"
local dictionary_bm=require "dictionary_bm"

local STRING_MAX_LENGTH = 254

local Bm_menu = Class(Widget, function(self, owner)
    Widget._ctor(self, "Bm_menu")
    self.owner = owner
    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetPosition(0, 0, 0)--设置位置

    self.fontsize=20

    self.offset_x=5
    --对不齐的太难看了，只能一个个分开才能左对其
    self.list={
        [1]={userid="userid:   "},
        [2]={zip="zip:        "},
        [3]={bank="bank:     "},
        [4]={build="build:    "},
        [5]={anim="anim:     "},
        [6]={frame="frame:    "},
        [7]={facing="facing:   "},
        [8]={pos="pos:       "},
        [9]={sg_cnt="sg_cnt:   "},
        [10]={last_act="last_act: "},
        [11]={lmb="lmb:       "},
        [12]={rmb="rmb:       "},
        [13]={tile="tile:        "},
    }
    self.camera_list={
        {fov=35},
        -- {pangain=4},
        -- {headinggain=20},
        -- {distancegain=1},
        -- {zoomstep=4},
        -- {distance=30},
        {disttarget=30},
        -- {mindist=15},--默认固定
        -- {maxdist=50},

        -- {mindistpitch=30},
        {pitch=45},
        -- {maxdistpitch=60},

        {hgtarget=45},
        {heading=45},
-- hding
        -- {currentpos=Vector3(0,0,0)},
        --tgtpos
        {targetpos=STRINGS.BM_HELP.BUTTONS.transfer.tgtpos},
        -- {controll=1},
        {paused=0},
        {cutscene=0},
    }
    self.anim_list={
        {"bank:",STRINGS.BM_HELP.BUTTONS.transfer.structure},
        {"build:",STRINGS.BM_HELP.BUTTONS.transfer.hand},
        {"anim:",STRINGS.BM_HELP.BUTTONS.transfer.player},
        {"symb:"},
        {"swap_symbol:"}
    }
    self.anim_type={

    }
    self.colour={0.9, 0.8, 0.6, 1}
    self:Init()
    self:message_player()--玩家相关信息
    self:transfer_player()--传送和视野设置
    self:item_player()
    self:StartUpdating()
end)
function Bm_menu:Init()
    self.shieldpos_x = -400
    self.shieldpos_y = 50
    self.shieldsize_x = 300
    self.shieldsize_y = self.shieldsize_x*1.618
    --第一个黑框
    self.shield = self.root:AddChild(Image("images/ui.xml", "black.tex"))
    self.shield:SetScale(1, 1, 1)
    self.shield:SetPosition(self.shieldpos_x, self.shieldpos_y, 0)
    self.shield:SetSize(self.shieldsize_x, self.shieldsize_y)
    self.shield:SetTint(1, 1, 1, 0.4)

    local close_scale=0.7
    self.shield_close=self.shield:AddChild(ImageButton("images/global_redux.xml","close.tex"))
    self.shield_close:SetScale(close_scale,close_scale,close_scale)
    self.shield_close:SetPosition(125,-220,0)
    self.shield_close:SetOnClick(function() self:ShowShieldMenu() end)
    self.shield_close:SetTooltip(STRINGS.BM_HELP.BUTTONS.shield.close_tip)

    self.shield_show=true
    self.shield:Show()
    --第二个黑框
    self.itemsize_x=self.shieldsize_x*1.5
    self.itemsize_y = self.shieldsize_y
    self.itempos_x=self.shieldsize_x/2+self.itemsize_x/2+self.shieldpos_x
    self.itempos_y=self.shieldpos_y
    self.item=self.root:AddChild(Image("images/ui.xml","black.tex"))
    self.item:SetScale(1, 1, 1)
    self.item:SetPosition(self.itempos_x, self.itempos_y, 0)
    self.item:SetSize(self.itemsize_x, self.itemsize_y)
    self.item:SetTint(1, 1, 1, 0.6)
    self.item_show=false
    self.item:Hide()
    --关闭按钮
    close_scale=0.7
    self.item_close=self.item:AddChild(ImageButton("images/global_redux.xml","close.tex"))
    self.item_close:SetScale(close_scale,close_scale,close_scale)
    self.item_close:SetPosition(200,-220,0)
    self.item_close:SetOnClick(function() self:ShowItemMenu() end)
    self.item_close:SetTooltip(STRINGS.BM_HELP.BUTTONS.item.close_tip)
    --第三黑框
    self.transfersize_x = self.shieldsize_x
    self.transfersize_y = self.shieldsize_y
    self.transferpos_x=self.itemsize_x/2+self.transfersize_x/2+self.itempos_x
    self.transferpos_y=self.shieldpos_y
    self.transfer = self.root:AddChild(Image("images/ui.xml","black.tex"))
    self.transfer:SetScale(1,1,1)
    self.transfer:SetPosition(self.transferpos_x, self.transferpos_y, 0)
    self.transfer:SetSize(self.transfersize_x, self.transfersize_y)
    self.transfer:SetTint(1, 1, 1, 0.4)
    --关闭按钮
    self.transfer_close=self.transfer:AddChild(ImageButton("images/global_redux.xml","close.tex"))
    self.transfer_close:SetScale(close_scale,close_scale,close_scale)
    self.transfer_close:SetPosition(125,-220,0)
    self.transfer_close:SetOnClick(function() self:ShowTransferMenu() end)
    self.transfer_close:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.close_tip)

    self.transfer_show=false
    self.transfer:Hide()
end
--玩家动画相关信息
function Bm_menu:message_player()
    self.player=self.shield:AddChild(Widget("ThePlayer"))
    self.player:SetPosition(-50,120, 0)

    self.player_x,self.player_y=-100,220
    self.player_x_offest,self.player_y_offset=80,-20
    for _,i in ipairs(self.list)do
        for k,v in pairs(i)do
            self.player[k]=self.shield:AddChild(Text(DEFAULTFONT,self.fontsize))
            self.player[k.."tmp"]=self.shield:AddChild(Text(DEFAULTFONT,self.fontsize))
            self.player[k]:SetPosition(self.player_x,self.player_y, 0)
            self.player[k]:SetString(v)
            self.player[k.."tmp"]:SetPosition(self.player_x+self.player_x_offest,self.player_y, 0)
            self.player_y=self.player_y+self.player_y_offset
        end
    end

    self.player_y=190
    self.player_x=100
    self.player.transfer = self.shield:AddChild(TextButton())
    self.player.transfer:SetFont(BODYTEXTFONT)
    self.player.transfer:SetTextSize(self.fontsize+5)
    self.player.transfer:SetColour(self.colour[1],self.colour[2],self.colour[3],self.colour[4])
    self.player.transfer:SetText(STRINGS.BM_HELP.BUTTONS.transfer.text)
    self.player.transfer:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.tip)
    self.player.transfer:SetPosition(self.player_x,self.player_y,0)
    -- self.player_y=self.player_y+self.player_y_offset
    self.player.transfer:SetOnClick(function() self:ShowTransferMenu() end)

    self.player_x,self.player_y=100,130
    self.player.code = self.shield:AddChild(TextButton())
    self.player.code:SetFont(BODYTEXTFONT)
    self.player.code:SetTextSize(self.fontsize+5)
    self.player.code:SetColour(self.colour[1],self.colour[2],self.colour[3],self.colour[4])
    self.player.code:SetText(STRINGS.BM_HELP.BUTTONS.code.text)
    self.player.code:SetTooltip(STRINGS.BM_HELP.BUTTONS.code.tip)
    self.player.code:SetPosition(self.player_x,self.player_y,0)
    -- self.player_y=self.player_y+self.player_y_offset
    self.player.code:SetOnClick(function() self:ShowItemMenu() end)


    local pos_x,pos_y=-100,-40
    self.player_boundary=self.shield:AddChild(Image())
    self.player_boundary:SetTexture("images/frontend_redux.xml", "achievements_wide_divider_bottom.tex" )
    self.player_boundary:SetPosition(0, pos_y, 0 )
    self.player_boundary:SetScale(0.3,0.3,0.3)

    pos_x,pos_y=-100,pos_y-20

    self.mouse_item=self.shield:AddChild(Text(DEFAULTFONT,self.fontsize))
    self.mouse_item:SetPosition(pos_x+30,pos_y,0)
    self.mouse_item:SetString(STRINGS.BM_HELP.BUTTONS.mouse_item.text)

    pos_x,pos_y=-100,pos_y-25
    local posx_offset,posy_offset=80,-20
    self.mouse_item_list={
        {prefab="prefab:   "},
        {zip="zip:        "},
        {bank="bank:     "},
        {build="build:    "},
        {anim="anim:     "},
        {facing="facing:   "},
        {pos="pos:       "},
        {sg_cnt="sg_cnt:   "},
    }

    for _,i in ipairs(self.mouse_item_list)do
        for k,v in pairs(i)do
            self.player["mouse_item"..k]=self.shield:AddChild(Text(DEFAULTFONT,self.fontsize))
            self.player["mouse_item"..k.."tmp"]=self.shield:AddChild(Text(DEFAULTFONT,self.fontsize))
            self.player["mouse_item"..k]:SetPosition(pos_x,pos_y, 0)
            self.player["mouse_item"..k]:SetString(v)
            self.player["mouse_item"..k.."tmp"]:SetPosition(pos_x+posx_offset,pos_y, 0)
            pos_y=pos_y+posy_offset
        end
    end

end

function Bm_menu:update_player()
    if self.owner.components.get_message then
        local message=self.owner.components.get_message
        local list={
            userid=self.owner.userid,
            zip=message.zip  or "?",
            bank=message.bank  or "?",
            build=message.build  or "?",
            anim=message.anim  or "?",
            frame=message.frame  or "?",
            facing=message.facing  or "?",
            pos=message.pos  or "?",
            sg_cnt=message.sg_current or "?",
            last_act=message.last_action or "?",
            rmb=(message.rmb or "?").."-"..(message.rmb_name or "?"),
            lmb=(message.lmb or "?").."-"..(message.lmb_name or "?"),
            rmb_name=message.rmb_name or "?",
            lmb_name=message.lmb_name or "?",
            tile=message.tile or "?"
        }
        for _,i in pairs(self.list)do
            for k,v in pairs(i)do
                self.player[k.."tmp"]:SetString(list[k])
            end
        end

        local item_list={
            prefab=message.item_prefab or "?",
            zip=message.item_zip  or "?",
            bank=message.item_bank  or "?",
            build=message.item_build  or "?",
            anim=message.item_anim  or "?",
            facing=message.item_facing  or "?",
            pos=message.item_pos  or "?",
            sg_cnt=message.item_sg_cnt or "?",
        }

        for _,i in pairs(self.mouse_item_list)do
            for k,v in pairs(i)do
                self.player["mouse_item"..k.."tmp"]:SetString(item_list[k])
            end
        end
    end
end
--玩家传送
function Bm_menu:transfer_player()

    -- self.player.transfer2 = self.shield:AddChild(TextButton())
    -- self.player.transfer2:SetFont(BODYTEXTFONT)
    -- self.player.transfer2:SetTextSize(self.fontsize+5)
    -- self.player.transfer2:SetColour(self.colour[1],self.colour[2],self.colour[3],self.colour[4])
    -- self.player.transfer2:SetText(STRINGS.BM_HELP.BUTTONS.transfer.text2)
    -- self.player.transfer2:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.tip2)
    -- self.player.transfer2:SetPosition(self.player_x,self.player_y,0)
    -- -- self.player_y=self.player_y+self.player_y_offset
    -- self.player.transfer2:SetOnClick(function() self:ShowTransferMenu() end)

    local pos_x,pos_y=-100,200
    local posx_offset,posy_offset=70,0
    local pos_message={
        [1]={x={"images/textboxes.xml", "textbox3_gold_tiny_normal.tex", "textbox3_gold_tiny_hover.tex", "textbox3_gold_tiny_focus.tex"},},
        [2]={y={"images/textboxes.xml", "textbox3_gold_tiny_normal.tex", "textbox3_gold_tiny_hover.tex", "textbox3_gold_tiny_focus.tex"},},
        [3]={z={"images/textboxes.xml", "textbox3_gold_tiny_normal.tex", "textbox3_gold_tiny_hover.tex", "textbox3_gold_tiny_focus.tex"},}
    }
    for _,value in ipairs(pos_message)do
        for k,v in pairs(value)do
            self["edit_text_bg"..k] = self.transfer:AddChild( Image() )
            self["edit_text_bg"..k]:SetTexture("images/textboxes.xml", "textbox3_gold_tiny_normal.tex" )
            self["edit_text_bg"..k]:SetPosition(pos_x, pos_y, 0 )
            self["edit_text_bg"..k]:ScaleToSize(60, 25)
    
            self["text_bg"..k]=self.transfer:AddChild(Text(DEFAULTFONT,self.fontsize+5))
            
            self["text_bg"..k]:SetPosition(pos_x,pos_y+30, 0)
            self["text_bg"..k]:SetString(k)
    
            --self[...]:SetString(str)
            --GetString
            self["edit_text"..k] = self.transfer:AddChild(TextEdit(NEWFONT_SMALL, 20, "" ))
            self["edit_text"..k]:SetCharacterFilter("-0123456789.")
            self["edit_text"..k]:SetIdleTextColour(139/255,105/255,20/255,1)
            self["edit_text"..k]:SetPosition(pos_x+2, pos_y, 0 )
            self["edit_text"..k]:SetRegionSize(50,40)
            self["edit_text"..k]:SetHAlign(ANCHOR_LEFT)
            self["edit_text"..k]:SetFocusedImage(self["edit_text_bg"..k], v[1], v[2],v[3],v[4])
            self["edit_text"..k]:SetTextLengthLimit(6)
            self["edit_text"..k]:SetForceEdit(true)

            self["edit_text"..k]:SetString("0")

            self:Push_TextEdit(self["edit_text"..k])--用于屏蔽动作
            pos_x=pos_x+posx_offset
        end
    end


    self.transfer_button=self.transfer:AddChild(ImageButton("images/global_redux.xml","value_gold.tex"))
    self.transfer_button:SetScale(0.75,0.75,1)
    self.transfer_button:SetPosition(pos_x,pos_y-5,0)
    self.transfer_button:SetOnClick(function()
        if self.owner.components.get_message then
            self.last_tarnsfer_num=1
            self.transfer_undo_right_offset=0
            self.transfer_undo_left_offset=0
            local x,y,z=self["edit_textx"]:GetString() or 0,self["edit_texty"]:GetString() or 0,self["edit_textz"]:GetString() or 0
            self.owner.components.get_message:Transfer(self.owner.userid,tonumber(x),tonumber(y),tonumber(z))
        end
    end)
    self.transfer_button:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.transfer_button)
    self.transfer_button_text=self.transfer_button:AddChild(Text(NUMBERFONT,self.fontsize+10))
    self.transfer_button_text:SetString(STRINGS.BM_HELP.BUTTONS.transfer.transfer_button)
    self.last_tarnsfer_num=1
    self.transfer_undo_right_offset=0
    self.transfer_undo_left_offset=0
    -- self.transfer_undo=self.transfer:AddChild(ImageButton("images/button_icons.xml","undo.tex"))
    -- self.transfer_undo:SetScale(0.12,0.12,1)
    -- self.transfer_undo:SetPosition(pos_x,pos_y+25,0)
    -- self.transfer_undo:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.transfer_undo)
    -- self.transfer_undo:SetOnClick(function()
    --     if self.owner.components.get_message and self.owner.components.get_message.last_pos then
    --         local pos=self.owner.components.get_message.last_pos[self.last_tarnsfer_num]
    --         if pos then
    --             self["edit_textx"]:SetString(pos.x)
    --             self["edit_texty"]:SetString(pos.y)
    --             self["edit_textz"]:SetString(pos.z)
    --             self.last_tarnsfer_num=self.last_tarnsfer_num+1
    --         end
    --     end
    -- end)
    self.transfer_undo_left=self.transfer:AddChild(ImageButton("images/global_redux.xml","arrow2_left.tex","arrow2_left_over.tex","arrow_left_disabled.tex","arrow2_left_down.tex"))
    self.transfer_undo_left:SetScale(0.3,0.3,1)
    self.transfer_undo_left:SetPosition(pos_x-10,pos_y+25,0)
    self.transfer_undo_left:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.transfer_undo_left)
    self.transfer_undo_left:SetOnClick(function()
        if self.owner.components.get_message and self.owner.components.get_message.last_pos then
            local num=#self.owner.components.get_message.last_pos
            self.last_tarnsfer_num=math.min(self.last_tarnsfer_num+self.transfer_undo_left_offset,num)
            -- print("左",self.last_tarnsfer_num,#self.owner.components.get_message.last_pos)
            local pos=self.owner.components.get_message.last_pos[self.last_tarnsfer_num]
            if pos then
                self["edit_textx"]:SetString(pos.x)
                self["edit_texty"]:SetString(pos.y)
                self["edit_textz"]:SetString(pos.z)
                self.last_tarnsfer_num=math.min(self.last_tarnsfer_num+1,num)
                self.transfer_undo_left_offset=0
                self.transfer_undo_right_offset=-2
                if self.last_tarnsfer_num==num then
                    self.transfer_undo_right_offset=-1
                end
            end
        end
    end)

    self.transfer_undo_right=self.transfer:AddChild(ImageButton("images/global_redux.xml","arrow2_right.tex","arrow2_right_over.tex","arrow_right_disabled.tex","arrow2_right_down.tex"))
    self.transfer_undo_right:SetScale(0.3,0.3,1)
    self.transfer_undo_right:SetPosition(pos_x+10,pos_y+25,0)
    self.transfer_undo_right:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.transfer_undo_right)
    self.transfer_undo_right:SetOnClick(function()
        if self.owner.components.get_message and self.owner.components.get_message.last_pos then
            self.last_tarnsfer_num=math.max(self.last_tarnsfer_num+self.transfer_undo_right_offset,1)
            -- print("右",self.last_tarnsfer_num,#self.owner.components.get_message.last_pos)
            local pos=self.owner.components.get_message.last_pos[self.last_tarnsfer_num]
            if pos then
                self["edit_textx"]:SetString(pos.x)
                self["edit_texty"]:SetString(pos.y)
                self["edit_textz"]:SetString(pos.z)
                self.last_tarnsfer_num=math.max(self.last_tarnsfer_num-1,1)
                self.transfer_undo_right_offset=0
                self.transfer_undo_left_offset=2
                if self.last_tarnsfer_num==1 then
                    self.transfer_undo_left_offset=1
                end
            end
        end
    end)
    self.transfer_undo_right.onclick()
    ---------------------------------------------------------------------传送部分完成
    pos_x,pos_y=-100,170
    self.transfer_boundary=self.transfer:AddChild(Image())
    self.transfer_boundary:SetTexture("images/frontend_redux.xml", "achievements_wide_divider_bottom.tex" )
    self.transfer_boundary:SetPosition(0, pos_y, 0 )
    self.transfer_boundary:SetScale(0.3,0.3,0.3)

    pos_x,pos_y=-100,130
    posx_offset,posy_offset=100,0
    pos_message={"images/textboxes.xml", "textbox3_gold_tiny_normal.tex", "textbox3_gold_tiny_hover.tex", "textbox3_gold_tiny_focus.tex"}
    local n=0
    for _,value in ipairs(self.camera_list)do
        for k,v in pairs(value)do
            self["edit_text_bg"..k] = self.transfer:AddChild( Image() )
            self["edit_text_bg"..k]:SetTexture("images/textboxes.xml", "textbox3_gold_tiny_normal.tex" )
            self["edit_text_bg"..k]:SetPosition(pos_x, pos_y, 0 )
            self["edit_text_bg"..k]:ScaleToSize(60, 25)
    
            self["text_bg"..k]=self.transfer:AddChild(Text(DEFAULTFONT,self.fontsize))
            self["text_bg"..k]:SetPosition(pos_x,pos_y+25, 0)
            self["text_bg"..k]:SetString(k)
    
            --self[...]:SetString(str)
            --GetString
            self["edit_text"..k] = self.transfer:AddChild(TextEdit(NEWFONT_SMALL, 20, "" ))
            self["edit_text"..k]:SetCharacterFilter("-0123456789.")
            self["edit_text"..k]:SetIdleTextColour(139/255,105/255,20/255,1)
            self["edit_text"..k]:SetPosition(pos_x+2, pos_y, 0 )
            self["edit_text"..k]:SetRegionSize(50,40)
            self["edit_text"..k]:SetHAlign(ANCHOR_LEFT)
            self["edit_text"..k]:SetFocusedImage(self["edit_text_bg"..k], pos_message[1], pos_message[2],pos_message[3],pos_message[4])
            self["edit_text"..k]:SetTextLengthLimit(6)
            self["edit_text"..k]:SetForceEdit(true)
            --------------------------------------------------忘记改成屏幕了，就这样吧
            self:Push_TextEdit(self["edit_text"..k])--用于屏蔽动作

            if k~="targetpos" then
                self["edit_text"..k].left=self["edit_text"..k]:AddChild(ImageButton("images/global_redux.xml","arrow2_left.tex"))
                self["edit_text"..k].left:SetScale(0.3,0.3,1)
                self["edit_text"..k].left:SetPosition(-40,0,0)
                self["edit_text"..k].left:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.left)
                self["edit_text"..k].left:SetOnClick(function()
                    local num=self["edit_text"..k]:GetString()
                    num=tonumber(num)
                    if type(num)=="number" then
                        num=num-1
                        self["edit_text"..k]:SetString(tostring(num))
                    end
                end)
    
                self["edit_text"..k].right=self["edit_text"..k]:AddChild(ImageButton("images/global_redux.xml","arrow2_right.tex"))
                self["edit_text"..k].right:SetScale(0.3,0.3,1)
                self["edit_text"..k].right:SetPosition(35,0,0)
                self["edit_text"..k].right:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.right)
                self["edit_text"..k].right:SetOnClick(function()
                    local num=self["edit_text"..k]:GetString()
                    num=tonumber(num) or 0
                    if type(num)=="number" then
                        num=(num+1)
                        self["edit_text"..k]:SetString(tostring(num))
                    end
                end)
            else
                self["edit_text_bg"..k]:ScaleToSize(100, 25)
                self["edit_text"..k]:SetCharacterFilter("()-0123456789.")
                self["edit_text"..k]:SetRegionSize(90,40)
                self["edit_text"..k]:SetTextLengthLimit(20)
            end
            self["edit_text"..k]:SetString(tostring(v))
            pos_x=pos_x+posx_offset
            n=n+1
            if n%3==0 then
                pos_x=-100
                pos_y=pos_y-50
            end
        end
    end
    self.transfer_default=self.transfer:AddChild(ImageButton("images/button_icons.xml","clean_all.tex"))
    self.transfer_default:SetScale(0.11,0.11,1)
    self.transfer_default:SetPosition(pos_x-35,pos_y,0)
    self.transfer_default:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.clean)
    self.transfer_default:SetOnClick(function()
        self.camera_update=false
        TheCamera.controllable=true
        TheCamera.target=self.owner
        self:update_transfer(true)
        TheCamera:SetDefault()
        -- self:update_transfer(true)
        self.transfer_update:SetTextures("images/global_redux.xml","checkbox_normal.tex","checkbox_focus.tex")
        self.transfer_360:SetText(STRINGS.BM_HELP.BUTTONS.transfer.transfer_360)
        self.transfer_360_update=false
    end)
    self.transfer_update=self.transfer:AddChild(ImageButton("images/global_redux.xml","checkbox_normal.tex","checkbox_focus.tex"))
    self.transfer_update:SetScale(1,1,1)
    self.transfer_update:SetPosition(pos_x-5,pos_y,0)
    self.transfer_update:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.updtate)
    self.transfer_update:SetOnClick(function()
        if not self.camera_update then
            self:update_transfer(true)
            self.camera_update=true
            TheCamera.controllable=false
            self.transfer_update:SetTextures("images/global_redux.xml","checkbox_normal_check.tex","checkbox_focus_check.tex")
        else
            self.camera_update=false
            TheCamera.controllable=true
            self:update_transfer(true)
            TheCamera.maxdist = 300
            TheCamera.mindist = 3
            -- TheCamera.mindistpitch = 35
            -- TheCamera.maxdistpitch = 120--60
            -- TheCamera:SetDefault()
            -- self:update_transfer(true)
            self.transfer_update:SetTextures("images/global_redux.xml","checkbox_normal.tex","checkbox_focus.tex")
        end
    end)

    self.transfer_360=self.transfer:AddChild(TextButton())
    self.transfer_360:SetFont(BODYTEXTFONT)
    self.transfer_360:SetPosition(pos_x+30,pos_y,0)
    self.transfer_360:SetTextSize(self.fontsize+3)
    self.transfer_360:SetText(STRINGS.BM_HELP.BUTTONS.transfer.transfer_360)
    self.transfer_360:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.transfer_360_tip)
    self.transfer_360:SetOnClick(function()
        if self.transfer_360_update then
            self.transfer_360:SetText(STRINGS.BM_HELP.BUTTONS.transfer.transfer_360)
            self.transfer_360_update=false
        else
            self.transfer_360:SetText(STRINGS.BM_HELP.BUTTONS.transfer.transfer_360_stop)
            self.transfer_360_update=true
        end
    end)
    -----------------------------------------------------------------------------------视野部分完成
    pos_x,pos_y=-100,0
    self.item_boundary=self.transfer:AddChild(Image())
    self.item_boundary:SetTexture("images/frontend_redux.xml", "achievements_wide_divider_bottom.tex" )
    self.item_boundary:SetPosition(0, pos_y, 0 )
    self.item_boundary:SetScale(0.3,0.3,0.3)

    pos_x,pos_y=0,-30
    posy_offset=-40
    pos_message={"images/textboxes.xml", "textbox3_gold_small_normal.tex", "textbox3_gold_small_hover.tex", "textbox3_gold_small_focus.tex"}
    for k,value in ipairs(self.anim_list)do
        local v,vv=value[1],value[2]
        if v =="swap_symbol:" then
            self["edit_text_bg"..v] = self.transfer:AddChild( Image() )
            self["edit_text_bg"..v]:SetTexture("images/textboxes.xml", "textbox3_gold_small_normal.tex" )
            self["edit_text_bg"..v]:SetPosition(pos_x+50, pos_y, 0 )
            self["edit_text_bg"..v]:ScaleToSize(150, 30)
    
            self["text_bg"..v]=self.transfer:AddChild(Text(DEFAULTFONT,self.fontsize+3))
            
            self["text_bg"..v]:SetPosition(pos_x-85,pos_y, 0)
            self["text_bg"..v]:SetString("obj_swap_sym:")
    
            --self[...]:SetString(str)
            --GetString
            self["edit_text"..v] = self.transfer:AddChild(TextEdit(NEWFONT_SMALL, 20, "" ))
            -- self["edit_text"..v]:SetCharacterFilter("_0123456789")
            self["edit_text"..v]:SetIdleTextColour(139/255,105/255,20/255,1)
            self["edit_text"..v]:SetPosition(pos_x+48, pos_y, 0 )
            self["edit_text"..v]:SetRegionSize(135,40)
            self["edit_text"..v]:SetHAlign(ANCHOR_LEFT)
            self["edit_text"..v]:SetFocusedImage(self["edit_text_bg"..v], pos_message[1], pos_message[2],pos_message[3],pos_message[4])
            self["edit_text"..v]:SetTextLengthLimit(40)
            self["edit_text"..v]:SetForceEdit(true)
            self:Push_TextEdit(self["edit_text"..v])--用于屏蔽动作
            self["edit_text"..v]:EnableWordPrediction(dictionary_bm.symbol[1],dictionary_bm.symbol[2])--用于预测
        else
            self["edit_text_bg"..v] = self.transfer:AddChild( Image() )
            self["edit_text_bg"..v]:SetTexture("images/textboxes.xml", "textbox3_gold_small_normal.tex" )
            self["edit_text_bg"..v]:SetPosition(pos_x-20, pos_y, 0 )
            self["edit_text_bg"..v]:ScaleToSize(150, 30)
    
            self["text_bg"..v]=self.transfer:AddChild(Text(DEFAULTFONT,self.fontsize+3))
            
            self["text_bg"..v]:SetPosition(pos_x-120,pos_y, 0)
            self["text_bg"..v]:SetString(v)
    
            --self[...]:SetString(str)
            --GetString
            self["edit_text"..v] = self.transfer:AddChild(TextEdit(NEWFONT_SMALL, 20, "" ))
            -- self["edit_text"..v]:SetCharacterFilter("_0123456789")
            self["edit_text"..v]:SetIdleTextColour(139/255,105/255,20/255,1)
            self["edit_text"..v]:SetPosition(pos_x-18, pos_y, 0 )
            self["edit_text"..v]:SetRegionSize(135,40)
            self["edit_text"..v]:SetHAlign(ANCHOR_LEFT)
            self["edit_text"..v]:SetFocusedImage(self["edit_text_bg"..v], pos_message[1], pos_message[2],pos_message[3],pos_message[4])
            self["edit_text"..v]:SetTextLengthLimit(40)
            self["edit_text"..v]:SetForceEdit(true)
            self:Push_TextEdit(self["edit_text"..v])--用于屏蔽动作
    
            -------------------------------------------------------------------------------------
            if vv then
                -- self["edit_text_bg"..vv] = self.transfer:AddChild( Image() )
                -- self["edit_text_bg"..vv]:SetTexture("images/textboxes.xml", "textbox3_gold_small_normal.tex" )
                -- self["edit_text_bg"..vv]:SetPosition(pos_x-20, pos_y, 0 )
                -- self["edit_text_bg"..vv]:ScaleToSize(150, 30)
        
                self["text_bg"..vv]=self.transfer:AddChild(Text(DEFAULTFONT,self.fontsize+3))
                
                self["text_bg"..vv]:SetPosition(pos_x+80,pos_y, 0)
                self["text_bg"..vv]:SetString(vv)
        
                --self[...]:SetString(str)
                --GetString
                self["edit_text"..vv] = self.transfer:AddChild(ImageButton("images/global_redux.xml","checkbox_normal.tex","checkbox_focus.tex"))
                -- self["edit_text"..v]:SetCharacterFilter("_0123456789")
                self["edit_text"..vv]:SetScale(1,1,1)
                self["edit_text"..vv]:SetPosition(pos_x+120,pos_y,0)
                self["edit_text"..vv]:SetOnClick(function()
                    if not self["edit_text"..vv].anim then
                        self["edit_text"..vv].anim=true
                        self["edit_text"..vv]:SetTextures("images/global_redux.xml","checkbox_normal_check.tex","checkbox_focus_check.tex")
                        for t,val in ipairs(self.anim_list)do
                            local vt=val[2]
                            if t~=k and vt then
                                self["edit_text"..vt].anim=false
                                self["edit_text"..vt]:SetTextures("images/global_redux.xml","checkbox_normal.tex","checkbox_focus.tex")
                            end
                        end
                        -- if vv==STRINGS.BM_HELP.BUTTONS.transfer.hand then
                        --     self["edit_textsymb:"]:SetString("swap_")
                        -- elseif vv==STRINGS.BM_HELP.BUTTONS.transfer.player then
                        --     -- self["edit_textsymb:"]:SetString("swap_")
                        -- else
                        --     self["edit_textanim:"]:SetString("idle")
                        -- end
                    else
                        self["edit_text"..vv].anim=false
                        self["edit_text"..vv]:SetTextures("images/global_redux.xml","checkbox_normal.tex","checkbox_focus.tex")
                        self["edit_text"..STRINGS.BM_HELP.BUTTONS.transfer.hand].anim=true
                        self["edit_text"..STRINGS.BM_HELP.BUTTONS.transfer.hand]:SetTextures("images/global_redux.xml","checkbox_normal_check.tex","checkbox_focus_check.tex")
                        -- self["edit_textsymb:"]:SetString("swap_")
                    end
                end)
            else
                self["edit_text"..v]:EnableWordPrediction(dictionary_bm.symbol[1],dictionary_bm.symbol[2])--用于预测

                self["edit_textplay"] = self.transfer:AddChild(ImageButton("images/global_redux.xml","button_carny_square_normal.tex",
                "button_carny_square_hover.tex","button_carny_square_disabled.tex","button_carny_square_down.tex"))
                -- self["edit_text"..v]:SetCharacterFilter("_0123456789")
                self["edit_textplay"]:SetScale(0.4,0.3,0.3)
                self["edit_textplay"]:SetPosition(pos_x+80,pos_y,0)
                self["edit_textplay"]:SetOnClick(function()
                    if self.owner.components.get_message then
                        self.owner.components.get_message:Play_anim(self["edit_textbank:"]:GetString(),self["edit_textbuild:"]:GetString(),
                        self["edit_textanim:"]:GetString(),self["edit_textsymb:"]:GetString(),
                        self["edit_textswap_symbol:"]:GetString(),
                        self["edit_text"..STRINGS.BM_HELP.BUTTONS.transfer.structure].anim,
                        self["edit_text"..STRINGS.BM_HELP.BUTTONS.transfer.hand].anim,
                        self["edit_text"..STRINGS.BM_HELP.BUTTONS.transfer.player].anim,
                        self["edit_text".."flower"].anim)
                        self.last_anim_play=2
                        self.anim_undo_left_offset=0
                        self.anim_undo_right_offset=0
                    end
                end)
    
                self["edit_textplay"].text=self.transfer:AddChild(Text(DEFAULTFONT,self.fontsize))
                self["edit_textplay"].text:SetPosition(pos_x+80,pos_y,0)
                self["edit_textplay"].text:SetString("play")
    
                self.last_anim_play=1
                self.anim_undo_left_offset=0
                self.anim_undo_right_offset=0
    
                -- self.anim_undo=self.transfer:AddChild(ImageButton("images/button_icons.xml","undo.tex"))
                -- self.anim_undo:SetScale(0.12,0.12,1)
                -- self.anim_undo:SetPosition(pos_x+120,pos_y,0)
                -- self.anim_undo:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.transfer_undo)
                -- self.last_anim_play=1
                -- self.anim_undo:SetOnClick(function()
                --     if self.owner.components.get_message and self.owner.components.get_message.last_anim then
                        -- local anim=self.owner.components.get_message.last_anim[self.last_anim_play]
                        -- if anim then
                        --     self["edit_textbank:"]:SetString(anim.bank)
                        --     self["edit_textbuild:"]:SetString(anim.build)
                        --     self["edit_textanim:"]:SetString(anim.anim)
                        --     self["edit_textsymb:"]:SetString(anim.symbol)
                --             self.last_anim_play=self.last_anim_play+1
                --         end
                --     end
                -- end)
                self.anim_undo_left=self.transfer:AddChild(ImageButton("images/global_redux.xml","arrow2_left.tex","arrow2_left_over.tex","arrow_left_disabled.tex","arrow2_left_down.tex"))
                self.anim_undo_left:SetScale(0.3,0.3,1)
                self.anim_undo_left:SetPosition(pos_x+115,pos_y,0)
                self.anim_undo_left:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.transfer_undo_left)
                self.anim_undo_left:SetOnClick(function()
                    if self.owner.components.get_message and self.owner.components.get_message.last_anim then
                        local num=#self.owner.components.get_message.last_anim
                        self.last_anim_play=math.min(self.last_anim_play+self.anim_undo_left_offset,num)
                        -- print("左",self.last_anim_play,#self.owner.components.get_message.last_anim)
                        local anim=self.owner.components.get_message.last_anim[self.last_anim_play]
                        if anim then
                            self["edit_textbank:"]:SetString(anim.bank or "")
                            self["edit_textbuild:"]:SetString(anim.build or "")
                            self["edit_textanim:"]:SetString(anim.anim or "")
                            self["edit_textsymb:"]:SetString(anim.symbol or "")
                            self["edit_textswap_symbol:"]:SetString(anim.swap_symbol or "swap_symbol")
                            self.last_anim_play=math.min(self.last_anim_play+1,num)
                            self.anim_undo_left_offset=0
                            self.anim_undo_right_offset=-2
                            if self.last_anim_play==num then
                                self.anim_undo_right_offset=-1
                            end
                        end
                    end
                end)
                self.anim_undo_right=self.transfer:AddChild(ImageButton("images/global_redux.xml","arrow2_right.tex","arrow2_right_over.tex","arrow_right_disabled.tex","arrow2_right_down.tex"))
                self.anim_undo_right:SetScale(0.3,0.3,1)
                self.anim_undo_right:SetPosition(pos_x+135,pos_y,0)
                self.anim_undo_right:SetTooltip(STRINGS.BM_HELP.BUTTONS.transfer.transfer_undo_right)
                self.anim_undo_right:SetOnClick(function()
                    if self.owner.components.get_message and self.owner.components.get_message.last_anim then
                        self.last_anim_play=math.max(self.last_anim_play+self.anim_undo_right_offset,1)
                        -- print("右",self.last_anim_play,#self.owner.components.get_message.last_anim)
                        local anim=self.owner.components.get_message.last_anim[self.last_anim_play]
                        if anim then
                            self["edit_textbank:"]:SetString(anim.bank or "")
                            self["edit_textbuild:"]:SetString(anim.build or "")
                            self["edit_textanim:"]:SetString(anim.anim or "")
                            self["edit_textsymb:"]:SetString(anim.symbol or "")
                            self["edit_textswap_symbol:"]:SetString(anim.swap_symbol or "swap_symbol")
                            self.last_anim_play=math.max(self.last_anim_play-1,1)
                            self.anim_undo_right_offset=0
                            self.anim_undo_left_offset=2
                            if self.last_anim_play==1 then
                                self.anim_undo_left_offset=1
                            end
                        end
                    end
                end)
            end
        end
        pos_y=pos_y+posy_offset
    end
    self.anim_undo_right.onclick()
    self["edit_text"..STRINGS.BM_HELP.BUTTONS.transfer.hand].anim=true
    self["edit_text"..STRINGS.BM_HELP.BUTTONS.transfer.hand]:SetTextures("images/global_redux.xml","checkbox_normal_check.tex","checkbox_focus_check.tex")
    
    
    ----------------------------------------------------------------------------
    self["text_bg".."flower"]=self.transfer:AddChild(Text(DEFAULTFONT,self.fontsize+3))
    self["text_bg".."flower"]:SetPosition(pos_x-110,pos_y+10, 0)
    self["text_bg".."flower"]:SetString(STRINGS.BM_HELP.BUTTONS.transfer.flower)

    self["edit_text".."flower"] = self.transfer:AddChild(ImageButton("images/global_redux.xml","checkbox_normal.tex","checkbox_focus.tex"))
    -- self["edit_text"..v]:SetCharacterFilter("_0123456789")
    self["edit_text".."flower"]:SetScale(1,1,1)
    self["edit_text".."flower"]:SetPosition(pos_x-50,pos_y+10,0)
    self["edit_text".."flower"]:SetOnClick(function()
        if not self["edit_text".."flower"].anim then
            self["edit_text".."flower"].anim=true
            self["edit_text".."flower"]:SetTextures("images/global_redux.xml","checkbox_normal_check.tex","checkbox_focus_check.tex")
        else
            self["edit_text".."flower"].anim=false
            self["edit_text".."flower"]:SetTextures("images/global_redux.xml","checkbox_normal.tex","checkbox_focus.tex")
        end
    end)
end

function Bm_menu:Camera_360(dt)
    if self.camera_update then
        local num=self["edit_texthgtarget"]:GetString()
        num=((tonumber(num) or 0)+dt*10*1.5)
        if num>360 then
            num=num-360
        end
        num=self:Get_integral(num)
        self["edit_texthgtarget"]:SetString(tostring(num))
        self["edit_textheading"]:SetString(tostring(num))
    else
        local num=TheCamera.headingtarget+dt*10*1.5
        if num>360 then
            num=num-360
        end
        num=self:Get_integral(num)
        TheCamera.headingtarget=num
        TheCamera.heading=num
    end
end


function Bm_menu:SetTarget(target)
    if self.transfer_show then
        TheCamera:SetTarget(target)
    end
end
function Bm_menu:Get_integral(num)
    if type(num)=="string" then
        num=tostring(num)
    end
    if type(num)=="number" then
        num=math.modf(num*10)/10
        return num
    end
    return 0
end
function Bm_menu:update_transfer(flag)
    local fn={
        [1]=function (num)
            TheCamera.fov=num
        end,
        [2]=function (num)
            TheCamera.distancetarget=num
            TheCamera.distance = num
            TheCamera.mindist = num
            TheCamera.maxdist = num+0.01
        end,
        [3]=function (num)
            TheCamera.mindistpitch=num
            TheCamera.maxdistpitch=num
        end,
        [4]=function (num)
            TheCamera.headingtarget=num
        end,
        [5]=function (num)
            TheCamera.heading=num
        end,
        [6]=function (num)
            -- 
        end,
        -- [7]=function (num)
        --     TheCamera.controllable=num>0 and true or false
        -- end,
        [7]=function (num)
            TheCamera.paused=num>0 and true or false
        end,
        [8]=function (num)
            TheCamera.cutscene=num>0 and true or false
        end,
    }
    local c_list={
        TheCamera.fov,
        TheCamera.distancetarget,
        TheCamera.pitch,
        TheCamera.headingtarget,
        TheCamera.heading,
        (TheCamera.targetpos and ("("..(self:Get_integral(TheCamera.targetpos.x) or 0)..","..
        (self:Get_integral(TheCamera.targetpos.y) or 0)..","..(self:Get_integral(TheCamera.targetpos.z) or 0)..")")) or "(0,0,0)",
        -- TheCamera.controllable==true and 1 or 0,
        TheCamera.paused==true and 1 or 0,
        TheCamera.cutscene==true and 1 or 0,
    }
    local n=0
    for _,value in ipairs(self.camera_list)do
        for k,v in pairs(value)do
            if flag then
                n=n+1
                self["edit_text"..k]:SetString(tostring(self:Get_integral(c_list[n])))
                if n>8 then
                    return
                end
            else
                local num=self["edit_text"..k]:GetString()
                num=tonumber(num) or 0
                if type(num)=="number" then
                    n=n+1
                    if n>8 then
                        return
                    end
                    fn[n](num)
                end
            end
        end
    end
    local str=(TheCamera.targetpos and ("("..(math.modf(TheCamera.targetpos.x) or 0)..","..
    (math.modf(TheCamera.targetpos.y) or 0)..","..(math.modf(TheCamera.targetpos.z) or 0)..")")) or "(0,0,0)"
    self["edit_texttargetpos"]:SetString(str)
end

function Bm_menu:item_player()
    -- self.ConsoleScreen=ConsoleScreen()
    -- self.ConsoleScreen:Hide()
    -- self.ConsoleScreen:Close()
    self.item_code_list={
        -- {"spawn:",STRINGS.BM_HELP.BUTTONS.code.spawn_num,STRINGS.BM_HELP.BUTTONS.code.spawn},--没多大用处
        {"sound:",STRINGS.BM_HELP.BUTTONS.code.sound_volume,STRINGS.BM_HELP.BUTTONS.code.sound},
    }
    local pos_x,pos_y=-80,210
    local posy_offset=-40
    local pos_message={"images/textboxes.xml", "textbox3_gold_small_normal.tex", "textbox3_gold_small_hover.tex", "textbox3_gold_small_focus.tex"}
    local pos_message2={"images/textboxes.xml", "textbox3_gold_tiny_normal.tex", "textbox3_gold_tiny_hover.tex", "textbox3_gold_tiny_focus.tex"}
    for k,value in ipairs(self.item_code_list)do
        local v,vv,vvv=value[1],value[2],value[3]
        ---描述
        self.item["text_bg"..v]=self.item:AddChild(Text(DEFAULTFONT,self.fontsize+3))
        self.item["text_bg"..v]:SetPosition(pos_x-105,pos_y, 0)
        self.item["text_bg"..v]:SetString(v)
        ---背景图片
        self.item["item_code"..v] = self.item:AddChild( Image() )
        self.item["item_code"..v]:SetTexture("images/textboxes.xml", "textbox3_gold_small_normal.tex" )
        self.item["item_code"..v]:SetPosition(pos_x, pos_y, 0 )
        self.item["item_code"..v]:ScaleToSize(150, 30)
        ---可编辑属性条
        --self[...]:SetString(str)
        --GetString
        self.item["edit_text"..v] = self.item:AddChild(TextEdit(NEWFONT_SMALL, 20, "" ))
        -- self["edit_text"..v]:SetCharacterFilter("_0123456789")
        self.item["edit_text"..v]:SetIdleTextColour(139/255,105/255,20/255,1)
        self.item["edit_text"..v]:SetPosition(pos_x-2, pos_y, 0 )
        self.item["edit_text"..v]:SetRegionSize(135,40)
        self.item["edit_text"..v]:SetHAlign(ANCHOR_LEFT)
        self.item["edit_text"..v]:SetFocusedImage(self.item["item_code"..v], pos_message[1], pos_message[2],pos_message[3],pos_message[4])
        -- self.item["edit_text"..v]:SetTextLengthLimit(40)
        self.item["edit_text"..v]:SetForceEdit(true)
        self:Push_TextEdit(self.item["edit_text"..v])--用于屏蔽动作
    

        local pos_x2,pos_y2=pos_x+180,pos_y
        -------------------------属性
        self.item["text_bg"..vv]=self.item:AddChild(Text(DEFAULTFONT,self.fontsize+3))
        self.item["text_bg"..vv]:SetPosition(pos_x2-70,pos_y, 0)
        self.item["text_bg"..vv]:SetString(vv)


        self.item["item_code"..vv] = self.item:AddChild( Image() )
        self.item["item_code"..vv]:SetTexture("images/textboxes.xml", "textbox3_gold_tiny_normal.tex" )
        self.item["item_code"..vv]:SetPosition(pos_x2, pos_y, 0 )
        self.item["item_code"..vv]:ScaleToSize(90, 30)
    
        self.item["edit_text"..vv] = self.item:AddChild(TextEdit(NEWFONT_SMALL, 20, "" ))
        self.item["edit_text"..vv]:SetCharacterFilter(".0123456789")
        self.item["edit_text"..vv]:SetIdleTextColour(139/255,105/255,20/255,1)
        self.item["edit_text"..vv]:SetPosition(pos_x2-2, pos_y, 0 )
        self.item["edit_text"..vv]:SetRegionSize(70,40)
        self.item["edit_text"..vv]:SetHAlign(ANCHOR_LEFT)
        self.item["edit_text"..vv]:SetFocusedImage(self.item["item_code"..vv], pos_message2[1], pos_message2[2],pos_message2[3],pos_message2[4])
        self.item["edit_text"..vv]:SetTextLengthLimit(10)
        self.item["edit_text"..vv]:SetForceEdit(true)
        self:Push_TextEdit(self.item["edit_text"..vv])--用于屏蔽动作
        ------------------------执行按钮
        self.item["edit_textplay"..v] = self.item:AddChild(ImageButton("images/global_redux.xml","button_carny_square_normal.tex",
        "button_carny_square_hover.tex","button_carny_square_disabled.tex","button_carny_square_down.tex"))
        -- self["edit_text"..v]:SetCharacterFilter("_0123456789")
        self.item["edit_textplay"..v]:SetScale(0.4,0.3,0.3)
        self.item["edit_textplay"..v]:SetPosition(pos_x2+80,pos_y,0)
        self.item["edit_textplay"..v]:SetOnClick(function()
            if self.owner.components.get_message then
                local prefab,num=self.item["edit_text"..v]:GetString(),self.item["edit_text"..vv]:GetString()
                self.owner.components.get_message:Play_code(prefab,tonumber(num),v)
            end
        end)
        self.item["edit_textplay"..v].text=self.item:AddChild(Text(DEFAULTFONT,self.fontsize))
        self.item["edit_textplay"..v].text:SetPosition(pos_x2+80,pos_y,0)
        self.item["edit_textplay"..v].text:SetString(vvv)
        self.item["edit_textplay"..v].text:SetColour(self.colour[1],self.colour[2],self.colour[3],self.colour[4])

        pos_y=pos_y+posy_offset
    end

    -- self.itemsize_x=self.shieldsize_x*1.5
    -- self.itemsize_y = self.shieldsize_y
    pos_x=0
    pos_y=0
    self.console_edit_bg = self.item:AddChild( Image() )
    self.console_edit_bg:SetTexture("images/quagmire_recipebook.xml", "quagmire_recipe_menu_bg.tex" )
    self.console_edit_bg:SetPosition(pos_x, pos_y, 0 )
    -- self.console_edit_bg.inst.UITransform:SetScissor(self.itemsize_x,self.itemsize_y, math.max(0, inst.healthCurrent / inst.healthMax * inst.w), math.max(0, inst.h))
    self.console_edit_bg:ScaleToSize(self.itemsize_x, self.itemsize_y-100)

    self.console_edit = self.item:AddChild(TextEdit(NEWFONT,self.fontsize+5, ""))
    self.console_edit:SetColour(1, 1, 1, 1)
    self.console_edit:SetForceEdit(true)
    self.console_edit:SetPosition(pos_x-5, pos_y, 0)
    self.console_edit:SetRegionSize(self.itemsize_x-80, self.itemsize_y-150)
    self.console_edit:SetHAlign(ANCHOR_LEFT)
    self.console_edit:SetVAlign(ANCHOR_TOP)
    self.console_edit:SetAllowNewline(true)
    self.console_edit:SetFocusedImage(self.console_edit_bg,"images/quagmire_recipebook.xml","quagmire_recipe_menu_bg.tex","quagmire_recipe_menu_bg.tex","quagmire_recipe_menu_bg.tex")
    --self.writetext:SetTextLengthLimit(1500)
    self.console_edit:EnableWordWrap(true)
    -- self.console_edit:EnableWhitespaceWrap(true)
    -- self.console_edit:EnableRegionSizeLimit(true)
    -- self.console_edit:EnableScrollEditWindow(true)
    self:Push_TextEdit(self.console_edit)--用于屏蔽动作
    self.owner:DoTaskInTime(1,function ()
        local prefab_names = {}
        for name,_ in pairs(Prefabs) do
            table.insert(prefab_names, name)
        end
        self.console_edit:EnableWordPrediction({width = 600, mode=Profile:GetConsoleAutocompleteMode()})
        self.console_edit:AddWordPredictionDictionary({words = prefab_names, delim = '"', postfix='"', skip_pre_delim_check=true})
        self.console_edit:AddWordPredictionDictionary({words = prefab_names, delim = "'", postfix="'", skip_pre_delim_check=true})
        local prediction_command = {"spawn", "save", "gonext", "give", "mat", "list", "findnext", "countprefabs", "selectnear", "removeall", "shutdown", "regenerateworld", "reset", "despawn", "godmode", "supergodmode", "armor", "makeboat", "makeboatspiral", "autoteleportplayers", "gatherplayers", "dumpentities", "freecrafting", "selectnext", "sounddebug" }
        self.console_edit:AddWordPredictionDictionary({words = prediction_command, delim = "c_", num_chars = 0})

        self.console_edit:SetForceEdit(true)
        -- self.console_edit.OnStopForceEdit = function() self:Close() end


        self.console_edit.last_code_play=1
        self.console_edit.code_undo_left_offset=0
        self.console_edit.code_undo_right_offset=0

        local code=self.owner.components.get_message and self.owner.components.get_message.last_code[1]
        if code then
            self.console_edit:SetString(code.str or "")
        end

        local old_OnRawKey=self.console_edit.OnRawKey
        self.console_edit.OnRawKey = function(s, key, down) 
            if s.editing and s.prediction_widget ~= nil and s.prediction_widget:OnRawKey(key, down) then
                s.editing_enter_down = false
                return true
            end
            if s.editing and not down then
                if key == KEY_UP then
                    local num=#self.owner.components.get_message.last_code
                    s.last_code_play=math.min(s.last_code_play+s.code_undo_left_offset,num)
                    local code=self.owner.components.get_message.last_code[s.last_code_play]
                    if code then
                        self.console_edit:SetString(code.str or "")
                        s.last_code_play=math.min(s.last_code_play+1,num)
                        s.code_undo_left_offset=0
                        s.code_undo_right_offset=-2
                        if s.last_code_play==num then
                            s.code_undo_right_offset=-1
                        end
                    end
                elseif key == KEY_DOWN then
                    s.last_code_play=math.max(s.last_code_play+s.code_undo_right_offset,1)
                    local code=self.owner.components.get_message.last_code[s.last_code_play]
                    if code then
                        self.console_edit:SetString(code.str or "")
                        s.last_code_play=math.max(s.last_code_play-1,1)
                        s.code_undo_right_offset=0
                        s.code_undo_left_offset=2
                        if s.last_code_play==1 then
                            s.code_undo_left_offset=1
                        end
                    end
                end
            end
            --[[
                                    if self.owner.components.get_message and self.owner.components.get_message.last_anim then
                        self.last_anim_play=math.max(self.last_anim_play+self.anim_undo_right_offset,1)
                        -- print("右",self.last_anim_play,#self.owner.components.get_message.last_anim)
                        local anim=self.owner.components.get_message.last_anim[self.last_anim_play]
                        if anim then
                            self["edit_textbank:"]:SetString(anim.bank or "")
                            self["edit_textbuild:"]:SetString(anim.build or "")
                            self["edit_textanim:"]:SetString(anim.anim or "")
                            self["edit_textsymb:"]:SetString(anim.symbol or "")
                            self["edit_textswap_symbol:"]:SetString(anim.swap_symbol or "swap_symbol")
                            self.last_anim_play=math.max(self.last_anim_play-1,1)
                            self.anim_undo_right_offset=0
                            self.anim_undo_left_offset=2
                            if self.last_anim_play==1 then
                                self.anim_undo_left_offset=1
                            end
                        end
                    end
            ]]
            old_OnRawKey(s,key,down)
        end

        self.console_edit.validrawkeys[KEY_LCTRL] = true
        self.console_edit.validrawkeys[KEY_RCTRL] = true
        self.console_edit.validrawkeys[KEY_UP] = true
        self.console_edit.validrawkeys[KEY_DOWN] = true
        self.toggle_remote_execute = false
    end)

    self.item["edit_play".."code"] = self.item:AddChild(ImageButton("images/global_redux.xml","button_carny_long_normal.tex",
    "button_carny_long_hover.tex","button_carny_long_disabled.tex","button_carny_long_down.tex"))
    -- self["edit_text"..v]:SetCharacterFilter("_0123456789")
    self.item["edit_play".."code"]:SetScale(0.6,0.6,0.6)
    self.item["edit_play".."code"]:SetPosition(pos_x,pos_y-215,0)
    self.item["edit_play".."code"]:SetOnClick(function()
        if self.owner.components.get_message then
            local str=self.console_edit:GetString()
            if str then
                self.console_edit.last_code_play=1
                self.console_edit.code_undo_left_offset=0
                self.console_edit.code_undo_right_offset=0
                self.owner.components.get_message:Run_code(str)
            end
        end
    end)
    self.item["edit_play".."code"].text=self.item:AddChild(Text(DEFAULTFONT,self.fontsize+10))
    self.item["edit_play".."code"].text:SetPosition(pos_x,pos_y-215,0)
    self.item["edit_play".."code"].text:SetString("run")
    self.item["edit_play".."code"].text:SetColour(self.colour[1],self.colour[2],self.colour[3],self.colour[4])
end

function Bm_menu:ShowTransferMenu()
    if self.transfer_show then
        self.transfer_show=false
        self.transfer:Hide()
    else
        self.transfer_show=true
        self.transfer:Show()
    end
end

function Bm_menu:ShowShieldMenu()
    if self.shield_show then
        self.shield_show=false
        self.shield:Hide()
    else
        self.shield_show=true
        self.shield:Show()
    end
end

function Bm_menu:ShowItemMenu()
    if self.item_show then
        self.item_show=false
        self.item:Hide()
    else
        -- if #dictionary_bm.prefabs[2].words==0 then
        --     local prefab_names={}
        --     for name,_ in pairs(Prefabs) do
        --         table.insert(prefab_names, name)
        --     end
        --     dictionary_bm.prefabs[2].words=prefab_names
        -- end
        -- self.item["edit_textspawn:"]:EnableWordPrediction(dictionary_bm.prefabs[1],dictionary_bm.prefabs[2])
        -- -- self.item["edit_text"..v]:EnableWordPrediction(dictionary_bm.symbol[1],dictionary_bm.symbol[2])--用于预测
        self.item_show=true
        self.item:Show()
    end
end
function Bm_menu:Push_TextEdit(text_edit)

    -- TheFrontEnd:GetFocusWidget().inst.TextEditWidget == text_edit--花花的方法肯定更简单
    -- text_edit.onlosefocusfn=function ()
    --     SetPause(false)
    --     if ThePlayer.HUD then
    --         ThePlayer.HUD:SetModFocus("Bm_menu","Bm_menu",false)
    --     end
    -- end
    -- text_edit.ongainfocusfn=function (self)
    --     SetPause(true)
    --     if ThePlayer.HUD then
    --         ThePlayer.HUD:SetModFocus("Bm_menu","Bm_menu",true)
    --     end
    -- end
    local old_idle=text_edit.DoIdleImage
    text_edit.DoIdleImage=function (self)
        old_idle(self)
        -- self:OnLoseFocus(self)
        if not self.editing then
            TheInput:EnableDebugToggle(true)
            -- SetPause(false)
            TUNING.BM_ALLOW=true
            if ThePlayer.HUD then
                ThePlayer.HUD:SetModFocus("Bm_menu","Bm_menu",false)
            end
        end
    end
    local old_select=text_edit.DoSelectedImage
    text_edit.DoSelectedImage=function (self)
        old_idle(self)
        TheInput:EnableDebugToggle(false)
        -- SetPause(true)
        TUNING.BM_ALLOW=false
        if ThePlayer.HUD then
            ThePlayer.HUD:SetModFocus("Bm_menu","Bm_menu",true)
        end
    end
end

function Bm_menu:OnLoad_bm()
    
end
function Bm_menu:OnUpdate(dt)
    self:update_player()
    if self.camera_update then
        self:update_transfer()
    end
    if self.transfer_360_update then
        self:Camera_360(dt)
    end
end
return Bm_menu