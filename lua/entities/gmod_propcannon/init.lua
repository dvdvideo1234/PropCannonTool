--[[
  ~ Prop Cannon (server) ~
  ~ lexi ~ Ported to Gmod 13 by dvd_video
--]]

AddCSLuaFile("shared.lua")
include("shared.lua")

local gsBull = "cannon_prop"
local gsUnit = PCannonLib.GetUnit()
local gsCall = PCannonLib.GetUnit(nil, "_numpad_keys")

function ENT:RemoveNumpad(...)
  local iD, tA = 1, {...}
  for iD = 1, #tA do
    numpad.Remove(tA[iD])
  end
end

function ENT:PreEntityCopy()
  self:WirePreEntityCopy()
end

function ENT:PostEntityPaste(ply, ent, created)
  self:WirePostEntityPaste(ply, ent, created)
end

function ENT:ApplyDupeInfo(ply, ent, info, fentid)
  self:WireApplyDupeInfo(ply, ent, info, fentid)
end

function ENT:Initialize()
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)

  -- Initialize internals
  self.nextFire        = CurTime()
  self.effectDataClass = EffectData() -- Allocate effect data class
  self.wenable         = false
  self.enabled         = false
  self.numpadID        = {}
  self.numpadKeyAF     = 44
  self.numpadKeyFO     = 46
  self.fireForce       = 40000
  self.cannonModel     = "models/props_trainstation/trashcan_indoor001b.mdl"
  self.fireModel       = "models/props_junk/cinderblock01a.mdl"
  self.recoilAmount    = 0
  self.fireDelay       = 1
  self.killDelay       = 5
  self.explosivePower  = 10
  self.explosiveRadius = 200
  self.fireEffect      = "Explosion"
  self.fireExplosives  = true
  self.fireMass        = 120 -- Mass with optimal distance for projectile
  self.fireDirection   = Vector(0,0,1) -- Default UP

  local phys = self:GetPhysicsObject()
  if(phys and phys:IsValid()) then phys:Wake() end

  self:WireCreateInputs(
    {"FireOnce"       , "NORMAL", "Fire a single prop while enabled"           },
    {"AutoFire"       , "NORMAL", "Trigger fire repeatedly until off"          },
    {"FireDelay"      , "NORMAL", "The time to pass before next shot"          },
    {"FireEffect"     , "STRING", "Effect displayed when fired"                },
    {"FireModel"      , "STRING", "Overrides the internal bullet model"        },
    {"FireClass"      , "STRING", "Overrides the internal bullet class"        },
    {"FireExplosives" , "NORMAL", "Should it have explosive bullets"           },
    {"ExplosiveRadius", "NORMAL", "Explosive bullets blast radius"             },
    {"ExplosivePower" , "NORMAL", "Explosive bullets blast power"              },
    {"KillDelay"      , "NORMAL", "How much time does the bullet lives"        },
    {"FireForce"      , "NORMAL", "The force the bullet is fired with"         },
    {"RecoilAmount"   , "NORMAL", "The amount of the recoil force"             },
    {"FireMass"       , "NORMAL", "The amount of mass applied on the bullet"   },
    {"FireDirection"  , "VECTOR", "The local direction that the bullet follows"}
  ):WireCreateOutputs(
    {"ReadyToFire", "NORMAL", "Is the cannon ready to fire again"    },
    {"Fired"      , "NORMAL", "Triggered every time the cannon fires"},
    {"AutoFiring" , "NORMAL", "Is the cannon currently autofiring"   },
    {"LastBullet" , "ENTITY", "The last prop that was fired"         }
  )
end

