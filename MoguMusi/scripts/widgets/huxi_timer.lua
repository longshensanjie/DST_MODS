
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local ImageButton = require("widgets/imagebutton")
require("fonts")


local function fixImgSize(img, size)
    local sizeX, sizeY = img:GetSize()
	local trans_scale = math.min(size / sizeX, size / sizeY)
	img:SetNormalScale(trans_scale)
	img:SetFocusScale(trans_scale * 1.2)
end

local ManagerHuxi = require("utilclass/mana_huxi")()

local huxiTimer = Class(Widget, function(self, owner)
    Widget._ctor(self, "huxiTimer")
    self.owner = owner or ThePlayer
    self.root = self:AddChild(Widget("root"))
    self.root:SetVAnchor(ANCHOR_TOP)
    self.root:SetHAnchor(ANCHOR_LEFT)

    
    local screen_w, screen_h = TheSim:GetScreenSize()
    local offx, offy = 120, 50             -- 起始偏移量, 以我的电脑为准，等比放缩
    self.num_col = 10                      -- 一行显示几个图标
    self.timer_btn_size = 50     -- 图标多大
    self.root:SetPosition(1920/screen_w*offx,1080/screen_h*(-offy))
    -- 全世界都给我响应！
    if TheWorld then
        TheWorld:ListenForEvent("Mod_Shroomcake_Huxi", function(inst, data) self:TransmitData(data) end)
        TheWorld:ListenForEvent("playerdeactivated",function(inst, data) self:TransmitData({type = "ins", name="ClearBuff"}) end)  
    end
    -- 早上好！
    if ThePlayer then
        ThePlayer:WatchWorldState("startday",function (inst)
            self:TransmitData({type = "ins", name = "Morning"})
        end)
    end
    self:StartSelf()
end)


function huxiTimer:StartSelf()
    self.pertask = self.inst:DoPeriodicTask(1, function(inst) self:OnUpdate() end)
end


function huxiTimer:ForceUpdate()
    if self.buffwidgets then self.buffwidgets:Kill() end
    self.buffwidgets = self.root:AddChild(self:MakeBuffwidgets())
end

function huxiTimer:TransmitData(data)
    ManagerHuxi:Process(data)
    self:OnUpdate()
end


function huxiTimer:OnUpdate()
    if not self.buffwidgets then 
        self:ForceUpdate()
    else
        -- 这里有一处bug, 我不说是啥
        local widgets_buff = self.buffwidgets.btns
        local buffs = ManagerHuxi:Product()
        if GetTableSize(widgets_buff) ~= #buffs then
            self:ForceUpdate()
        else
            for _,buff in pairs(buffs)do
                local w_b = widgets_buff[buff.name]
                if w_b then
                    w_b.thetext:SetString(buff.duration_text)
                    if buff.textcolor then 
                        w_b.thetext:SetColour(buff.textcolor)
                    else
                        w_b.thetext:SetColour(UICOLOURS.WHITE)
                    end
                else
                    self:ForceUpdate()
                end
            end
        end
    end
end

local function LROnControl(button, control, down)
	if not button:IsEnabled() or not button.focus or TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) then return end
	if button:IsSelected() and not button.AllowOnControlWhenSelected then return false end
	local click = control == button.control and 1 or (control == CONTROL_SECONDARY or control == CONTROL_CONTROLLER_ALTACTION) and 2 or 0
	if click == 0 then return end
	if down and not button.down then
		if button.has_image_down then
			button.image:SetTexture(button.atlas, button.image_down)
			if button.size_x and button.size_y then 
				button.image:ScaleToSize(button.size_x, button.size_y)
			end
		end
		TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		button.o_pos = button:GetLocalPosition()
		if button.move_on_click then
			button:SetPosition(button.o_pos + button.clickoffset)
		end
		button.down = true
		-- to store which button made it down
		button.left = click == 1
		if button.whiledown then
			button:StartUpdating()
		end
		if button.ondown then
			button.ondown()
		end
	-- make sure button released is one that made it down
	elseif not down and button.down and button.left == (click == 1) then
		if button.has_image_down then
			button.image:SetTexture(button.atlas, button.image_focus)
			if button.size_x and button.size_y then 
				button.image:ScaleToSize(button.size_x, button.size_y)
			end
		end
		button.down = false
		button.left = nil
		button:ResetPreClickPosition()
		if button.onclick then
			button.onclick(click == 1)
		end
		button:StopUpdating()
	end
	return true
end


function huxiTimer:MakeBuffwidgets()
    local spacing_y = self.timer_btn_size * 1.7
    local spacing_x = self.timer_btn_size * 1.5
    local text_posy = self.timer_btn_size * -1
    local text_size = 30
    local buffs = ManagerHuxi:Product()
    local w = Widget("huxi_timer_buffs")
    w.btns = {}
    for i, buff in pairs(buffs)do
        local btn = w:AddChild(Widget("huxi_timer_buff"))
        local x_pos = (i-1)%self.num_col * spacing_x
        local y_pos = math.floor((i-1)/self.num_col) * spacing_y
        btn:SetPosition(x_pos, -y_pos)

        local tex = buff.image..".tex"
        btn.imgbtn = btn:AddChild(ImageButton(GetInventoryItemAtlas(tex), tex))
        fixImgSize(btn.imgbtn, self.timer_btn_size)
        btn.imgbtn:SetTooltip(buff.description)
        btn.imgbtn:SetTooltipPos(0, text_posy*1.3)

        btn.imgbtn.OnControl = LROnControl
        btn.imgbtn:SetOnClick(function(lmb)
            if lmb then
                self:TransmitData({type = "sayIt", name = buff.name})
            else
                if self.owner.HUD and ManagerHuxi:Permiss(buff.name) then
                    self.owner.HUD:hxOpenTextEntry(buff.name)
                end
            end
        end)

        btn.thetext = btn:AddChild(Text(NUMBERFONT, text_size, buff.duration_text, UICOLOURS.WHITE))
        btn.thetext:SetPosition(0, text_posy)

        w.btns[buff.name] = btn
    end
    return w
end


return huxiTimer