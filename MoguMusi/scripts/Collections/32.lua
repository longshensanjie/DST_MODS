local G = GLOBAL
local function Drop()

	local player = G.ThePlayer
	if not player or player.prefab ~= "wortox" then return end

	if G.ThePlayer and not G.ThePlayer.HUD:IsChatInputScreenOpen() and not G.ThePlayer.HUD:IsConsoleScreenOpen() and not G.ThePlayer.HUD.writeablescreen then
		for i,v in pairs(G.ThePlayer.replica.inventory:GetItems()) do
			if v ~= nil and v.prefab == "wortox_soul" then         
			G.ThePlayer.replica.inventory:DropItemFromInvTile(v)  
			end 
		end 

		if (G.ThePlayer.replica.inventory:GetActiveItem()) then
			if G.ThePlayer.replica.inventory:GetActiveItem().prefab == "wortox_soul" then         
				G.ThePlayer.replica.inventory:DropItemFromInvTile(G.ThePlayer.replica.inventory:GetActiveItem())  
			end 
		end
		
	end
		return true
end

G.TheInput:AddKeyDownHandler(GetModConfigData("wortox_RELEASE_KEY"), Drop)