function ENT:Setup(numpadKeyAF, numpadKeyFO   , fireForce     ,
                   cannonModel, fireModel     , recoilAmount  ,
                   fireDelay  , killDelay     , explosivePower, explosiveRadius,
                   fireEffect , fireExplosives, fireDirection , fireMass, fireClass)
  local ply = self:GetPlayer()
  self.fireExplosives  = tobool(fireExplosives)
  self.fireEffect      = tostring(fireEffect or "")
  self.numpadKeyAF     = math.floor(tonumber(numpadKeyAF) or 0)
  self.numpadKeyFO     = math.floor(tonumber(numpadKeyFO) or 0)
  -- Remove the previosky used numpad keys anf handle numpad crap
  if(self.numpadID.AF) then numpad.Remove(self.numpadID.AF) end
  if(self.numpadID.FO) then numpad.Remove(self.numpadID.FO) end
  self.numpadID.AF     = numpad.OnDown(ply, self.numpadKeyAF, gsUnit.."_AF", self)
  self.numpadID.FO     = numpad.OnDown(ply, self.numpadKeyFO, gsUnit.."_FO", self)
  self:RemoveCallOnRemove(gsCall)
  self:CallOnRemove(gsCall, self.RemoveNumpad, self.numpadID.AF, self.numpadID.FO)
  -- Polulate entity data slots wuth the player provided values
  self.cannonModel     = tostring(cannonModel or self:GetModel())
  self.fireModel       = tostring(fireModel or "")
  self.fireClass       = tostring(fireClass or gsBull)
  if(self.fireClass == "") then self.fireClass = gsBull end
  self.fireMass        = math.Clamp(tonumber(fireMass) or 0, 1, PCannonLib.FIREMASS:GetFloat())
  self.fireForce       = math.Clamp(tonumber(fireForce) or 0, 0, PCannonLib.FIREFORCE:GetFloat())
  self.fireDelay       = math.Clamp(tonumber(fireDelay) or 0, 0, PCannonLib.FIREDELAY:GetFloat())
  self.killDelay       = math.Clamp(tonumber(killDelay) or 0, 0, PCannonLib.KILLDELAY:GetFloat())
  self.recoilAmount    = math.Clamp(tonumber(recoilAmount) or 0, 0, PCannonLib.RECAMOUNT:GetFloat())
  self.explosivePower  = math.Clamp(tonumber(explosivePower)  or 0, 0, PCannonLib.EXPPOWER:GetFloat())
  self.explosiveRadius = math.Clamp(tonumber(explosiveRadius) or 0, 0, PCannonLib.EXPRADIUS:GetFloat())
  self.fireDirection:Set(fireDirection)
  if(self.fireDirection:LengthSqr() > 0) then -- The user or constructor can pass any value
    self.fireDirection:Normalize() -- Normalize the vector when there is some length
  else self.fireDirection.z = 1 end -- Make sure the fire direction length is equal to 1
  self:SetOverlayText("< Prop Cannon >"..
                      "\nNumpad Key AutoFire("..(self.enabled and "On" or "Off")..") : "..
                                                 math.Round(self.numpadKeyAF    , 0)..
                      "\nNumpad Key FireOne : "..math.Round(self.numpadKeyFO    , 0)..
                      "\nFiring Delay : "      ..math.Round(self.fireDelay      , 2)..
                      "\nFiring Force : "      ..math.Round(self.fireForce      , 2)..
                      "\nFiring Direction : "  ..math.Round(self.fireDirection.x, 2)..", "..
                                                 math.Round(self.fireDirection.y, 2)..", "..
                                                 math.Round(self.fireDirection.z, 2)..
                      "\nBullet Weight : "     ..math.Round(self.fireMass       , 2)..
                      "\nFiring Effect : "     ..self.fireEffect..
                      "\nBullet Model : "      ..self.fireModel..
                      "\nBullet Class : "      ..self.fireClass..
                      "\nBullet Lifetime : "   ..math.Round(self.killDelay      , 2)..
                      "\nBullet Recoil : "     ..math.Round(self.recoilAmount   , 2)..
                      "\nExplosive Radius : "  ..math.Round(self.explosiveRadius, 2)..
                      "\nExplosive Power ("     ..(self.fireExplosives and "On" or "Off").."): "..
                                                  math.Round(self.explosivePower , 2))
end

function ENT:GetFireDirection()
  local sang, sdir = self:GetAngles(), Vector()
  local wdir = self:WireRead("FireDirection", true)
  sdir:Set(self.fireDirection) -- Read the internal direction
  if(wdir ~= nil) then sdir:Set(wdir) -- Override using wire
    if(sdir:LengthSqr() > 0) then -- Wire input can pass any value
      sdir:Normalize() -- Normalize the vector when there is some length
    else sdir.z = 1 end -- Make sure the fire direction length is equal to 1
  end; sdir:Rotate(sang); return sdir -- Forcing sane direction on the prop cannon
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

