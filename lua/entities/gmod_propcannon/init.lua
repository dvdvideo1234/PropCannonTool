--[[
  ~ Prop Cannon (server) ~
  ~ Lexi ~
--]]

AddCSLuaFile("shared.lua")
include("shared.lua")

local gsUnit = "propcannon"
local gsCall = "remove_numpad_keys"

local function numpadRemoveKeys(self, ...)
  local iD, tA = 1, {...}
  for iD = 1, # tA do sK = tostring(tA[iD])
    self:Print("removeKeys("..iD.."): ["..sK.."]")
    numpad.Remove(tA[iD])
  end
end

function ENT:Initialize()
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid  (SOLID_VPHYSICS)
  self.nextFire = CurTime()
  local phys = self:GetPhysicsObject()
  if(phys and phys:IsValid()) then phys:Wake() end
  if(WireLib) then
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


ENT.numpadID        = {}
ENT.numpadKeyAF     = 42
ENT.numpadKeyFO     = 42
ENT.fireForce       = 40000
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

function ENT:Setup(numpadKeyAF   , numpadKeyFO    , fireForce      , cannonModel,
                   fireModel     , recoilAmount   , fireDelay      ,
                   killDelay     , explosivePower , explosiveRadius,
                   fireEffect    , fireExplosives , fireDirection  , fireMass)
  self:Print("ENT.Setup: Start")
  local ply = self:GetPlayer()
  self.numpadKeyAF     = math.floor(tonumber(numpadKeyAF) or 0)
  self.numpadKeyFO     = math.floor(tonumber(numpadKeyFO) or 0)
  -- Remove the previosky used numpad keys anf handle numpad crap
  if(self.numpadID.Tgg) then numpad.Remove(self.numpadID.Tgg) end
  if(self.numpadID.One) then numpad.Remove(self.numpadID.One) end
  self.numpadID.Tgg    = numpad.OnDown(ply, self.numpadKeyAF, gsUnit.."_TGG", self)
  self.numpadID.One    = numpad.OnDown(ply, self.numpadKeyFO, gsUnit.."_ONE", self)
  self:Print("ENT.Setup: Keys", self.numpadID.Tgg, self.numpadID.One)
  self:RemoveCallOnRemove(gsCall)
  self:CallOnRemove(gsCall, numpadRemoveKeys, self.numpadID.Tgg, self.numpadID.One)
  -- Polulate entity data slots wuth the player provided values
  self.fireForce       = math.Clamp(tonumber(fireForce) or 0, 0, 500000)
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
  self.effectDataClass = EffectData() -- Allocate effect data class
  self:SetOverlayText("- Prop Cannon -"..
                      "\nNumpad Key AutoFire("..(self.enabled and "On" or "Off")..") : "..
                                                 math.Round(self.numpadKeyAF, 0)..
                      "\nNumpad Key FireOne : "..math.Round(self.numpadKeyFO, 0)..
                      "\nFiring Force : "      ..math.Round(self.fireForce      , 2)..
                      "\nFiring Direction : "  ..math.Round(self.fireDirection.x, 2)..", "..
                                                 math.Round(self.fireDirection.y, 2)..", "..
                                                 math.Round(self.fireDirection.z, 2)..
                      "\nFiring Delay : "      ..math.Round(self.fireDelay      , 2)..
                      "\nExplosive Area : "    ..math.Round(self.explosiveRadius, 2)..
                      "\nBullet Weight : "     ..math.Round(self.fireMass       , 2)..
                      "\nFiring Effect : "     ..self.fireEffect..
                      "\nBullet Model : "      ..self.fireModel..
                      "\nExplosive Power("    ..(self.fireExplosives and "On" or "Off").."): "..
                                                 math.Round(self.explosivePower , 2))
  self:Print("ENT.Setup: Success")
end

function ENT:WireRead(name)
  if(not name) then return nil end; local info = self.Inputs
  if(not istable(info)) then return nil end
  if(not next(info)) then return nil end; info = info[name]
  return (IsValid(info.Src) and info.Value or nil)
end

function ENT:WireWrite(name, data)
  if(not name) then return nil end
  if(not data) then return nil end
  if(WireLib) then
    WireLib.TriggerOutput(self, name, data) end
end

function ENT:GetFireDirection()
  local wdir = Vector(); wdir:Set(self.fireDirection)
        wdir:Rotate(self:GetAngles())
  return wdir
end

function ENT:OnTakeDamage(dmginfo)
  self:TakePhysicsDamage(dmginfo)
end

