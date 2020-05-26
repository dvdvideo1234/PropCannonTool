--[[
  ~ Prop Cannon (server) ~
  ~ lexi ~ Ported to Gmod 13 by dvd_video
--]]

AddCSLuaFile("shared.lua")
include("shared.lua")

local gsUnit = "propcannon"
local gsCall = gsUnit.."_numpad_keys"
local varRecAmount = GetConVar(gsUnit.."_maxrecamount")
local varFireDelay = GetConVar(gsUnit.."_maxfiredelay")
local varKillDelay = GetConVar(gsUnit.."_maxkilldelay")
local varExpPower  = GetConVar(gsUnit.."_maxexppower" )
local varExpRadius = GetConVar(gsUnit.."_maxexpradius")
local varFireMass  = GetConVar(gsUnit.."_maxfiremass" )
local varFireForce = GetConVar(gsUnit.."_maxfireforce")

local function numpadRemoveKeys(self, ...)
  local iD, tA = 1, {...}
  for iD = 1, # tA do sK = tostring(tA[iD])
    self:Print("ENT.RemoveKeys("..iD.."): ["..sK.."]")
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
      "AutoFire",
      "FireDelay",
      "FireEffect",
      "FireModel",
      "FireExplosives",
      "ExplosiveRadius",
      "ExplosivePower",
      "KillDelay",
      "FireForce",
      "RecoilAmount",
      "FireMass",
      "FireDirection"
    }, { "NORMAL", "NORMAL", "NORMAL", "STRING",
         "STRING", "NORMAL", "NORMAL", "NORMAL",
         "NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR" }, {
      "Fire a single prop while enabled",
      "Fire repeatedly until off (triggered)",
      "The time to pass before next shot",
      "Effect displayed when fired",
      "Overrides the internal bullet model",
      "Should it have explosive bullets",
      "Explosive bullets blast radius",
      "Explosive bullets blast power",
      "How much time does the bullet lives",
      "The force the bullet is fired with",
      "The amount of the recolil force",
      "The amount of mass applied on the bullet",
      "Direction the bullet follows when shot (local)"
    })
    WireLib.CreateSpecialOutputs(self, {
      "ReadyToFire",
      "Fired",
      "AutoFiring",
      "LastBullet"
    }, { "NORMAL", "NORMAL", "NORMAL", "ENTITY"} , {
      "Is the cannon ready to fire again",
      "Triggered every time the cannon fires",
      "Is the cannon currently autofiring",
      "The last prop that was fired"
    })
  end
end

ENT.wenable         = false
ENT.enabled         = false
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
  if(self.numpadID.AF) then numpad.Remove(self.numpadID.AF) end
  if(self.numpadID.FO) then numpad.Remove(self.numpadID.FO) end
  self.numpadID.AF     = numpad.OnDown(ply, self.numpadKeyAF, gsUnit.."_AF", self)
  self.numpadID.FO     = numpad.OnDown(ply, self.numpadKeyFO, gsUnit.."_FO", self)
  self:Print("ENT.Setup: Keys", self.numpadID.AF, self.numpadID.FO)
  self:RemoveCallOnRemove(gsCall)
  self:CallOnRemove(gsCall, numpadRemoveKeys, self.numpadID.AF, self.numpadID.FO)
  -- Polulate entity data slots wuth the player provided values
  self.fireForce       = math.Clamp(tonumber(fireForce) or 0, 0, varFireForce:GetFloat())
  self.cannonModel     = tostring(cannonModel or ""); self:SetModel(self.cannonModel)
  self.fireModel       = tostring(fireModel or "")
  self.recoilAmount    = math.Clamp(tonumber(recoilAmount) or 0, 0, varRecAmount:GetFloat())
  self.fireDelay       = math.Clamp(tonumber(fireDelay) or 0, 0, varFireDelay:GetFloat())
  self.killDelay       = math.Clamp(tonumber(killDelay) or 0, 0, varKillDelay:GetFloat())
  self.explosivePower  = math.Clamp(tonumber(explosivePower)  or 0, 0, varExpPower:GetFloat())
  self.explosiveRadius = math.Clamp(tonumber(explosiveRadius) or 0, 0, varExpRadius:GetFloat())
  self.fireEffect      = tostring(fireEffect or "")
  self.fireExplosives  = tobool(fireExplosives)
  self.fireMass        = math.Clamp(tonumber(fireMass) or 0, 1, varFireMass:GetFloat())
  self.fireDirection:Set(fireDirection)
  if(self.fireDirection:Length() > 0) then self.fireDirection:Normalize()
  else self.fireDirection.z = 1 end -- Make sure length equal to 1
  self.effectDataClass = EffectData() -- Allocate effect data class
  self:SetOverlayText("- Prop Cannon -"..
                      "\nNumpad Key AutoFire("..(self.enabled and "On" or "Off")..") : "..
                                                 math.Round(self.numpadKeyAF    , 0)..
                      "\nNumpad Key FireOne : "..math.Round(self.numpadKeyFO    , 0)..
                      "\nFiring Delay : "      ..math.Round(self.fireDelay      , 2)..
                      "\nFiring Force : "      ..math.Round(self.fireForce      , 2)..
                      "\nFiring Direction : "  ..math.Round(self.fireDirection.x, 2)..", "..
                                                 math.Round(self.fireDirection.y, 2)..", "..
                                                 math.Round(self.fireDirection.z, 2)..
                      "\nExplosive Radius : "  ..math.Round(self.explosiveRadius, 2)..
                      "\nBullet Weight : "     ..math.Round(self.fireMass       , 2)..
                      "\nFiring Effect : "     ..self.fireEffect..
                      "\nBullet Model : "      ..self.fireModel..
                      "\nExplosive Power("    ..(self.fireExplosives and "On" or "Off").."): "..
                                                 math.Round(self.explosivePower , 2))
  self:Print("ENT.Setup: Success")
