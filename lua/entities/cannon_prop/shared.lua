--[[
  ~ Cannon Prop ~
  ~ lexi ~ Ported to Gmod 13 by dvd_video
--]]

AddCSLuaFile("shared.lua")

ENT.Type           = "anim"
ENT.Base           = "base_anim"
ENT.PrintName      = "Prop Cannon Projectile"
ENT.Author         = "Lexi"               -- Fixed for gmod 13 by dvd_video
ENT.Contact        = "lexi@lexi.org.uk"   -- Email dvd_video@abv.bg
ENT.Spawnable      = false
ENT.AdminSpawnable = false

local gsUnit     = "propcannon"
local varLogFile = GetConVar(gsUnit.."_logfile")
local varLogUsed = GetConVar(gsUnit.."_logused")
local gsFormHead = "[%s] %s > %s: "
local gsFormItem = " {%s}"

AddCSLuaFile(gsUnit.."/wire_wrapper.lua")
include(gsUnit.."/wire_wrapper.lua")

if(not file.Exists(gsUnit.."_tool","DATA")) then
  file.CreateDir(gsUnit.."_tool")
end

function ENT:Print(...)
  if(not varLogUsed:GetBool()) then return end;
  local sD = os.date("%y-%m-%d").." "..os.date("%H:%M:%S")
  local sI = (SERVER and "SERVER" or (CLIENT and "CLIENT" or "NOINST"))
  local sL = gsFormHead:format(sD, sI, tostring(self))
  if(varLogFile:GetBool()) then local tD, iD = {...}, 1
    sL = sL..tostring(tD[1]); iD = (iD + 1)
    while(tD[iD]) do local sS = tostring(tD[iD])
      sL, iD = sL..gsFormItem:format(sS), (iD + 1) end
    file.Append(gsUnit.."_tool/system_log.txt", sL.."\n")
  else print(sL, ...) end
end

if(CLIENT) then
  language.Add("cannon_prop", ENT.PrintName)
  return;
end

function ENT:Initialize()
  self:Print("ENT.Initialize: Start")
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  if(not IsValid(self.Owner)) then self.Owner = self end
  self.effectDataClass = EffectData()
  self:SetPhysicsAttacker(self.Owner)
  self.exploded = false
  local phys = self:GetPhysicsObject()
  if(phys and phys:IsValid()) then phys:Wake() end

  self:WireCreateInputs({"Explode", "NORMAL", "Trigger this to create an explosion"})
  self:Print("ENT.Initialize: Success")
end

hook.Add("EntityTakeDamage", gsUnit.."_crediting",
  function(ent, info) -- Called when something gets damaged by it
    local me = info:GetInflictor() -- Returns the inflictor of the damage
    if(not (me and me:IsValid())) then return end -- Bail when not valid
    if(me:GetClass() == "cannon_prop") then info:SetAttacker(me.Owner) end
  end)

function ENT:Explode(dmgInfo)
  if(self.exploded) then return end
  self:Print("ENT.Explode: Start")
  -- Make sure we set the explode flag here, otherwise recursion
  -- will take place in `OnTakeDamage` and the game will crash !
  self.exploded = true -- The `exploded` flag is right where it needs to be
  local own = self.Owner
  local pos = self:GetPos()
  local eff = self.effectDataClass
  local pow = self.explosivePower
  local rad = self.explosiveRadius
  if(eff) then -- Use the cached effect
    eff:SetStart(pos)
    eff:SetOrigin(pos)
    eff:SetScale(1)
    util.Effect("Explosion", eff)
  end
  if(self and self:IsValid() and util.IsInWorld(pos) and
     own and own:IsValid() and rad > 0 and pow > 0)
  then -- This will call `OnTakeDamage` internally and trigger a chain explosions
    if(dmgInfo) then -- When damage information is passed `OnTakeDamage`
      util.BlastDamageInfo(dmgInfo, pos, rad)
    else -- When there is no damage information present
      util.BlastDamage(self, own, pos, rad, pow)
    end
    self:Print("ENT.Explode: Blast conditions OK", dmgInfo)
  else
    self:Print("ENT.Explode: Blast conditions not met !")
  end
  self:Remove()
  self:Print("ENT.Explode: Success")
end

function ENT:OnTakeDamage(dmgInfo)
  if(self.explosive) then self:Explode(dmgInfo) end
  self:TakePhysicsDamage(dmgInfo)
end

function ENT:Think()
  local wE = self:WireRead("Explode", true)
  if(wE and wE ~= 0) then self:Explode() end
  if(not self.dietime) then return end
  if(self.die) then self:Remove()
  elseif(self.dietime <= CurTime()) then
    self:Fire("break"); self.die = true
  end
end

local function doBoom(self)
  if(not (self and self:IsValid())) then return end
  if(self.explosive) then self:Explode() end
end

-- Even a tiny flinch can set it off
ENT.Use            = doBoom
ENT.Touch          = doBoom
ENT.StartTouch     = doBoom
ENT.PhysicsCollide = doBoom
