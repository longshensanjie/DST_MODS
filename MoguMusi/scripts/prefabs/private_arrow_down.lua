local assets=
{
	Asset("ANIM", "anim/private_anim.zip")	  
}

local function SetScale(inst,n)
	inst.Transform:SetScale(n,n,n)
end

local function PlayAnim(inst,anim,bool)
	inst.AnimState:PlayAnimation(anim,bool)
end

local function pos(inst,add_x,add_y)
	local x,y,z = inst.Transform:GetWorldPosition()
	inst.Transform:SetPosition(x+add_x,y,z+add_y)
end

local function fn_private_arrow_down(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	inst.SetScale = SetScale
	--inst.Transform:SetRotation(45)
	inst.pos = pos

	
	anim:SetBank("bank")
	anim:SetBuild("private_anim")
	anim:PlayAnimation("green") --red/green/blue, circle, left/right, up
	inst.PlayAnim = PlayAnim
	
	--anim:SetOrientation( ANIM_ORIENTATION.OnGround )
	--anim:SetLayer( LAYER_BACKGROUND )
	anim:SetSortOrder( 3 )
	
	inst.persists = false
	inst:AddTag("fx")
	inst:AddTag("notarget")
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	--inst:AddTag("DECOR")

	return inst
end


local SCALE_RAD = { 
	1.3, 1.8, 2.4, 2.55, 2.84, 3.11, 3.34, 3.6, 3.81, 4, 4.2, 4.39, 4.56, 4.75, 4.9, -- 1-15
}
local function SetRadius(inst,r)
	local scale = SCALE_RAD[r] or 1
	-- 这么乱的代码，艹
	if r == 3.5 then scale = 2.33 end
	if r == 7.5 then scale = 3.49 end
	if r == 3.8 then scale = 2.7 end
	if r == 4.25 then scale = 2.6 end
	if r == 4.5 then scale = 2.7 end
	if r == 18 then scale = 5.8 end
	if r == 666 then scale = 1.43 end
	if r == 777 then scale = 0.4 end
	inst.Transform:SetScale(scale,scale,scale)
end

local function fn_private_circle(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	inst.SetScale = SetScale
	inst.SetRadius = SetRadius
	--inst.Transform:SetRotation(45)
	inst.pos = pos
	inst.colours={1,1,1,1} --default inst.AnimState:OverrideMultColour
	
	anim:SetBank("bank")
	anim:SetBuild("private_anim")
	anim:PlayAnimation("circle") --red/green/blue, circle, left/right, up
	inst.PlayAnim = PlayAnim
	
	anim:SetOrientation( ANIM_ORIENTATION.OnGround )
	anim:SetLayer( LAYER_BACKGROUND )
	anim:SetSortOrder( 3 )
	
	inst.persists = false
	inst:AddTag("fx")
	inst:AddTag("notarget")
	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	--inst:AddTag("DECOR")

	return inst
end



return Prefab( "common/private_arrow_down", fn_private_arrow_down, assets) 
	,Prefab( "common/private_circle", fn_private_circle, assets)