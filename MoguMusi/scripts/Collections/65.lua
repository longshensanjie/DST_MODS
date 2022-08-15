if not GetModConfigData("wanda_display") then return end
local WandaHealthBadge = require("widgets/wandahealthbadge")
local HealthBadge = require("widgets/healthbadge")

local WandaAgeBadge = require("widgets/wandaagebadge")
local WandaHealthBadge = require("widgets/healthbadge")
local Location = 2
local Blood = 1
local Keep = 1
local Combinde_mods = 2

if GetModConfigData("wanda_display") == "60HP" then
	Blood = 1
else
	Blood = 2
end


local function addHelloWidget(self,owner)
	if owner:HasTag("clockmaker") then
		--owner.hello = self:AddChild(WandaAgeBadge(owner))-- 为controls添加hello widget。
		--owner.hello:SetPosition(self.stomach:GetPosition().x -84, self.stomach:GetPosition().y +15, 0) -- 设置hello widget相对原点的偏移量，70，-50表明向右70，向下50，第三个参数无意义。
		--local oldSetHealthPercent=self.SetHealthPercent
		--self.SetHealthPercent = function(self,pct)
		--	local health = self.owner.replica.health
		--	self.healthpenalty = health:GetPenaltyPercent()
		--	self.heart:SetPercent(pct, health:Max(), self.healthpenalty)
		--	owner.hello:SetPercent(pct, health:Max(), self.healthpenalty)
		--	if pct <= (self.heart.warning_precent or .33) then
		--		self.heart:StartWarning()
		--	else
		--		self.heart:StopWarning()
		--	end
		--end
		local oldSetGhostMode=self.SetGhostMode
		self.SetGhostMode = function(self,ghostmode)
		    if not self.isghostmode == not ghostmode then --force boolean
				return
			elseif ghostmode then
				self.isghostmode = true

				self.heart:Hide()
				self.stomach:Hide()
				self.brain:Hide()
				self.moisturemeter:Hide()
				self.boatmeter:Hide()

				self.heart:StopWarning()
				self.stomach:StopWarning()
				self.brain:StopWarning()
				
				if owner.hello ~= nil then
					owner.hello:Hide()
				end
				
				if self.wereness ~= nil then
					self.wereness:Hide()
					self.wereness:StopWarning()
				end

				if self.pethealthbadge ~= nil then
					self.pethealthbadge:Hide()
				end

				if self.inspirationbadge ~= nil then
					self.inspirationbadge:Hide()
				end
			else
				self.isghostmode = nil

				self.heart:Show()
				self.stomach:Show()
				self.brain:Show()
				self.moisturemeter:Show()
				self.boatmeter:Show()
				
				if owner.hello ~= nil then
					owner.hello:Show()
				end

				if self.wereness ~= nil then
					self.wereness:Show()
				end

				if self.pethealthbadge ~= nil then
					self.pethealthbadge:Show()
				end

				if self.inspirationbadge ~= nil then
					self.inspirationbadge:Show()
				end
			end

			if self.rezbuttontask ~= nil then
				self.rezbuttontask:Cancel()
				self.rezbuttontask = nil
			end
			self:EnableResurrect(self.owner.components.attuner ~= nil and self.owner.components.attuner:HasAttunement("remoteresurrector"))

			if self.modetask ~= nil then
				self.modetask:Cancel()
			end
			self.modetask = self.inst:DoTaskInTime(0, ghostmode and OnSetGhostMode or OnSetPlayerMode, self)
		end
	end
end

local function addHelloWidgeth60(self,owner)
	if owner:HasTag("clockmaker") then
		--owner.hello = self:AddChild(WandaAgeBadge(owner))-- 为controls添加hello widget。
		--owner.hello:SetPosition(self.stomach:GetPosition().x -84, self.stomach:GetPosition().y +15, 0) -- 设置hello widget相对原点的偏移量，70，-50表明向右70，向下50，第三个参数无意义。
		local oldSetHealthPercent=self.SetHealthPercent
		self.SetHealthPercent = function(self,pct)
			local health = self.owner.replica.health
			self.healthpenalty = health:GetPenaltyPercent()
			self.heart:SetPercent(pct, health:Max(), self.healthpenalty)
			if owner.hello ~= nil then
				owner.hello:SetPercent(pct, health:Max(), self.healthpenalty)
			end
			if pct <= (self.heart.warning_precent or .33) then
				self.heart:StartWarning()
			else
				self.heart:StopWarning()
			end
		end
	end
end

