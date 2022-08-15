local mount,moodmult,beardmult,domesticmult,lastmounted
AddPlayerPostInit(function(inst)
	inst:ListenForEvent("isridingdirty", function(inst)
		if inst ~= GLOBAL.ThePlayer then return end
		if not inst.replica.rider then return end 
		if inst.replica.rider._isriding:value() then
			if lastmounted == nil then
				lastmounted = GLOBAL.GetTime()

				inst:DoTaskInTime(GLOBAL.FRAMES, function(inst)
					mount = inst.replica.rider.classified ~= nil and inst.replica.rider.classified.ridermount:value()

					if type(mount) == "table" and mount.prefab == "beefalo" then
						moodmult = mount:HasTag("scarytoprey") and GLOBAL.TUNING.BEEFALO_BUCK_TIME_MOOD_MULT or 1
						beardmult = not mount:HasTag("has_beard") and GLOBAL.TUNING.BEEFALO_BUCK_TIME_NUDE_MULT or 1
						domesticmult = not mount:HasTag("domesticated") and GLOBAL.TUNING.BEEFALO_BUCK_TIME_UNDOMESTICATED_MULT or 1
					end
				end)
			end
		else
			local ridetime = nil

			if lastmounted ~= nil then
				ridetime = GLOBAL.GetTime() - lastmounted
				lastmounted = nil
			end

			if type(mount) == "table" and mount.prefab == "beefalo" and ridetime ~= nil then
				local basedelay = ridetime / moodmult / beardmult / domesticmult
				local domestication = GLOBAL.Remap(basedelay, GLOBAL.TUNING.BEEFALO_MIN_BUCK_TIME, GLOBAL.TUNING.BEEFALO_MAX_BUCK_TIME, 0, 1)

				if inst.AnimState:IsCurrentAnimation("buck") or inst.AnimState:IsCurrentAnimation("buck_pst") then
                    TIP("牛牛驯化度预测", "blue", string.format("大概 %.2f%%", domestication * 100), "chat")
					-- print(string.format("Recorded %.2f second ride time for \"%s\" (%s domestication)", ridetime, mount.name, domestication))
				elseif not mount:HasTag("domesticated") and domestication > 0 then
                    TIP("牛牛驯化度预测", "blue", string.format("本次骑行时间%.2f秒, 驯化度大约 %.2f%%",ridetime, domestication * 100), "chat")
				end
			end
		end
	end)
end)
