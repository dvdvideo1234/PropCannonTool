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
ENT.recoilAmount    = 0
ENT.fireDelay       = 5
ENT.killDelay       = 5
ENT.explosivePower  = 10
ENT.explosiveRadius = 200
ENT.fireEffect      = "Explosion"
ENT.fireExplosives  = true
ENT.fireMass        = 120 -- Mass with optimal distance for projectile
ENT.fireDirection   = Vector(0,0,1) -- Default UP

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
  self.fireMass        = math.Clamp(tonumber(fireMass) or 0,1,50000)
  self.fireDirection:Set(fireDirection)
  if(self.fireDirection:Length() > 0) then self.fireDirection:Normalize()
  else self.fireDirection.z = 1 end -- Make sure length equal to 1
  self:SetOverlayText("- Prop Cannon -"..
                      "\nFiring Force    : "..pcnRoundValue(self.fireForce,0.01)..
                      "\nFiring Direction: "..pcnRoundValue(tostring(self.fireDirection),0.01)..
                      "\nFiring Delay    : "..pcnRoundValue(self.fireDelay,0.01)..
                      "\nExplosive Area  : "..pcnRoundValue(self.explosiveRadius,0.01)..
                      "\nBullet Model    : "..self.fireModel..
                      "\nBullet Weight   : "..pcnRoundValue(self.fireMass)..
                      "\nExplosive Power("..(self.fireExplosives and "On " or "Off")"): "..pcnRoundValue(explosivePower,0.01))
end

function self:GetFireDirection()
  local wdir = Vector(); wdir:Set(self.fireDirection)
        wdir:Rotate(self:GetAngles()); return wdir
end

function ENT:OnTakeDamage(dmginfo)
  self:Print("ENT.OnTakeDamage: TakePhysicsDamage Start")
  self:TakePhysicsDamage(dmginfo)
  self:Print("ENT.OnTakeDamage: TakePhysicsDamage Success")
end

function ENT:FireEnable()
  self.enabled  = true
  self.nextFire = CurTime()
  if (WireLib) then WireLib.TriggerOutput(self, "AutoFiring", 1) end
end

function ENT:FireDisable()
  self.enabled = false
  if (WireLib) then WireLib.TriggerOutput(self, "AutoFiring", 0) end
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
  self.nextFire = (CurTime() + self.fireDelay)
  local pos = self:LocalToWorld(self:OBBCenter())
  local dir = self:GetFireDirection()
  if(self.fireEffect ~= "" and self.fireEffect ~= "none") then
    self:Print("ENT.FireOne: Effect", self.fireEffect)
    local effectData = EffectData()
    self:Print("ENT.FireOne: Alloc data", self.fireEffect)
    effectData:SetOrigin(pos)
    effectData:SetStart(pos)
    effectData:SetScale(1)
    self:Print("ENT.FireOne: Alloc setup", self.fireEffect)
    util.Effect(self.fireEffect, effectData)
    self:Print("ENT.FireOne: Setup effect", self.fireEffect)
  end; self:Print("ENT.FireOne: Setup effects success", self.fireEffect)
  local ent = ents.Create("cannon_prop")
  if(not (ent and ent:IsValid())) then
    self:Print("ENT.FireOne: Cannot create projectile !"); return nil end
  self:Print("ENT.FireOne: Projectile crteated", ent)
  self:DeleteOnRemove(ent)
  ent:SetPos(pos + dir * (self:BoundingRadius() + ent:BoundingRadius()))
  ent:SetModel(self.fireModel)
  ent:SetAngles(self:GetAngles())
  ent:SetOwner(self) -- For collision and such.
  ent.Owner = self:GetPlayer() -- For kill crediting
  if (self.fireExplosives) then
    ent.explosive       = true
    ent.exploded        = false
    ent.explosiveRadius = self.explosiveRadius
    ent.explosivePower  = self.explosivePower
  end; self:Print("ENT.FireOne: Explosive projectile", self.fireExplosives)
  if(self.killDelay > 0) then
    ent.dietime = CurTime() + self.killDelay end
  self:Print("ENT.FireOne: Kill delay", self.killDelay, ent.dietime)
  ent:Spawn(); self:Print("ENT.FireOne: Spawn projectile")
  local iPhys = self:GetPhysicsObject()
  local uPhys =  ent:GetPhysicsObject()
  self:Print("ENT.FireOne: Get settings success")
  if(iPhys and iPhys:IsValid()) then
    reco = dir * -self.fireForce * self.recoilAmount
    self:Print("ENT.FireOne: Recoil", iPhys, reco)
    iPhys:ApplyForceCenter(reco)
  end -- Recoil. The cannon could conceivably work without a valid physics model.
  self:Print("ENT.FireOne: Recoil Success")
  if (not (uPhys and uPhys:IsValid())) then -- The bullets can't though
    self:Print("ENT.FireOne: Invalid physics for projectile", iPhys, ent) return nil end
  self:Print("ENT.FireOne: Setup projectile launch")
  uPhys:SetMass(self.fireMass)
  uPhys:SetVelocityInstantaneous(self:GetVelocity()) -- Start the bullet off going like we be.
  uPhys:ApplyForceCenter(dir * self.fireForce) -- Fire it off infront of us
  self:Print("ENT.FireOne: Launch projectile")
  if (WireLib) then
    WireLib.TriggerOutput(self, "Fired", 1)
    WireLib.TriggerOutput(self, "LastBullet", ent)
    WireLib.TriggerOutput(self, "Fired", 0)
  end; self:Print("ENT.FireOne: Success")
end

function ENT:TriggerInput(key, value)
  if(key == "FireOnce" and value ~= 0) then
    self:Print("ENT.TriggerInput: FireOne Start")
    self:FireOne()
    self:Print("ENT.TriggerInput: FireOne Success")
  elseif (key == "AutoFire") then
    if(value == 0) then
      self:Print("ENT.TriggerInput: FireDisable Start")
      self:FireDisable()
      self:Print("ENT.TriggerInput: FireDisable Success")
    else
      self:Print("ENT.TriggerInput: FireEnable Start")
      self:FireEnable()
      self:Print("ENT.TriggerInput: FireEnable Success")
    end
  end
end

local function On(ply, ent )
  if(not (ent and ent:IsValid())) then return end
  self:Print("ENT.On: Start")
  ent:FireEnable()
  self:Print("ENT.On: Success")
end

local function Off( pl, ent )
  if(not (ent and ent:IsValid())) then return end
  self:Print("ENT.Off: Start")
  ent:FireDisable()
  self:Print("ENT.Off: Success")
end

numpad.Register( "propcannon_On",  On )
numpad.Register( "propcannon_Off", Off )