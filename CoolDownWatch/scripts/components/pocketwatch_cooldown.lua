local PocketWatch_CoolDown = Class(function(self, inst)
    self.inst = inst
    self.oncooldownfn = nil
    self.iscooldownflag = false
end)

function PocketWatch_CoolDown:SetOnCoolDownFn(fn)
    self.oncooldownfn = fn
end

function PocketWatch_CoolDown:IsCoolDownFlag()
    return self.iscooldownflag
end


function PocketWatch_CoolDown:CanCoolDown(target, doer, invobject)
	if target.components.rechargeable ~= nil and target.components.rechargeable:IsCharged() then
        print("shibai")
        return false, "ONCOOLDOWNING"
    end
	if not doer:HasTag("clockmaker") then
        print("shibai2")
		return false
	end
    if target.components.pocketwatch_cooldown then
        print("shibai3")
		return false
    end
    if not invobject.components.pocketwatch.inactive then
        print("shibai4")
		return false
    end
    if target.components.weapon then
        print("shibai5  jinggaobiao")
        return false
    end
    if target.GetActionVerb_CAST_POCKETWATCH == "WARP" then
        print("shibai5  daozoubiao")
        return false
    end  
    return true
end

function PocketWatch_CoolDown:CoolDown(doer, target)
    print("进行冷切动作")
    doer.components.pocketwatch.inactive = true
    doer.components.rechargeable:Discharge(0)
    doer.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
    self.inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_RECALL_COOLDOWN)
    self.inst.components.pocketwatch.inactive = false
    if self.ondismantlefn ~= nil then
        self.oncooldownfn(doer)
    end
end


return PocketWatch_CoolDown