end

function ENT:WireRead(name)
  if(not WireLib) then return nil end -- No wiremod
  if(not name) then return nil end; local info = self.Inputs
  if(not istable(info)) then return nil end; info = info[name]
  return (info and (IsValid(info.Src) and info.Value or nil) or nil)
end

function ENT:WireWrite(name, data)
  if(not WireLib) then return self end
  if(not name) then return self end
  if(not data) then return self end
  WireLib.TriggerOutput(self, name, data)
  return self -- Coding effective API
end

function ENT:GetFireDirection()
  local sdir = Vector(); sdir:Set(self.fireDirection)
  local wdir = self:WireRead("FireDirection")
  if(wdir ~= nil) then sdir:Set(wdir) end
  sdir:Rotate(self:GetAngles()); return sdir
end

function ENT:OnTakeDamage(dmginfo)
  self:TakePhysicsDamage(dmginfo)
end

function ENT:FireEnable()
  self.enabled  = true
  self.nextFire = CurTime()
  self:WireWrite("AutoFiring", 1)
end

function ENT:FireDisable()
  self.enabled = false
  self:WireWrite("AutoFiring", 0)
end

function ENT:CanFire()
  return (self.nextFire <= CurTime())
end

function ENT:Think() local wA, wO
  local wA = self:WireRead("AutoFire")
  local wO = self:WireRead("FireOnce")
  if(self:CanFire()) then
    self:WireWrite("ReadyToFire", 1)
    if(wO) then -- Blast only one bullet
      if(wO ~= 0) then self:FireOne() end
    else -- Request autofire state
      if(wA) then -- Override by wire input (trigger toggled)
        if(wA ~= 0) then self.wenable = (not self.wenable) end
        if(self.wenable) then self:FireOne() end
      else -- Wiremod is not installed use numpad events
        if(self.enabled) then self:FireOne() end
      end
    end
  else -- Cannon is not ready to fire yet
    self:WireWrite("ReadyToFire", 0)
  end
end

