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

local pcnPrefx   = ENT.PrintName:gsub(" ", ""):lower()
local pcnFvars   = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local varLogFile = CreateConVar(pcnPrefx.."logfile", "1", pcnFvars, "Enable logging in a file")
local varLogUsed = CreateConVar(pcnPrefx.."logused", "1", pcnFvars, "Enable logging on error")
function ENT:Print(...)
  if(not varLogUsed:GetBool()) then return end;
  local sLin = "["..os.date().."] "..self.PrintName.." > "..tostring(self)..":"
  if(varLogFile:GetBool()) then
    local sDel = "\t"
    local tData, nID, {...}, 1
    while(tData[nID]) do
      sLin, nID = sLin..sDel..tostring(tData[nID]), (nID + 1)
    end; file.Append(pcnPrefx.."/".."system_log.txt", sLin.."\n")
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
    self:Print("EntityTakeDamage: Call",ent, me, attack, amt, info)
    if(me.ClassName == "cannon_prop") then
      self:Print("EntityTakeDamage: Class")
      info:SetAttacker(me.Owner)
      self:Print("EntityTakeDamage: Attacker", me.Owner)
    end
    self:Print("EntityTakeDamage: Success")
  end)

function ENT:Explode()
  if(self.exploded) then return end
  local pos = self:GetPos()
  self:Print("ENT.Explode: Alloc")
  local effectData = EffectData()
  effectData:SetStart(pos)
  effectData:SetOrigin(pos)
  effectData:SetScale(1)
  self:Print("ENT.Explode: Effect")
  util.Effect("Explosion", effectData);
  util.BlastDamage(self, self.Owner, pos, self.explosiveRadius, self.explosivePower)
  self.exploded = true; self:Remove()
  self:Print("ENT.Explode: Success")
end

function ENT:OnTakeDamage(damageInfo)
  if(self.explosive) then self:Explode() end
  self:TakePhysicsDamage(damageInfo)
  self:Print("ENT.OnTakeDamage: Success", damageInfo)
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