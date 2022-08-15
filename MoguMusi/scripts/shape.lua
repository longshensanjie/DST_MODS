local shape = Class(function()
    self.space = 2
    self.length = 7.5
    self.step = 8
    self.rot_c = 0
    self.rot_s = 0
    self.center_x = 0
    self.center_z = 0
end)
function shape:SetParams()
    local a, b, c, d = ThePlayer.components.RoundDeploy:GetParams()
    self.length = a
    self.step = tonumber(360 / b) or 8
    self.rot_c = math.cos(math.rad(c))
    self.rot_s = math.sin(math.rad(c))
    self.space = tonumber(d)
    self.center_x = ThePlayer.components.RoundDeploy.Center_x
    self.center_z = ThePlayer.components.RoundDeploy.Center_z
end
function shape:PPD(x1, y1, x2, y2)--Point to point distance
    if math.abs(x2) > self.space / 2 then
        return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2) > self.space
    else
        return false
    end
end
function shape:rot(x, y)
    return x * self.rot_c - y * self.rot_s, x * self.rot_s + y * self.rot_c
end
function shape:GetCirclePosition()
    self:SetParams()
    local pos = {}
    for Angle = 0, 360, self.step do
        local theta = math.rad(Angle)
        local s = math.sin(theta)
        local c = math.cos(theta)
        local r = self.length
        local x, z = self:rot(r * c, r * s)
        table.insert(pos, Vector3(x + self.center_x, 0, z + self.center_z))
    end
    return pos
end
function shape:GetCardioidPosition()
    self:SetParams()
    local pos = {}
    local pos2 = {}
    local x1, y1, st = 0, 0, 0
    for i = math.pi / 2, math.pi * 3 / 2, 0.1 do
        local s = math.sin(i)
        local c = math.cos(i)
        local r = self.length * ((s * math.sqrt(math.abs(c))) / (s + 7 / 5) - 2 * s + 2)
        x1 = r * c
        if math.abs(x1) > self.space / 2 then
            y1 = r * s
            local nx1, ny1 = self:rot(x1, y1)
            local top_x, top_y = self:rot(0, y1 - math.abs(x1) * 2 * math.cos(math.pi / 6))
            table.insert(pos, Vector3(self.center_x - top_x, 0, self.center_z + top_y))
            table.insert(pos, Vector3(nx1 + self.center_x, 0, ny1 + self.center_z))
            local nnx1, nny1 = self:rot(0 - x1, y1, self.rotate)
            table.insert(pos2, Vector3(self.center_x + nnx1, 0, nny1 + self.center_z))
            st = i
            break
        end
    end
    for i = st, math.pi * 3 / 2, math.pi / 360 do
        local s = math.sin(i)
        local c = math.cos(i)
        local r = self.length * ((s * math.sqrt(math.abs(c))) / (s + 7 / 5) - 2 * s + 2)
        local x2 = r * c
        local y2 = r * s
        if self:PPD(x1, y1, x2, y2) then
            x1 = x2
            y1 = y2
            local nx1, ny1 = self:rot(x1, y1)
            table.insert(pos, Vector3(nx1 + self.center_x, 0, ny1 + self.center_z))
            local nnx1, nny1 = self:rot(0 - x1, y1, self.rotate)
            table.insert(pos2, Vector3(self.center_x + nnx1, 0, nny1 + self.center_z))
        end
    end
    local bottom_x, bottom_y = self:rot(0, y1 - math.abs(x1) * 2 * math.cos(math.pi / 6))

    table.insert(pos, Vector3(self.center_x + bottom_x, 0, self.center_z + bottom_y))
    for _, v in pairs(pos2) do
        table.insert(pos, v)
    end
    return pos
end

function shape:GetStraightPosition()
    self:SetParams()
    local pos = {}
    local length
    local num = math.floor(self.length / self.space)
    if num % 2 == 0 then
        length = (num - 1) * (self.space + 0.002) / 2
    else
        length = (num - 1) * (self.space + 0.002) / 2
    end
    for i = -length, length, self.space + 0.001 do
        local x, y = self:rot(0, i)
        table.insert(pos, Vector3(self.center_x + x, 0, self.center_z + y))
    end
    return pos
end

function shape:GetSquarePosition()
    self:SetParams()
    local pos = {}
    local length
    local num = math.floor(self.length / self.space)
    if num % 2 == 0 then
        length = (num - 1) * (self.space + 0.002) / 2
    else
        length = (num - 1) * (self.space + 0.002) / 2
    end
    for i = -length, length, self.space + 0.001 do
        for j = -length, length, self.space + 0.001 do
            local x, y = self:rot(i, j)
            table.insert(pos, Vector3(self.center_x + x, 0, self.center_z + y))
        end
    end
    return pos
end
return shape