--[[
  ~ Prop Cannon (shar'd) ~
  ~ lexi ~ Ported to Gmod 13 by dvd_video
--]]

ENT.Type            = "anim"
ENT.PrintName       = "Prop Cannon Gun"
if (WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.PrintName
else
  ENT.Base          = "base_gmodentity"
end
ENT.Author          = "Lexi"              -- Fixed for gmod13 dvd_video
ENT.Contact         = "lexi@lexi.org.uk"  -- dvd_video@abv.bg
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

local gsUnit = PCannonLib.GetUnit()

if(CLIENT) then
  language.Add("gmod_propcannon", ENT.PrintName)
end

AddCSLuaFile(gsUnit.."/wire_wrapper.lua")
include(gsUnit.."/wire_wrapper.lua")

if(not file.Exists(gsUnit.."_tool","DATA")) then
  file.CreateDir(gsUnit.."_tool")
end

function ENT:BulletAng(ent, dir)
  if(not ent) then return end
  if(not ent:IsValid()) then return end
  local aim = ent.CannonAimAxis -- Bullet local vector
  local vec, anc = ent:GetUp(), ent:GetAngles()
  if(aim) then vec:Set(aim); vec:Rotate(anc) end
  ent:SetAngles(ent:AlignAngles(vec:Angle(), dir:Angle()))
end

function ENT:GetBulletBase(dir, mar)
  local obb = self:OBBCenter()
  local bps = self:LocalToWorld(obb)
  local ang = self:GetAngles()
  local muv = Vector(dir); muv:Rotate(ang)
  local mar = PCannonLib.GetRadius(mar)
  muv:Mul(self:BoundingRadius() * mar)
  bps:Add(muv); return bps
end

function ENT:BulletPos(ent, pos, dir, mar)
  if(not ent) then return end
  if(not ent:IsValid()) then return end
  local eps, ean = Vector(pos), ent:GetAngles()
  local mar = PCannonLib.GetRadius(mar)
  local era = ent:BoundingRadius() * mar
  local cra = self:BoundingRadius() * mar
  local eob = ent:OBBCenter(); eob:Rotate(ean)
  eps:Add((cra + era) * dir); eps:Sub(eob)
  ent:SetPos(eps)
end

function ENT:Print(...)
  PCannonLib.Print(self, ...)
end
