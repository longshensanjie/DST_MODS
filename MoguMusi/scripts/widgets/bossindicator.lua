-- Based entirely on Klei's playerindicator.lua

local Image = require "widgets/image"
local Widget = require "widgets/widget"
local Text = require "widgets/text"

local YOFFSETUP = 40
local YOFFSETDOWN = 30
local XOFFSET = 10

local SHOW_DELAY = 0 --10

local HEAD_SIZE = 60

local ARROW_OFFSET = 65

local TOP_EDGE_BUFFER = 20
local BOTTOM_EDGE_BUFFER = 40
local LEFT_EDGE_BUFFER = 67
local RIGHT_EDGE_BUFFER = 80

local MIN_SCALE = .5
local MIN_ALPHA = .35

local DEFAULT_ATLAS = "images/avatars.xml"
local ICONS_ATLAS = "images/mod_bossindicators_icons.xml"

local MIN_INDICATOR_RANGE = 20
local MAX_INDICATOR_RANGE = 60

local function CancelIndicator(inst)
    inst.startindicatortask:Cancel()
    inst.startindicatortask = nil
    inst.OnRemoveEntity = nil
end

local function StartIndicator(target, self)
    self.inst.startindicatortask = nil
    self.inst.OnRemoveEntity = nil
    -- self.colour = BOSS_COLOURS[target.prefab]
    self:StartUpdating()
    self:OnUpdate()
    self:Show()
end

local BossIndicator = Class(Widget, function(self, owner, target, colour)
    Widget._ctor(self, "BossIndicator")
    self.owner = owner
    self.isFE = false
    self:SetClickable(true)

    self.root = self:AddChild(Widget("root"))
    -- self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.icon = self.root:AddChild(Widget("target"))

    self.target = target
    self.colour = colour

    --self.headbg = self.icon:AddChild(Image(DEFAULT_ATLAS, "avatar_bg.tex"))
    self.head = self.icon:AddChild(Image(ICONS_ATLAS, self:GetAvatar()))
    --self.headframe = self.icon:AddChild(Image(DEFAULT_ATLAS, "avatar_frame_white.tex"))

    self.icon:SetScale(.8)

    self.arrow = self.root:AddChild(Image("images/ui.xml", "scroll_arrow.tex"))
    self.arrow:SetScale(.5)

    self.name = target.name
    self.name_label = self.icon:AddChild(Text(UIFONT, 45, self.name))
    self.name_label:SetPosition(0, 80, 0)
    self.name_label:Hide()

    self:Hide()
    self.inst.startindicatortask = target:DoTaskInTime(0, StartIndicator, self)
    self.inst.OnRemoveEntity = CancelIndicator
    self.agree = true


    self.inst:DoTaskInTime(0, function()
		-- 如果有玩家 且 玩家HUD有_StatusAnnouncer【说明支持快捷宣告】
		if ThePlayer and ThePlayer.HUD._StatusAnnouncer then
            self.root:SetClickable(true)
			self.root.OnMouseButton = function(_, button, down)
                if button == 1000 and down and TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) and ThePlayer.HUD._StatusAnnouncer then
                    ThePlayer.HUD._StatusAnnouncer:Announce(self:GetAnnounce())
                end
            end
		end
	end)

    owner:ListenForEvent("Mod_BossIndicator", function(_, style)
        self.agree = style
    end)
end)

function BossIndicator:GetAnnounce()
    if (IsSteam() or not TheWorld.ismastersim) and TheInventory and TheInventory:CheckOwnership("emoji_eyeplant") then
        return "我这里有:eyeplant:"..self.name..":eyeplant:"
    else
        return "我这里有 "..self.name
    end
end

function BossIndicator:OnGainFocus()
    BossIndicator._base.OnGainFocus(self)
    self.name_label:Show()
end

function BossIndicator:OnLoseFocus()
    BossIndicator._base.OnLoseFocus(self)
    self.name_label:Hide()
end

function BossIndicator:GetTarget()
    return self.target
end

function BossIndicator:GetBossIndicatorAlpha(dist)
    if dist > TUNING.MAX_INDICATOR_RANGE*2 then
        dist = TUNING.MAX_INDICATOR_RANGE*2
    end
    local alpha = Remap(dist, TUNING.MAX_INDICATOR_RANGE, TUNING.MAX_INDICATOR_RANGE*2, 1, MIN_ALPHA)
    if dist <= TUNING.MAX_INDICATOR_RANGE then
        alpha = 1
    end
    return alpha
end

