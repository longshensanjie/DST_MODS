local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local function OnEffigyDeactivated(inst)
    if inst.AnimState:IsCurrentAnimation("effigy_deactivate") then
        inst.widget:Hide()
    end
end

local WandaHealthBadge = Class(Badge, function(self, owner, art)
    Badge._ctor(self, art, owner, { 174 / 255, 21 / 255, 21 / 255, 1 }, "status_health")

    self.rate_time = 0
	self.warning_precent = 0.1

    
    if self.circleframe ~= nil then
        self.circleframe:GetAnimState():Hide("frame")
    else
        self.anim:GetAnimState():Hide("frame")
    end

    self.circleframe2 = self.underNumber:AddChild(UIAnim())
    self.circleframe2:GetAnimState():SetBank("status_meter")
    self.circleframe2:GetAnimState():SetBuild("status_meter")
    self.circleframe2:GetAnimState():PlayAnimation("frame")

    self.sanityarrow = self.underNumber:AddChild(UIAnim())
    self.sanityarrow:GetAnimState():SetBank("sanity_arrow")
    self.sanityarrow:GetAnimState():SetBuild("sanity_arrow")
    self.sanityarrow:GetAnimState():PlayAnimation("neutral")
    self.sanityarrow:SetClickable(false)

    self.effigyanim = self.underNumber:AddChild(UIAnim())
    self.effigyanim:GetAnimState():SetBank("status_health")
    self.effigyanim:GetAnimState():SetBuild("status_health")
    self.effigyanim:GetAnimState():PlayAnimation("effigy_deactivate")
    self.effigyanim:Hide()
    self.effigyanim:SetClickable(false)
    self.effigyanim.inst:ListenForEvent("animover", OnEffigyDeactivated)
    self.effigy = false
    self.effigybreaksound = nil

    self.corrosives = {}
    self._onremovecorrosive = function(debuff)
        self.corrosives[debuff] = nil
    end
    self.inst:ListenForEvent("startcorrosivedebuff", function(owner, debuff)
        if self.corrosives[debuff] == nil then
            self.corrosives[debuff] = true
            self.inst:ListenForEvent("onremove", self._onremovecorrosive, debuff)
        end
    end, owner)

    self.hots = {}
    self._onremovehots = function(debuff)
        self.hots[debuff] = nil
    end

    self:StartUpdating()
    self.healthpenalty = 0
end)

function WandaHealthBadge:ShowEffigy()
    if not self.effigy then
        self.effigy = true
        self.effigyanim:GetAnimState():PlayAnimation("effigy_activate")
        self.effigyanim:GetAnimState():PushAnimation("effigy_idle", false)
        self.effigyanim:Show()
    end
end

local function PlayEffigyBreakSound(inst, self)
    inst.task = nil
    if self:IsVisible() and inst.AnimState:IsCurrentAnimation("effigy_deactivate") then
        --Don't use FE sound since it's not a 2D sfx
        TheFocalPoint.SoundEmitter:PlaySound(self.effigybreaksound)
    end
end

function WandaHealthBadge:HideEffigy()
    if self.effigy then
        self.effigy = false
        self.effigyanim:GetAnimState():PlayAnimation("effigy_deactivate")
        if self.effigyanim.inst.task ~= nil then
            self.effigyanim.inst.task:Cancel()
        end
        self.effigyanim.inst.task = self.effigyanim.inst:DoTaskInTime(7 * FRAMES, PlayEffigyBreakSound, self)
    end
end

function WandaHealthBadge:SetPercent(val, max, penaltypercent)
	--self.num:SetString(tostring(math.floor(age + 0.5)))

    Badge.SetPercent(self, val, ((TUNING.WANDA_MAX_YEARS_OLD - TUNING.WANDA_MIN_YEARS_OLD)/(TUNING.OLDAGE_HEALTH_SCALE)))
end

