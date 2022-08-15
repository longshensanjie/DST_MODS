local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local scale = 0
	if TUNING.MACHIN == "winona_catapult" then
		scale = 1.55
	elseif TUNING.MACHIN == "firesuppressor" then
		scale = 1.48
	elseif TUNING.MACHIN == "lightning_rod" then
		scale = 2.53
	-- elseif
	-- 	scale = 1.09
	end
	
    trans:SetScale(scale,scale,scale)
	
    anim:SetBank("firefighter_placement")
    anim:SetBuild("firefighter_range")
    anim:PlayAnimation("idle")
    
	anim:SetOrientation( ANIM_ORIENTATION.OnGround )
    anim:SetLayer( LAYER_BACKGROUND )
    anim:SetSortOrder( 3 )
	
	inst.persists = false
    inst:AddTag("fx")
	inst:AddTag("range_indicator")
    
	if TUNING.SHOW_RANGE_TIME and TUNING.SHOW_RANGE_TIME > 0 then
		inst:DoTaskInTime(TUNING.SHOW_RANGE_TIME, function() inst:Remove() end)
	end
	
    return inst
end

return Prefab( "common/range_indicator", fn) 