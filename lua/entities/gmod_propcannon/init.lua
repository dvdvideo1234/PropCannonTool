--[[
  ~ Prop Cannon (server) ~
  ~ Lexi ~
--]]
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:Initialize()
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid  (SOLID_VPHYSICS)
  self.nextFire = CurTime()
  local phys = self:GetPhysicsObject()
  if(phys and phys:IsValid()) then phys:Wake() end
  if (WireLib) then
    WireLib.CreateSpecialInputs(self,{
      "FireOnce",
      "AutoFire"
    }, { "NORMAL", "NORMAL" }, {
      "Fire a single prop",
      "Fire repeatedly until released."
    })
    WireLib.CreateSpecialOutputs(self, {
      "ReadyToFire",
      "Fired",
      "AutoFiring",
      "LastBullet"
    }, { "NORMAL", "NORMAL", "NORMAL", "ENTITY"} , {
      "Is the cannon ready to fire again?",
      "Triggered every time the cannon fires.",
      "Is the cannon currently autofiring?",
      "The last prop fired"
    })
  end
end

ENT.fireForce       = 20000
ENT.cannonModel     = "models/props_trainstation/trashcan_indoor001b.mdl"
ENT.fireModel       = "models/props_junk/cinderblock01a.mdl"
ENT.recoilAmount    = 1
ENT.fireDelay       = 5
ENT.killDelay       = 5
ENT.explosivePower  = 10
ENT.explosiveRadius = 200
ENT.fireEffect      = "Explosion"
ENT.fireExplosives  = true

function ENT:Setup(fireForce     , cannonModel    , fireModel ,
                   recoilAmount  , fireDelay      , killDelay ,
                   explosivePower, explosiveRadius, fireEffect,
                   fireExplosives, fireDirection  , fireMass)
  self.fireForce       = math.Clamp(tonumber(fireForce) or 0, )
  self.cannonModel     = tostring(cannonModel or ""); self:SetModel(self.cannonModel)
  self.fireModel       = tostring(fireModel or "")
  self.recoilAmount    = math.Clamp(tonumber(recoilAmount) or 0,0,10)
  self.fireDelay       = math.Clamp(tonumber(fireDelay) or 0,0,50)
  self.killDelay       = math.Clamp(tonumber(killDelay) or 0,0,30)
  self.explosivePower  = math.Clamp(tonumber(explosivePower)  or 0,0,200)
  self.explosiveRadius = math.Clamp(tonumber(explosiveRadius) or 0,0,500)
  self.fireEffect      = tostring(fireEffect or "")
  self.fireExplosives  = tobool(fireExplosives)
  self.fireDirection   = Vector(); self.fireDirection:Set(fireDirection)
  self.fireMass        = math.Clamp(tonumber(fireMass) or 0,1,50000)
  if(self.fireDirection:Length() > 0) then self.fireDirection:Normalize()
  else self.fireDirection.z = 1 end -- Make sure length equal to 1
  self:SetOverlayText("- Prop Cannon -"..
                      "\nFiring Force    : "..RoundValue(self.fireForce,0.01)..
                      "\nFiring Direction: "..RoundValue(tostring(self.fireDirection),0.01)..
                      "\nFiring Delay    : "..RoundValue(self.fireDelay,0.01)..
                      "\nExplosive Area  : "..RoundValue(self.explosiveRadius,0.01)..
                      "\nBullet Model    : "..self.fireModel..
                      "\nBullet Weight   : "..RoundValue(self.fireMass)..
                      "\nExplosive Power("..(fireExplosives and "On " or "Off")"): "..RoundValue(explosivePower,0.01))
end

function self:GetFireDirection()
  local wdir = Vector(); wdir:Set(self.fireDirection)
        wdir:Rotate(self:GetAngles()); return wdir
end

function ENT:OnTakeDamage( dmginfo)
  self:TakePhysicsDamage(dmginfo)
end

function ENT:FireEnable()
  self.enabled = true
  self.nextFire = CurTime()
  if (WireLib) then
    WireLib.TriggerOutput(self, "AutoFiring", 1)
  end
end

function ENT:FireDisable()
  self.enabled = false
  if (WireLib) then
    WireLib.TriggerOutput(self, "AutoFiring", 0)
  end
end

function ENT:CanFire()
  return self.nextFire <= CurTime()
end

function ENT:Think()
  if(self:CanFire()) then
    if(WireLib) then
      WireLib.TriggerOutput(self, "ReadyToFire", 1) end
    if(self.enabled) then self:FireOne() end
  elseif (WireLib) then
    WireLib.TriggerOutput(self, "ReadyToFire", 0) end
end

function ENT:FireOne()
  self.nextFire = CurTime() + self.fireDelay
  local pos = self:GetPos()
  if (self.fireEffect ~= "" and self.fireEffect ~= "none") then
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetStart(pos)
    effectData:SetScale(1)
    util.Effect(self.fireEffect, effectData)
  end
  local ent = ents.Create("cannon_prop")
  if(not (ent and ent:IsValid())) then
    error("Could not create cannon_prop for firing!") end
  ent:SetPos(pos)
  ent:SetModel(self.fireModel)
  ent:SetAngles(self:GetAngles())
  ent:SetOwner(self) -- For collision and such.
  ent.Owner = self:GetPlayer() -- For kill crediting
  if (self.fireExplosives) then
    ent.explosive       = true
    ent.explosiveRadius = self.explosiveRadius
    ent.explosivePower  = self.explosivePower
  end
  if (self.killDelay > 0) then
    ent.dietime = CurTime() + self.killDelay end
  ent:Spawn()
  self:DeleteOnRemove(ent)
  local iPhys = self:GetPhysicsObject()
  local uPhys =  ent:GetPhysicsObject()
  local fidir = self:GetFireDirection()
  if(iPhys and iPhys:IsValid()) then -- The cannon could conceivably work without a valid physics model.
    iPhys:ApplyForceCenter(fidir * -self.fireForce * self.recoilAmount) end -- Recoil
  if (not (uPhys and uPhys:IsValid())) then -- The bullets can't though
    error("Invalid physics for model '" .. self.fireModel .. "' !!") end
  uPhys:SetMass(self.fireMass)
  uPhys:SetVelocityInstantaneous(self:GetVelocity()) -- Start the bullet off going like we be.
  uPhys:ApplyForceCenter(fidir * self.fireForce) -- Fire it off infront of us
  if (WireLib) then
    WireLib.TriggerOutput(self, "Fired", 1)
    WireLib.TriggerOutput(self, "LastBullet", ent)
    WireLib.TriggerOutput(self, "Fired", 0)
  end
end

function ENT:TriggerInput(key, value)
  if (key == "FireOnce" and value ~= 0) then
    self:FireOne()
  elseif (key == "AutoFire") then
    if (value == 0) then
      self:FireDisable()
    else self:FireEnable() end
  end
end


local function On( ply, ent )
  if(not (ent and ent:IsValid())) then return end
  ent:FireEnable()
end

local function Off( pl, ent )
  if(not (ent and ent:IsValid())) then return end
  ent:FireDisable()
end

numpad.Register( "propcannon_On",  On )
numpad.Register( "propcannon_Off", Off )