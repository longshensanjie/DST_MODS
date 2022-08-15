GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

local function LoadAtlas(name)
    if name then
        for _, modname in ipairs(TheSim:GetModDirectoryNames()) do
            local filepath = string.gsub(MODS_ROOT .. modname .. "/images/avatars/avatar_" .. name .. ".xml", "\\", "/")
            if kleifileexists(filepath) then
                local prefabname = "Atlas_" .. name
                local character = name
                local saveslotpath = string.gsub(MODS_ROOT .. modname .. "/images/saveslot_portraits/" .. name .. ".xml", "\\", "/")
                if kleifileexists(saveslotpath) then
                    filepath = saveslotpath
                else
                    character = "avatar_" .. name
                end
                RegisterPrefabs(Prefab(prefabname, nil, {Asset("ATLAS", filepath)}, nil, true))
                TheSim:LoadPrefabs({prefabname})
                return filepath, character
            end
        end
    end
    return nil, "mod"
end

local default_portrait_atlas = "images/saveslot_portraits.xml"
local default_avatar = "unknown.tex"

AddClassPostConstruct("widgets/redux/serversaveslot", function(self)
	if self.character_portrait then
        self.character_portrait.SetCharacter = function(_, character_atlas, character)
            if character_atlas and character then
                if character == "mod" then
                    local atlas = nil
                    atlas, character = LoadAtlas(ShardSaveGameIndex:GetSlotCharacter(self.slot))
                    if atlas then
                        character_atlas = atlas
                    end
                end
                _.title_portrait:SetTexture(character_atlas, character .. ".tex")
            else
                _.title_portrait:SetTexture(default_portrait_atlas, default_avatar)
            end
        end
    end
end)