function ENT:Think()
  local wA = self:WireRead("AutoFire", true)
  local wO = self:WireRead("FireOnce", true)
  if(self:CanFire()) then
    self:WireWrite("ReadyToFire", 1)
    if(wO and wO ~= 0) then self:FireOne() end
    if(wA) then -- Override by wire input (trigger toggled)
      if(wA ~= 0) then self.wenable = (not self.wenable) end
      if(self.wenable) then self:FireOne() end
    else -- Wiremod is not installed use numpad events
      if(self.enabled) then self:FireOne() end
    end
  else -- Cannon is not ready to fire yet
    self:WireWrite("ReadyToFire", 0)
  end
end

function ENT:GetCase(bC, vT, vF)
  if(bC) then return vT end -- True condition
  return vF -- Return the false condition value
end

function ENT:BulletArm(ent)
  if(ent and ent:IsValid()) then
    local css = ent:GetClass()
    if(gsBull == css) then return end
    local ply = self:GetPlayer()
    local exp = ent.explosive
    if(not exp) then return end
    if(ent.Arm) then
      local suc, err = pcall(ent.Arm, ent)
      if(not suc) then return end
    else
      ent:Use(ply, self, USE_ON, 1)
    end
  end
end

function ENT:BulletTime(ent, num)
  if(not ent) then return end
  if(not ent:IsValid()) then return end
  if(not num or num <= 0) then return end
  local dietime = CurTime() + num
  local timekey = gsUnit.."_"..ent:EntIndex()
  timer.Create(timekey, 0, 0, function()
    if(CurTime() >= dietime) then
      timer.Remove(timekey)
      if(IsValid(ent)) then
        constraint.RemoveAll(ent) -- Remove contraints
        ent:SetNoDraw(true)       -- Disable drawing
        ent:SetNotSolid(true)     -- Remove solidness
        ent:SetMoveType(MOVETYPE_NONE) -- Ditch physics
        ent:Fire("break"); ent:Remove() -- Remove bullet
        self:WireWrite("LastBullet")
      end
    end -- Valid entity references are removed when available
  end) -- Otherwise the entity as exploded and reference is NULL
end