function ENT:FireOne()
  if(not self:CanFire()) then return end
  self:Print("ENT.FireOne: Start")

  -- Wiremod values used to store overriding values
  local wfireMass        = self:WireRead("FireMass")
  local wfireDelay       = self:WireRead("FireDelay")
  local wfireModel       = self:WireRead("FireModel")
  local wkillDelay       = self:WireRead("KillDelay")
  local wfireForce       = self:WireRead("FireForce")
  local wfireEffect      = self:WireRead("FireEffect")
  local wrecoilAmount    = self:WireRead("RecoilAmount")
  local wfireExplosives  = self:WireRead("FireExplosives")
  local wexplosivePower  = self:WireRead("ExplosivePower")
  local wexplosiveRadius = self:WireRead("ExplosiveRadius")

  -- Genral values used for firing. Overrided by connected wire chips
  local fireMass = ((wfireMass and wfireMass > 0) and wfireMass or self.fireMass)
  local fireDelay = ((wfireDelay and wfireDelay >= 0) and wfireDelay or self.fireDelay)
  local fireModel = ((wfireModel and util.IsValidModel(wfireModel)) and wfireModel or self.fireModel)
  local killDelay = ((wkillDelay and wkillDelay >= 0) and wkillDelay or self.killDelay)
  local fireForce = ((wfireForce and wfireForce >= 0) and wfireForce or self.fireForce)
  local fireEffect = ((wfireEffect and (wfireEffect ~= "")) and wfireEffect or self.fireEffect)
  local recoilAmount = ((wrecoilAmount and wrecoilAmount >= 0) and wrecoilAmount or self.recoilAmount)
  local fireExplosives = self.fireExplosives; if(wfireExplosives) then fireExplosives = tobool(wfireExplosives) end
  local explosivePower = ((wexplosivePower and wexplosivePower >= 0) and wexplosivePower or self.explosivePower)
  local explosiveRadius = ((wexplosiveRadius and wexplosiveRadius >= 0) and wexplosiveRadius or self.explosiveRadius)

  self.nextFire = (CurTime() + fireDelay)
  local pos = self:LocalToWorld(self:OBBCenter())
  local dir = self:GetFireDirection()
  local eff = self.effectDataClass
  if(fireEffect ~= "" and fireEffect ~= "none") then
    eff:SetOrigin(pos)
    eff:SetStart(pos)
    eff:SetScale(1)
    util.Effect(fireEffect, eff)
    self:Print("ENT.FireOne: Effects", "["..fireEffect.."]")
  end
  local ent = ents.Create("cannon_prop")
  if(not (ent and ent:IsValid())) then
    self:Print("ENT.FireOne: Cannot create projectile !"); return nil end
  self:DeleteOnRemove(ent)
  ent:SetCollisionGroup(COLLISION_GROUP_NONE)
  ent:SetSolid(SOLID_VPHYSICS)
  ent:SetMoveType(MOVETYPE_VPHYSICS)
  ent:SetNotSolid(false)
  ent:SetModel(fireModel)
  ent:SetPos(pos + dir * (self:BoundingRadius() + ent:BoundingRadius()))
  ent:SetAngles(self:GetAngles())
  ent:SetOwner(self) -- For collision and such.
  ent.Owner = self:GetPlayer() -- For kill crediting
  ent.exploded        = false            -- Not yet exploded
  ent.explosive       = fireExplosives   -- Explosive props parameter flag
  ent.explosiveRadius = explosiveRadius  -- Explosion radius
  ent.explosivePower  = explosivePower   -- Explosion power
  self:Print("ENT.FireOne: Explosive ["..tostring(fireExplosives).."]")
  if(killDelay > 0) then ent.dietime = CurTime() + killDelay end
  ent:Spawn()
  ent:Activate()
  ent:SetRenderMode(RENDERMODE_TRANSALPHA)
  ent:DrawShadow(true)
  ent:PhysWake()
  local iPhys = self:GetPhysicsObject()
  local uPhys =  ent:GetPhysicsObject()
  if(iPhys and iPhys:IsValid()) then
    reco = dir * -fireForce * recoilAmount
    iPhys:ApplyForceCenter(reco)
    self:Print("ENT.FireOne: Recoil")
  end -- Recoil. The cannon could conceivably work without a valid physics model.
  if(not (uPhys and uPhys:IsValid())) then -- The bullets can't though
    self:Print("ENT.FireOne: Invalid physics for projectile !", iPhys, ent) return nil end
  uPhys:SetMass(fireMass)
  uPhys:SetVelocityInstantaneous(self:GetVelocity()) -- Start the bullet off going like we be.
  uPhys:ApplyForceCenter(dir * fireForce) -- Fire it off in front of us
  self:WireWrite("Fired", 1)
  self:WireWrite("LastBullet", ent)
  self:WireWrite("Fired", 0)
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

numpad.Register(gsUnit.."_AF", fireToggle)
numpad.Register(gsUnit.."_FO", fireOne)