function BossIndicator:OnUpdate()
    -- figure out how far away they are and scale accordingly
    -- then grab the new position of the target and update the HUD elt's pos accordingly
    -- kill on this is rough: it just pops in/out. would be nice if it faded in/out...
	
	if not self.target:IsValid() then return end

    local dist = self.owner:GetDistanceSqToInst(self.target)
    dist = math.sqrt(dist)

    local alpha = self:GetBossIndicatorAlpha(dist)
    --self.headbg:SetTint(1, 1, 1, alpha)
    self.head:SetTint(1, 1, 1, alpha)
    --self.headframe:SetTint(self.colour[1], self.colour[2], self.colour[3], alpha)
    if self.colour then
        self.arrow:SetTint(self.colour[1], self.colour[2], self.colour[3], alpha)
        self.name_label:SetColour(self.colour[1], self.colour[2], self.colour[3], alpha)
    end

    if dist < MIN_INDICATOR_RANGE then
        dist = MIN_INDICATOR_RANGE
    elseif dist > MAX_INDICATOR_RANGE then
        dist = MAX_INDICATOR_RANGE
    end
    local scale = Remap(dist, MIN_INDICATOR_RANGE, MAX_INDICATOR_RANGE, 1, MIN_SCALE)
    self:SetScale(scale)

    local x, y, z = self.target.Transform:GetWorldPosition()
    self:UpdatePosition(x, z)

    if self.agree then self:Show() else self:Hide() end
end

local function GetXCoord(angle, width)
    if angle >= 90 and angle <= 180 then -- left side
        return 0
    elseif angle <= 0 and angle >= -90 then -- right side
        return width
    else -- middle somewhere
        if angle < 0 then
            angle = -angle - 90
        end
        local pctX = 1 - (angle / 90)
        return pctX * width
    end
end

local function GetYCoord(angle, height)
    if angle <= -90 and angle >= -180 then -- top side
        return height
    elseif angle >= 0 and angle <= 90 then -- bottom side
        return 0
    else -- middle somewhere
        if angle < 0 then
            angle = -angle
        end
        if angle > 90 then
            angle = angle - 90
        end
        local pctY = (angle / 90)
        return pctY * height
    end
end

function BossIndicator:UpdatePosition(targX, targZ)
    local angleToTarget = self.owner:GetAngleToPoint(targX, 0, targZ)
    local downVector = TheCamera:GetDownVec()
    local downAngle = -math.atan2(downVector.z, downVector.x) / DEGREES
    local indicatorAngle = (angleToTarget - downAngle) + 45
    while indicatorAngle > 180 do indicatorAngle = indicatorAngle - 360 end
    while indicatorAngle < -180 do indicatorAngle = indicatorAngle + 360 end

    local scale = self:GetScale()
    local w = 0
    local h = 0
    local w0, h0 = 16, 16 --self.head:GetSize()
    local w1, h1 = self.arrow:GetSize()
    if w0 and w1 then
        w = (w0 + w1)
    end
    if h0 and h1 then
        h = (h0 + h1)
    end

    local screenWidth, screenHeight = TheSim:GetScreenSize()

    local x = GetXCoord(indicatorAngle, screenWidth)
    local y = GetYCoord(indicatorAngle, screenHeight)

    if x <= LEFT_EDGE_BUFFER + (.5 * w * scale.x) then 
        x = LEFT_EDGE_BUFFER + (.5 * w * scale.x)
    elseif x >= screenWidth - RIGHT_EDGE_BUFFER - (.5 * w * scale.x) then
        x = screenWidth - RIGHT_EDGE_BUFFER - (.5 * w * scale.x)
    end

    if y <= BOTTOM_EDGE_BUFFER + (.5 * h * scale.y) then 
        y = BOTTOM_EDGE_BUFFER + (.5 * h * scale.y)
    elseif y >= screenHeight - TOP_EDGE_BUFFER - (.5 * h * scale.y) then
        y = screenHeight - TOP_EDGE_BUFFER - (.5 * h * scale.y)
    end

    self:SetPosition(x,y,0)
    self.x = x
    self.y = y
    self.angle = indicatorAngle
    self:PositionArrow()
    self:PositionLabel()
end

function BossIndicator:PositionArrow()
    if not self.x and self.y and self.angle then return end

    local angle = self.angle + 45
    self.arrow:SetRotation(angle)
    local x = math.cos(angle*DEGREES) * ARROW_OFFSET
    local y = -(math.sin(angle*DEGREES) * ARROW_OFFSET)
    self.arrow:SetPosition(x, y, 0)
end

function BossIndicator:PositionLabel()
    if not self.x and self.y and self.angle then return end

    local angle = self.angle + 45 - 180
    local x = math.cos(angle*DEGREES) * ARROW_OFFSET * 1.75
    local y = -(math.sin(angle*DEGREES) * ARROW_OFFSET  * 1.25)
    self.name_label:SetPosition(x, y, 0)
end

function BossIndicator:GetAvatarAtlas()
    return DEFAULT_ATLAS
end

function BossIndicator:GetAvatar()
	return self.target.prefab .. ".tex"
end

return BossIndicator