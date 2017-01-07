--[[
  ~ Cannon Prop ~
  ~ Lexi ~
--]]
AddCSLuaFile("shared.lua")
ENT.Type           = "anim"
ENT.Base           = "base_anim"
ENT.PrintName      = "Prop Cannon Projectile"
ENT.Author         = "Lexi"               -- Fixed for gmod 13 by dvd_video
ENT.Contact        = "lexi@lexi.org.uk"   -- Email dvd_video@abv.bg
ENT.Spawnable      = false
ENT.AdminSpawnable = false

local pcnPrefx   = ENT.PrintName:gsub(" ", "_"):lower()
local pcnFvars   = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local varLogFile = CreateConVar(pcnPrefx.."logfile", "1", pcnFvars, "Enable logging in a file")
local varLogUsed = CreateConVar(pcnPrefx.."logused", "1", pcnFvars, "Enable logging on error")

if(not file.Exists("prop_cannon_tool","DATA") and varLogFile:GetBool()) then
  file.CreateDir("prop_cannon_tool")
end

function ENT:Print(...)
  if(not varLogUsed:GetBool()) then return end;
  local sLin = "["..os.date().."] "..self.PrintName.." > "..tostring(self)..":"
  if(varLogFile:GetBool()) then
    local sDel = "\t"
    local tData, nID = {...}, 1
    while(tData[nID]) do
      sLin, nID = sLin..sDel..tostring(tData[nID]), (nID + 1)
    end; file.Append("prop_cannon_tool/system_log.txt", sLin.."\n")
  else print(sLin,...) end
end

if(CLIENT) then
  language.Add("cannon_prop", ENT.PrintName)
  return;
end

function ENT:Initialize()
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid  (SOLID_VPHYSICS)

  if(not IsValid(self.Owner)) then
    self.Owner = self
    self:Print("ENT.Initialize: Created without a valid owner !")
  end

  self:SetPhysicsAttacker(self.Owner)

  local phys = self:GetPhysicsObject()
  if(phys and phys:IsValid()) then phys:Wake() end
  self:Print("ENT.Initialize: Success")
end

hook.Add("EntityTakeDamage", "cannon_prop kill crediting",
  function(ent, me, attack, amt, info)
    print("EntityTakeDamage: Call", ent, me, attack, amt, info)
    if(me.ClassName == "cannon_prop") then
      print("EntityTakeDamage: Class")
      info:SetAttacker(me.Owner)
      print("EntityTakeDamage: Attacker", me.Owner)
    end
    print("EntityTakeDamage: Success")
  end)

function ENT:Explode()
  if(self.exploded) then return end
  local pos = self:GetPos()
  if(not self.effectDataClass) then
    self:Print("ENT.Explode: Alloc")
    self.effectDataClass = EffectData()
  end; local effectData = self.effectDataClass
  effectData:SetStart(pos)
  effectData:SetOrigin(pos)
  effectData:SetScale(1)
  self:Print("ENT.Explode: Effect make")
  util.Effect("Explosion", effectData)
  self:Print("ENT.Explode: Effect blast")
  util.BlastDamage(self, self.Owner, pos, self.explosiveRadius, self.explosivePower)
  self:Print("ENT.Explode: Effect remove")
  self.exploded = true; self:Remove()
  self:Print("ENT.Explode: Success")
end

function ENT:OnTakeDamage(dmgInfo)
  if(self.explosive) then self:Explode() end
  self:TakePhysicsDamage(dmgInfo)
  self:Print("ENT.OnTakeDamage: Success", dmgInfo)
end

local function doBoom(self)
  if(self.explosive) then self:Explode() end
  self:Print("ENT.doBoom: Success")
end

-- Even a tiny flinch can set it off
ENT.Use            = doBoom
ENT.Touch          = doBoom
ENT.StartTouch     = doBoom
ENT.PhysicsCollide = doBoom

function ENT:Think()
  if(not self.dietime) then return end
  if(self.die) then self:Remove()
  elseif(self.dietime <= CurTime()) then
    self:Fire("break"); self.die = true
  end
end