function ENT:FireOne()
  if(not self:CanFire()) then return end
  -- Wiremod values used to store overriding values
  local wfireMass        = self:WireRead("FireMass", true)
  local wfireClass       = self:WireRead("FireClass", true)
  local wfireDelay       = self:WireRead("FireDelay", true)
  local wfireModel       = self:WireRead("FireModel", true)
  local wkillDelay       = self:WireRead("KillDelay", true)
  local wfireForce       = self:WireRead("FireForce", true)
  local wfireEffect      = self:WireRead("FireEffect", true)
  local wrecoilAmount    = self:WireRead("RecoilAmount", true)
  local wfireExplosives  = self:WireRead("FireExplosives", true)
  local wexplosivePower  = self:WireRead("ExplosivePower", true)
  local wexplosiveRadius = self:WireRead("ExplosiveRadius", true)
  -- Genral values used for shooting. Overrided by connected wire chips
  local fireMass        = self:GetCase(wfireMass        ~= nil and wfireMass        >  0, wfireMass              , self.fireMass)
  local fireClass       = self:GetCase(wfireClass       ~= nil and wfireClass      ~= "", wfireClass             , self.fireClass)
  local fireDelay       = self:GetCase(wfireDelay       ~= nil and wfireDelay       >  0, wfireDelay             , self.fireDelay)
  local fireModel       = self:GetCase(wfireModel       ~= nil and util.IsValidModel(wfireModel),     wfireModel , self.fireModel)
  local killDelay       = self:GetCase(wkillDelay       ~= nil and wkillDelay       >  0, wkillDelay             , self.killDelay)
  local fireForce       = self:GetCase(wfireForce       ~= nil and wfireForce       >= 0, wfireForce             , self.fireForce)
  local fireEffect      = self:GetCase(wfireEffect      ~= nil                          , wfireEffect            , self.fireEffect)
  local recoilAmount    = self:GetCase(wrecoilAmount    ~= nil and wrecoilAmount    >= 0, wrecoilAmount          , self.recoilAmount)
  local fireExplosives  = self:GetCase(wfireExplosives  ~= nil                          , tobool(wfireExplosives), self.fireExplosives)
  local explosivePower  = self:GetCase(wexplosivePower  ~= nil and wexplosivePower  >= 0, wexplosivePower        , self.explosivePower)
  local explosiveRadius = self:GetCase(wexplosiveRadius ~= nil and wexplosiveRadius >= 0, wexplosiveRadius       , self.explosiveRadius)
  -- Apply the general shoot trigger logic and bullet configuration
  self.nextFire = (CurTime() + fireDelay)
  local pos = self:LocalToWorld(self:OBBCenter())
  local dir = self:GetFireDirection()
  local eff = self.effectDataClass
  if(fireEffect ~= "" and fireEffect ~= "none") then
    eff:SetOrigin(pos); eff:SetStart(pos); eff:SetScale(1)
    util.Effect(fireEffect, eff, true, true)
  end
  local ply = self:GetPlayer() -- For prop protection and ownership addons
  local ent = ents.Create(fireClass)
  if(PCannonLib.IsOther(ent, true)) then return end
  self:WireWrite("Fired", 1) -- Indicate that bullet is fired
  self:WireWrite("LastBullet", ent) -- Write last bullet here
  ent.Owner = ply -- For prop protection and ownership addons
  ent.owner = ply -- For prop protection and ownership addons
  ent.exploded        = false            -- Prevents bullet infinite recursion
  ent.explosive       = fireExplosives   -- Explosive props parameter flag
  ent.explosiveRadius = explosiveRadius  -- Explosion blast radius
  ent.explosivePower  = explosivePower   -- Explosion blast power
  ent:SetCollisionGroup(COLLISION_GROUP_NONE)
  ent:SetSolid(SOLID_VPHYSICS)
  ent:SetMoveType(MOVETYPE_VPHYSICS)
  ent:SetNotSolid(false)
  ent:SetModel(fireModel) -- This does not work for custom bomps
  ent:SetPos(pos + dir * (self:BoundingRadius() + ent:BoundingRadius()))
  ent:SetAngles(dir:Angle())
  ent:SetOwner(self) -- Used for bullets fired by their owner
  ent:Spawn()
  ent:Activate()
  ent:SetRenderMode(RENDERMODE_TRANSALPHA)
  ent:DrawShadow(true)
  ent:PhysWake()
  self:BulletArm(ent)
  self:BulletTime(ent, killDelay)
  self:DeleteOnRemove(ent)
  local iPhys, uPhys = self:GetPhysicsObject(), ent:GetPhysicsObject()
  if(not (uPhys and uPhys:IsValid())) then return end -- Invalid bullet physics
  uPhys:SetMass(fireMass) -- Apply bullet mass. Requires valid bullet
  uPhys:SetVelocityInstantaneous(self:GetVelocity()) -- Apply relative velocity
  uPhys:ApplyForceCenter(dir * fireForce) -- Fire it off in front of us
  if(iPhys and iPhys:IsValid() and recoilAmount > 0) then -- Valid cannon  physics
    iPhys:ApplyForceCenter(dir * (-fireForce * recoilAmount)) -- Recoil amount
  end -- Recoil. The cannon could work without a valid physics model.
  self:WireWrite("Fired", 0)
  ent.Owner:AddCount("props", ent)
  ent.Owner:AddCleanup("props", ent)
end

local function fireToggle(ply, ent)
  if(not (ent and ent:IsValid())) then return end
  if(ent:GetClass() ~= "gmod_"..gsUnit) then return end
  if(ent:WireIsConnected("AutoFire")) then return end
  if(ent.enabled) then ent:FireDisable() else ent:FireEnable() end
end

local function fireOne(pl, ent)
  if(not (ent and ent:IsValid())) then return end
  if(ent:GetClass() ~= "gmod_"..gsUnit) then return end
  if(ent:WireIsConnected("FireOnce")) then return end
  if(ent:CanFire()) then ent:FireOne() end
end

numpad.Register(gsUnit.."_AF", fireToggle)
numpad.Register(gsUnit.."_FO", fireOne)