function WandaHealthBadge:OnUpdate(dt)
    if self.pulsing == nil then
        local down
        if (self.owner.IsFreezing ~= nil and self.owner:IsFreezing()) or
            (self.owner.replica.health ~= nil and self.owner.replica.health:IsTakingFireDamageFull()) or
            (self.owner.replica.hunger ~= nil and self.owner.replica.hunger:IsStarving()) or
            next(self.corrosives) ~= nil then
            down = "_most"
        elseif self.owner.IsOverheating ~= nil and self.owner:IsOverheating() then
            down = self.owner:HasTag("heatresistant") and "_more" or "_most"
        end

        local up = down == nil and
            (next(self.hots) ~= nil) and self.owner.replica.health ~= nil and self.owner.replica.health:IsHurt()

        local anim =
            (down ~= nil and ("arrow_loop_decrease"..down)) or
            (not up and "neutral") or
            (next(self.hots) ~= nil and "arrow_loop_increase_most") or
            "arrow_loop_increase"

        if self.arrowdir ~= anim then
            self.arrowdir = anim
            self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
        end
    end
end

function WandaHealthBadge:PulseColor(r, g, b, a)
    self.pulse:GetAnimState():SetMultColour(r, g, b, a)
    self.pulse:GetAnimState():PlayAnimation("on")
    self.pulse:GetAnimState():PushAnimation("on_loop", true)
end

function WandaHealthBadge:PulseGreen()
    self:PulseColor(0, 1, 0, 1)
end

function WandaHealthBadge:PulseRed()
    self:PulseColor(1, 0, 0, 1)
end

function WandaHealthBadge:PulseOff()
    self.pulse:GetAnimState():SetMultColour(1, 0, 0, 1)
    self.pulse:GetAnimState():PlayAnimation("off")
    self.pulse:GetAnimState():PushAnimation("idle")
    TheFrontEnd:GetSound():KillSound("pulse_loop")

    self.pulsing = nil
end

function WandaHealthBadge:Pulse(color)
    local frontend_sound = TheFrontEnd:GetSound()
    
    if color == "green" then
        self:PulseGreen()
        frontend_sound:KillSound("pulse_loop")
        frontend_sound:PlaySound("wanda2/characters/wanda/up_health_LP", "pulse_loop")
        frontend_sound:PlaySound("dontstarve/HUD/health_up")
    else
        self:PulseRed()
        frontend_sound:KillSound("pulse_loop")
        frontend_sound:PlaySound("wanda2/characters/wanda/down_health_LP", "pulse_loop")
        frontend_sound:PlaySound("dontstarve/HUD/health_down")
    end

    self.pulsing = color
end

function WandaHealthBadge:HealthDelta(data)
    
    local oldpenalty = self.healthpenalty
    local health = self.owner.replica.health
    self.healthpenalty = health:GetPenaltyPercent()

    self:SetPercent(data.newpercent, health:Max(), self.healthpenalty)

    local should_pulse = nil

    if oldpenalty > self.healthpenalty or data.newpercent > data.oldpercent then
        should_pulse = "green"

        local anim = "arrow_loop_increase_most"

        if self.arrowdir ~= anim then
            self.arrowdir = anim
            self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
        end

    elseif oldpenalty < self.healthpenalty or data.newpercent < data.oldpercent then
        should_pulse = "red"

        local anim = "arrow_loop_decrease_most"

        if self.arrowdir ~= anim then
            self.arrowdir = anim
            self.sanityarrow:GetAnimState():PlayAnimation(anim, true)
        end
    end

    if should_pulse then
        if self.pulsing ~= nil then
            if should_pulse == self.pulsing then
                if self.turnofftask ~= nil then
                    self.turnofftask:Cancel()
                    self.turnofftask = nil
                end
            else
                if self.turnofftask ~= nil then
                    self.turnofftask:Cancel()
                    self.turnofftask = nil
                end

                self:Pulse(should_pulse)
            end
        else
            self:Pulse(should_pulse)
        end

        self.turnofftask = self.inst:DoTaskInTime(0.25, function() self:PulseOff() end)
    else
        if self.turnofftask ~= nil then
            self.turnofftask:Cancel()
            self.turnofftask = nil
        end
        self:PulseOff()
    end
end

return WandaHealthBadge
