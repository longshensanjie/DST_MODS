local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/redux/templates"

local FACING_DOWN = GLOBAL.FACING_DOWN
local FACING_LEFT = GLOBAL.FACING_LEFT
local FACING_UP = GLOBAL.FACING_UP
local FACING_RIGHT = GLOBAL.FACING_RIGHT

local function PuppetRotato(self)
	if self.puppet ~= nil then
		self.current_facing = FACING_DOWN
		
		self.puppet.rotate_left = self.puppet_root:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "goto_url.tex", nil, false, false))
		self.puppet.rotate_right = self.puppet_root:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "goto_url.tex", nil, false, false))
		
		self.puppet.rotate_left:SetClickable(true)
		self.puppet.rotate_right:SetClickable(true)
		
		self.puppet.rotate_left:SetScale(-0.7, 0.7, 1)
		self.puppet.rotate_right:SetScale(0.7)

		self.puppet.rotate_left:SetPosition(-150, 20)
		self.puppet.rotate_right:SetPosition(150, 20)

		self.puppet.rotate_left:SetOnClick(function()
			if self.current_facing == FACING_DOWN then
				self.puppet.anim:SetFacing(FACING_LEFT)
				self.current_facing = FACING_LEFT
			elseif self.current_facing == FACING_LEFT then
				self.puppet.anim:SetFacing(FACING_UP)
				self.current_facing = FACING_UP
			elseif self.current_facing == FACING_UP then
				self.puppet.anim:SetFacing(FACING_RIGHT)
				self.current_facing = FACING_RIGHT
			elseif self.current_facing == FACING_RIGHT then
				self.puppet.anim:SetFacing(FACING_DOWN)
				self.current_facing = FACING_DOWN
			end
		end)
		
		self.puppet.rotate_right:SetOnClick(function()
			if self.current_facing == FACING_DOWN then
				self.puppet.anim:SetFacing(FACING_RIGHT)
				self.current_facing = FACING_RIGHT
			elseif self.current_facing == FACING_LEFT then
				self.puppet.anim:SetFacing(FACING_DOWN)
				self.current_facing = FACING_DOWN
			elseif self.current_facing == FACING_UP then
				self.puppet.anim:SetFacing(FACING_LEFT)
				self.current_facing = FACING_LEFT
			elseif self.current_facing == FACING_RIGHT then
				self.puppet.anim:SetFacing(FACING_UP)
				self.current_facing = FACING_UP
			end
		end)
	end
end

local function PuppetRotatoLoadOut(self)
	if self.puppet ~= nil then
		self.current_facing = FACING_DOWN
		
		self.puppet.rotate_left = self.puppet_root:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "goto_url.tex", nil, false, false))
		self.puppet.rotate_right = self.puppet_root:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "goto_url.tex", nil, false, false))
		
		self.puppet.rotate_left:SetClickable(true)
		self.puppet.rotate_right:SetClickable(true)
		
		self.puppet.rotate_left:SetScale(-0.7, 0.7, 1)
		self.puppet.rotate_right:SetScale(0.7)

		self.puppet.rotate_left:SetPosition(-150, -180)
		self.puppet.rotate_right:SetPosition(150, -180)

		self.puppet.rotate_left:SetOnClick(function()
			if self.current_facing == FACING_DOWN then
				self.puppet.anim:SetFacing(FACING_LEFT)
				self.current_facing = FACING_LEFT
			elseif self.current_facing == FACING_LEFT then
				self.puppet.anim:SetFacing(FACING_UP)
				self.current_facing = FACING_UP
			elseif self.current_facing == FACING_UP then
				self.puppet.anim:SetFacing(FACING_RIGHT)
				self.current_facing = FACING_RIGHT
			elseif self.current_facing == FACING_RIGHT then
				self.puppet.anim:SetFacing(FACING_DOWN)
				self.current_facing = FACING_DOWN
			end
		end)
		
		self.puppet.rotate_right:SetOnClick(function()
			if self.current_facing == FACING_DOWN then
				self.puppet.anim:SetFacing(FACING_RIGHT)
				self.current_facing = FACING_RIGHT
			elseif self.current_facing == FACING_LEFT then
				self.puppet.anim:SetFacing(FACING_DOWN)
				self.current_facing = FACING_DOWN
			elseif self.current_facing == FACING_UP then
				self.puppet.anim:SetFacing(FACING_LEFT)
				self.current_facing = FACING_LEFT
			elseif self.current_facing == FACING_RIGHT then
				self.puppet.anim:SetFacing(FACING_UP)
				self.current_facing = FACING_UP
			end
		end)
	end
end

AddClassPostConstruct("screens/redux/wardrobescreen", PuppetRotato)
AddClassPostConstruct("widgets/redux/loadoutselect", PuppetRotatoLoadOut)