function ENT:FireEnable()
  self.enabled, self.nextFire = true, CurTime()
  if(WireLib) then self:WireWrite("AutoFiring", 1) end
end

function ENT:FireDisable()
  self.enabled = false
  if(WireLib) then self:WireWrite("AutoFiring", 0) end
end

function ENT:CanFire()
  return (self.nextFire <= CurTime())
end

function ENT:Think() local wA, wO
  if(WireLib) then
    wA = self:WireRead("AutoFire")
    wO = self:WireRead("FireOnce")
  end

  if(self:CanFire()) then
    if(wO) then
      if(wO ~= 0) then self:FireOne() end
    else
      if(wA) then
        if(wA ~= 0) then self:FireOne() end
      else
        if(self.enabled) then self:FireOne() end
      end
    end
    if(WireLib) then self:WireWrite("ReadyToFire", 1) end
  else
    if(WireLib) then self:WireWrite("ReadyToFire", 0) end
  end
end

function ENT:FireOne()
  if(not self:CanFire()) then return end
  self:Print("ENT.FireOne: Start")
  self.nextFire = (CurTime() + self.fireDelay)
  local pos = self:LocalToWorld(self:OBBCenter())
  local dir = self:GetFireDirection()
  local eff = self.effectDataClass
  if(self.fireEffect ~= "" and self.fireEffect ~= "none") then
    eff:SetOrigin(pos)
    eff:SetStart(pos)
    eff:SetScale(1)
    util.Effect(self.fireEffect, eff)
    self:Print("ENT.FireOne: Effects", "["..self.fireEffect.."]")
  end
  local ent = ents.Create("cannon_prop")
  if(not (ent and ent:IsValid())) then
    self:Print("ENT.FireOne: Cannot create projectile !"); return nil end
  self:DeleteOnRemove(ent)
  ent:SetCollisionGroup(COLLISION_GROUP_NONE)
  ent:SetSolid(SOLID_VPHYSICS)
  ent:SetMoveType(MOVETYPE_VPHYSICS)
  ent:SetNotSolid(false)
  ent:SetModel(self.fireModel)
  ent:SetPos(pos + dir * (self:BoundingRadius() + ent:BoundingRadius()))
  ent:SetAngles(self:GetAngles())
  ent:SetOwner(self) -- For collision and such.
  ent.Owner = self:GetPlayer() -- For kill crediting
  if(self.fireExplosives) then
    ent.explosive       = true
    ent.exploded        = false
    ent.explosiveRadius = self.explosiveRadius
    ent.explosivePower  = self.explosivePower
    self:Print("ENT.FireOne: Explosive")
  end
  if(self.killDelay > 0) then
    ent.dietime = CurTime() + self.killDelay end
  ent:Spawn()
  ent:Activate()
  ent:SetRenderMode(RENDERMODE_TRANSALPHA)
  ent:DrawShadow(true)
  ent:PhysWake()
  local iPhys = self:GetPhysicsObject()
  local uPhys =  ent:GetPhysicsObject()
  if(iPhys and iPhys:IsValid()) then
    reco = dir * -self.fireForce * self.recoilAmount
    iPhys:ApplyForceCenter(reco)
    self:Print("ENT.FireOne: Recoil")
  end -- Recoil. The cannon could conceivably work without a valid physics model.
  if(not (uPhys and uPhys:IsValid())) then -- The bullets can't though
    self:Print("ENT.FireOne: Invalid physics for projectile !", iPhys, ent) return nil end
  uPhys:SetMass(self.fireMass)
  uPhys:SetVelocityInstantaneous(self:GetVelocity()) -- Start the bullet off going like we be.
  uPhys:ApplyForceCenter(dir * self.fireForce) -- Fire it off in front of us
  if(WireLib) then
    self:WireWrite("Fired", 1)
    self:WireWrite("LastBullet", ent)
    self:WireWrite("Fired", 0)
  end
  ent.Owner:AddCount("props", ent)
  ent.Owner:AddCleanup("props", ent)
  self:Print("ENT.FireOne: Success")
end

local function fireToggle(ply, ent)
  if(not (ent and ent:IsValid())) then return end
  if(ent:GetClass() ~= "gmod_"..gsUnit) then return end
  if(ent.enabled) then
    ent:FireDisable()
  else
    ent:FireEnable()
  end
end

local function fireOne(pl, ent)
  if(not (ent and ent:IsValid())) then return end
  if(ent:GetClass() ~= "gmod_"..gsUnit) then return end
  ent:FireOne()
end

numpad.Register(gsUnit.."_TGG", fireToggle)
numpad.Register(gsUnit.."_ONE", fireOne)