local function addHelloWidgeth150(self,owner)
	if owner:HasTag("clockmaker") then
		--owner.hello = self:AddChild(WandaAgeBadge(owner))-- 为controls添加hello widget。
		--owner.hello:SetPosition(self.stomach:GetPosition().x -84, self.stomach:GetPosition().y +15, 0) -- 设置hello widget相对原点的偏移量，70，-50表明向右70，向下50，第三个参数无意义。
		local oldSetHealthPercent=self.SetHealthPercent
		self.SetHealthPercent = function(self,pct)
			local health = self.owner.replica.health
			self.healthpenalty = health:GetPenaltyPercent()
			self.heart:SetPercent(pct, health:Max()*2.5, self.healthpenalty*2.5)
			if owner.hello ~= nil then
				owner.hello:SetPercent(pct, health:Max(), self.healthpenalty)
			end
			if pct <= (self.heart.warning_precent or .33) then
				self.heart:StartWarning()
			else
				self.heart:StopWarning()
			end
		end
	end
end

local function addHelloWidgeta150(self,owner)
	if owner:HasTag("clockmaker") then
		--owner.hello = self:AddChild(WandaAgeBadge(owner))-- 为controls添加hello widget。
		--owner.hello:SetPosition(self.stomach:GetPosition().x -84, self.stomach:GetPosition().y +15, 0) -- 设置hello widget相对原点的偏移量，70，-50表明向右70，向下50，第三个参数无意义。
		local oldSetHealthPercent=self.SetHealthPercent
		self.SetHealthPercent = function(self,pct)
			local health = self.owner.replica.health
			self.healthpenalty = health:GetPenaltyPercent()
			self.heart:SetPercent(pct, health:Max(), self.healthpenalty)
			if owner.hello ~= nil then
				owner.hello:SetPercent(pct, health:Max()*2.5, self.healthpenalty*2.5)
			end
			if pct <= (self.heart.warning_precent or .33) then
				self.heart:StartWarning()
			else
				self.heart:StopWarning()
			end
		end
	end
end

if Keep == 1 then
	if Combinde_mods == 2 then
		AddClassPostConstruct("widgets/statusdisplays", function (self,owner)
			if owner:HasTag("clockmaker") then
				owner.hello = self:AddChild(WandaHealthBadge(owner))
				owner.hello:SetPosition(self.stomach:GetPosition().x -62, self.stomach:GetPosition().y, 0)
			end
		end)
	else
		if Location == 1 then
			AddClassPostConstruct("widgets/statusdisplays", function (self,owner)
				if owner:HasTag("clockmaker") then
					owner.hello = self:AddChild(WandaHealthBadge(owner))
					owner.hello:SetPosition(self.stomach:GetPosition().x +40, self.stomach:GetPosition().y -72, 0)
				end
			end)
		elseif Location == 2 then
			AddClassPostConstruct("widgets/statusdisplays", function (self,owner)
				if owner:HasTag("clockmaker") then
					owner.hello = self:AddChild(WandaHealthBadge(owner))
					owner.hello:SetPosition(self.stomach:GetPosition().x -84, self.stomach:GetPosition().y +15, 0)
				end
			end)
		elseif Location == 3 then
			AddPrefabPostInit("wanda", function(inst)inst.CreateHealthBadge = WandaHealthBadge end)
			AddClassPostConstruct("widgets/statusdisplays", function (self,owner)
				if owner:HasTag("clockmaker") then
					owner.hello = self:AddChild(WandaAgeBadge(owner))
					owner.hello:SetPosition(self.stomach:GetPosition().x -84, self.stomach:GetPosition().y +15, 0)
				end
			end)
		end
	end
else
	AddPrefabPostInit("wanda", function(inst)inst.CreateHealthBadge = WandaHealthBadge end)
end

if Location == 3 or Keep == 2 then
	if Blood == 1 then
		AddClassPostConstruct("widgets/statusdisplays", addHelloWidgeth60) -- 这个函数是官方的MOD API，用于修改游戏中的类的构造函数。第一个参数是类的文件路径，根目录为scripts。第二个自定义的修改函数，第一个参数固定为self，指代要修改的类。
	else
		AddClassPostConstruct("widgets/statusdisplays", addHelloWidgeth150)
	end
else
	if Blood == 1 then
		AddClassPostConstruct("widgets/statusdisplays", addHelloWidgeth60) -- 这个函数是官方的MOD API，用于修改游戏中的类的构造函数。第一个参数是类的文件路径，根目录为scripts。第二个自定义的修改函数，第一个参数固定为self，指代要修改的类。
	else
		AddClassPostConstruct("widgets/statusdisplays", addHelloWidgeta150)
	end
end
AddClassPostConstruct("widgets/statusdisplays", addHelloWidget)