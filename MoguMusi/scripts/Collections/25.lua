local judge = GetModConfigData("sw_nickname")

local show_oneself = false
if judge == "all" then show_oneself = true end


if not TUNING.SHOW_PLAYERS_NICKNAMES then
	TUNING.SHOW_PLAYERS_NICKNAMES = true
	AddPlayersAfterInit(function(inst)
		if inst == GLOBAL.ThePlayer and not show_oneself then
			return
		end
		inst.GetMyDisplayName = function(inst)
			return inst:GetDisplayName()
		end
		local label = inst.entity:AddLabel()
	   
		label:SetFontSize(18)         
		label:SetFont(GLOBAL.BODYTEXTFONT)
		label:SetWorldOffset(0, 2.3, 0)       --
	 
		local Name = inst:GetMyDisplayName()
		--if IsAdmin(Name) then Name ="" end
		label:SetText(Name)              ----default = ""
		label:SetColour(255/255,255/255,255/255)               --  default = "(255/255,255/255,255/255)"
		label:Enable(true)                     --default = "false"
		
		--Change name dynamically (because of Health Info mod)
		inst:DoPeriodicTask(0.1+math.random()*0.01,function()
			local new_name = inst:GetMyDisplayName()
			if Name ~= new_name and type(new_name) == "string" then
				Name = new_name
				label:SetText(Name)
			end
		end)
	end)
end
