--[[
  ~ Prop Cannon (server) ~
  ~ lexi ~ Ported to Gmod 13 by dvd_video
--]]

AddCSLuaFile("shared.lua")
include("shared.lua")

local gsBucs = "cannon_prop"
local gsUnit = PCannonLib.GetUnit()
local gsType = PCannonLib.GetUnit("gmod_")
local gsCall = PCannonLib.GetUnit(nil, "_numpad_keys")

local cvFIREMASS  = PCannonLib.FIREMASS
local cvFIREFORCE = PCannonLib.FIREFORCE
local cvFIREDELAY = PCannonLib.FIREDELAY
local cvKILLDELAY = PCannonLib.KILLDELAY
local cvRECAMOUNT = PCannonLib.RECAMOUNT
local cvEXPPOWER  = PCannonLib.EXPPOWER
local cvEXPRADIUS = PCannonLib.EXPRADIUS
local cvEFFECTSCL = PCannonLib.EFFECTSCL
local cvALGNVELCY = PCannonLib.ALGNVELCY

function ENT:RemoveNumpad(...)
  local iD, tA = 1, {...}
  for iD = 1, #tA do
    numpad.Remove(tA[iD])
  end
end

function ENT:PreEntityCopy()
  self:WirePreEntityCopy()
end

function ENT:PostEntityPaste(ply, ent, cre)
  self:WirePostEntityPaste(ply, ent, cre)
end

function ENT:ApplyDupeInfo(ply, ent, info, feid)
  self:WireApplyDupeInfo(ply, ent, info, feid)
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
  self.fireEntity      = nil
  self.cannonModel     = "models/props_trainstation/trashcan_indoor001b.mdl"
  self.fireModel       = "models/props_junk/cinderblock01a.mdl"
  self.recoilAmount    = 0
  self.fireDelay       = 1
  self.killDelay       = 5
  self.fireSpreadX     = 0
  self.fireSpreadY     = 0
  self.explosivePower  = 10
  self.explosiveRadius = 200
  self.fireEffect      = "Explosion"
  self.fireExplosives  = true
  self.fireMass        = 120 -- Mass with optimal distance for projectile
  self.fireDirection   = PCannonLib.GetAimAxis(true) -- Default UP
  self.fireAimAxis     = PCannonLib.GetAimAxis(true) -- Default bullet aim axis

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
    {"AutoFiring" , "NORMAL", "Is the cannon currently auto-firing"  },
    {"LastBullet" , "ENTITY", "The last prop that was fired"         }
  )
end

function ENT:UpdateUCS(cucs, uent)
  if(cucs) then -- Calculate UCS status
    self.fireUpDirAxis = PCannonLib.GetUp(self.fireDirection)
    self.fireRgDirAxis = self.fireDirection:Cross(self.fireUpDirAxis)
  end
  if(uent) then
    self:SetNWVector(gsType.."_firedr", self.fireDirection)
    self:SetNWVector(gsType.."_fireup", self.fireUpDirAxis)
    self:SetNWVector(gsType.."_fireRg", self.fireRgDirAxis)
  end
end

function ENT:Setup(numpadKeyAF    , numpadKeyFO, fireForce     ,
                   cannonModel    , fireModel  , recoilAmount  ,
                   fireDelay      , killDelay  , explosivePower,
                   explosiveRadius, fireEffect , fireExplosives,
                   fireDirection  , fireMass   , fireClass     , fireSpreadX, fireSpreadY)
  local ply            = self:GetPlayer()
  self.fireExplosives  = tobool(fireExplosives)
  self.fireEffect      = tostring(fireEffect or "")
  self.numpadKeyAF     = math.floor(tonumber(numpadKeyAF) or 0)
  self.numpadKeyFO     = math.floor(tonumber(numpadKeyFO) or 0)
  -- Remove the previously used numpad keys and handle numpad crap
  if(self.numpadID.AF) then numpad.Remove(self.numpadID.AF) end
  if(self.numpadID.FO) then numpad.Remove(self.numpadID.FO) end
  self.numpadID.AF     = numpad.OnDown(ply, self.numpadKeyAF, gsUnit.."_AF", self)
  self.numpadID.FO     = numpad.OnDown(ply, self.numpadKeyFO, gsUnit.."_FO", self)
  self:RemoveCallOnRemove(gsCall)
  self:CallOnRemove(gsCall, self.RemoveNumpad, self.numpadID.AF, self.numpadID.FO)
  -- Populate entity data slots with the player provided values
  self.cannonModel     = tostring(cannonModel or self:GetModel())
  self.fireModel       = tostring(fireModel or "")
  self.fireClass       = tostring(fireClass or gsBucs)
  if(self.fireClass == "") then self.fireClass = gsBucs end
  self.fireSpreadX     = math.Clamp(tonumber(fireSpreadX) or 0, 0, 180)
  self.fireSpreadY     = math.Clamp(tonumber(fireSpreadY) or 0, 0, 180)
  self.fireMass        = math.Clamp(tonumber(fireMass) or 0, 0, cvFIREMASS:GetFloat())
  self.fireForce       = math.Clamp(tonumber(fireForce) or 0, 0, cvFIREFORCE:GetFloat())
  self.fireDelay       = math.Clamp(tonumber(fireDelay) or 0, 0, cvFIREDELAY:GetFloat())
  self.killDelay       = math.Clamp(tonumber(killDelay) or 0, 0, cvKILLDELAY:GetFloat())
  self.recoilAmount    = math.Clamp(tonumber(recoilAmount) or 0, 0, cvRECAMOUNT:GetFloat())
  self.explosivePower  = math.Clamp(tonumber(explosivePower)  or 0, 0, cvEXPPOWER:GetFloat())
  self.explosiveRadius = math.Clamp(tonumber(explosiveRadius) or 0, 0, cvEXPRADIUS:GetFloat())
  self.fireDirection:Set(fireDirection)
  if(self.fireDirection:LengthSqr() > 0) then -- The user or constructor can pass any value
    self.fireDirection:Normalize() -- Normalize the vector when there is some length
  else self.fireDirection.z = 1 end; self:UpdateUCS(true, true) -- Direction length must be equal to 1
  self:SetOverlayText("< Prop Cannon >"..
                      "\nNumpad AutoFire : "   ..math.Round(self.numpadKeyAF    , 0)..
                      "\nNumpad FireOnce : "   ..math.Round(self.numpadKeyFO    , 0)..
                      "\nFiring Delay : "      ..math.Round(self.fireDelay      , 2)..
                      "\nFiring Force : "      ..math.Round(self.fireForce      , 2)..
                      "\nFiring Direction : [" ..math.Round(self.fireDirection.x, 2)..","..
                                                 math.Round(self.fireDirection.y, 2)..","..
                                                 math.Round(self.fireDirection.z, 2).."]"..
                      "\nBullet Weight : "     ..math.Round(self.fireMass       , 2)..
                      "\nBullet Spread : ["    ..math.Round(self.fireSpreadX, 2).."|"..
                                                 math.Round(self.fireSpreadY, 2).."]"..
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
  local sdir = Vector(self.fireDirection) -- Read direction
  local wdir = self:WireRead("FireDirection", true)
  if(wdir ~= nil) then sdir:Set(wdir) -- Override using wire
    if(sdir:LengthSqr() > 0) then -- Wire input can pass any value
      sdir:Normalize() -- Normalize the vector when there is some length
    else sdir.z = 1 end -- Make sure the fire direction length is equal to 1
  end -- Assume that the wire user does not need to use HUD update
  local sang = sdir:AngleEx(self.fireUpDirAxis)
        sang = self:LocalToWorldAngles(sang)
  if(self.fireSpreadX > 0 or self.fireSpreadY > 0) then
    local axsX, axsY = sang:Up(), sang:Right()
    sang:RotateAroundAxis(axsX, self.fireSpreadX * (math.random() - 0.5))
    sang:RotateAroundAxis(axsY, self.fireSpreadY * (math.random() - 0.5))
  end; return sang:Forward() -- Forcing sane direction on the prop cannon
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
  return (CurTime() >= self.nextFire)
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

function ENT:BulletArm(ent)
  if(not ent) then return end
  if(not ent:IsValid()) then return end
  local css = ent:GetClass()
  if(gsBucs == css) then return end
  if(ent.CannonNoArm) then return end
  if(not ent.isExplosive) then return end
  local arm, set = ent.Arm, ent.CannonArmArgs
  if(arm) then -- Arm method is available
    if(set ~= nil) then -- Arm method has extern arguments
      if(type(set) == "table") then -- Process table
        local a1, a2, a3 = set[1], set[2], set[3]
        local a4, a5, a6 = set[4], set[5], set[6]
        local a7, a8, a9 = set[7], set[8], set[9]
        local suc, err = pcall(arm, ent, a1, a2, a3,
                                         a4, a5, a6,
                                         a7, a8, a9)
        if(not suc) then return end
      else -- Arm arguments contain single value
        local suc, err = pcall(arm, ent, set)
        if(not suc) then return end
      end -- Process method extern arguments
    else -- Arm method does not have extern arguments
      local suc, err = pcall(arm, ent)
      if(not suc) then return end
    end -- Arm method has been processed
  end -- Arm method does not exist
end

function ENT:BulletTime(ent, delay)
  if(not ent) then return end
  if(not ent:IsValid()) then return end
  self.fireEntity = ent -- Mark the bullet
  if(not delay or delay <= 0) then return end
  local dietime = (CurTime() + delay)
  local timekey = PCannonLib.GetTimerID(ent, "T")
  timer.Create(timekey, 0, 0, function()
    if(CurTime() >= dietime) then
      timer.Remove(timekey)
      if(IsValid(ent)) then
        if(self.fireEntity == ent) then
          self:WireWrite("LastBullet") end
        constraint.RemoveAll(ent) -- Remove constraints
        ent:SetNoDraw(true)       -- Disable drawing
        ent:SetNotSolid(true)     -- Remove solidness
        ent:SetMoveType(MOVETYPE_NONE) -- Ditch physics
        ent:Fire("break"); ent:Remove() -- Remove bullet
      end
    end -- Valid entity references are removed when available
  end) -- Otherwise the entity as exploded and reference is NULL
end

function ENT:BulletAlign(ent)
  if(not ent) then return end
  if(not ent:IsValid()) then return end
  local vfa = ent.CannonEnAlign
  if(vfa == false) then return end
  local vag = cvALGNVELCY:GetFloat()
  if(vag <= 0) then return end -- Owner disabled
  local vmn = cvALGNVELCY:GetMin()
  local vmx = cvALGNVELCY:GetMax()
  local can = tonumber(ent.CannonVeAlign)
  local vam = math.Clamp(can or vag, vmn, vmx)
  if(vam <= 0) then return end -- Override disable
  local aiv, err, ero = Vector(), Vector(), Vector()
  local aim = self:GetBulletAxis(ent)
  local key = PCannonLib.GetTimerID(ent, "A")
  timer.Create(key, 0, 0, function()
    if(ent and ent:IsValid()) then
      local phy = ent:GetPhysicsObject()
      if(phy and phy:IsValid()) then
        local mas, ftm = phy:GetMass(), FrameTime()
        if(ftm > 0) then -- PD controller to flip bullet
          local vec = phy:GetVelocity(); vec:Normalize()
          aiv:Set(aim); aiv:Rotate(ent:GetAngles())
          err:Set(vec:Cross(aiv)) -- Current error
          aiv:Set(err); aiv:Sub(ero); aiv:Mul(1 / ftm)
          aiv:Add(err); aiv:Mul(mas * -vam)
          phy:ApplyTorqueCenter(aiv); ero:Set(err)
        end -- No frame time. No force applied
      else timer.Remove(key) end
    else timer.Remove(key) end
  end)
end

function ENT:FireOne()
  if(not self:CanFire()) then return end
  -- Wiremod values used to store overriding values
  local wfireDelay = self:WireRead("FireDelay", true)
  local wfireClass = self:WireRead("FireClass", true)
  -- General values used for shooting. Overridden by connected wire chips
  local fireDelay = PCannonLib.GetCase(wfireDelay ~= nil and wfireDelay  >  0, wfireDelay , self.fireDelay)
  local fireClass = PCannonLib.GetCase(wfireClass ~= nil and wfireClass ~= "", wfireClass , self.fireClass)
  -- Apply the general shoot trigger logic and bullet configuration
  self.nextFire = (CurTime() + fireDelay)
  local ent = ents.Create(fireClass)
  if(PCannonLib.IsOther(ent, true)) then return end
  -- Wiremod values used to store overriding values
  local wfireMass        = self:WireRead("FireMass", true)
  local wfireModel       = self:WireRead("FireModel", true)
  local wkillDelay       = self:WireRead("KillDelay", true)
  local wfireForce       = self:WireRead("FireForce", true)
  local wfireEffect      = self:WireRead("FireEffect", true)
  local wrecoilAmount    = self:WireRead("RecoilAmount", true)
  local wfireExplosives  = self:WireRead("FireExplosives", true)
  local wexplosivePower  = self:WireRead("ExplosivePower", true)
  local wexplosiveRadius = self:WireRead("ExplosiveRadius", true)
  -- General values used for shooting. Overridden by connected wire chips
  local fireMass        = PCannonLib.GetCase(wfireMass        ~= nil and wfireMass        >  0, wfireMass              , self.fireMass)
  local fireModel       = PCannonLib.GetCase(wfireModel       ~= nil and util.IsValidModel(wfireModel),     wfireModel , self.fireModel)
  local killDelay       = PCannonLib.GetCase(wkillDelay       ~= nil and wkillDelay       >  0, wkillDelay             , self.killDelay)
  local fireForce       = PCannonLib.GetCase(wfireForce       ~= nil and wfireForce       >= 0, wfireForce             , self.fireForce)
  local fireEffect      = PCannonLib.GetCase(wfireEffect      ~= nil                          , wfireEffect            , self.fireEffect)
  local recoilAmount    = PCannonLib.GetCase(wrecoilAmount    ~= nil and wrecoilAmount    >= 0, wrecoilAmount          , self.recoilAmount)
  local fireExplosives  = PCannonLib.GetCase(wfireExplosives  ~= nil                          , tobool(wfireExplosives), self.fireExplosives)
  local explosivePower  = PCannonLib.GetCase(wexplosivePower  ~= nil and wexplosivePower  >= 0, wexplosivePower        , self.explosivePower)
  local explosiveRadius = PCannonLib.GetCase(wexplosiveRadius ~= nil and wexplosiveRadius >= 0, wexplosiveRadius       , self.explosiveRadius)
  -- Apply the general shoot trigger logic and bullet configuration
  local ply = self:GetPlayer() -- For prop protection and ownership addons
  local eff = self.effectDataClass -- Reference to our own explosion
  local dir = self:GetFireDirection() -- Bullet fire diction
  local pos = self:LocalToWorld(self:OBBCenter())
  if(fireEffect ~= "" and fireEffect ~= "none") then
    local mer = (fireForce / cvFIREFORCE:GetFloat())
    eff:SetScale(mer * cvEFFECTSCL:GetFloat())
    eff:SetOrigin(pos); eff:SetStart(pos)
    util.Effect(fireEffect, eff, true, true)
  end -- Finish creating effect. Some effect do not use scaling
  self:WireWrite("Fired", 1) -- Indicate that bullet is fired
  self:WireWrite("LastBullet", ent) -- Write last bullet here
  ent.Owner = ply -- For prop protection and ownership addons
  ent.owner = ply -- For prop protection and ownership addons
  ent.isExploded = false -- Prevents bullet infinite recursion
  ent.isExplosive = fireExplosives -- Explosive props parameter flag
  ent.explosiveRadius = explosiveRadius  -- Explosion blast radius
  ent.explosivePower  = explosivePower   -- Explosion blast power
  ent:SetCollisionGroup(COLLISION_GROUP_NONE) -- Bullet standard collisions
  ent:SetSolid(SOLID_VPHYSICS) -- Bullet acts like a physics object
  ent:SetMoveType(MOVETYPE_VPHYSICS) -- Bullet moves like a physics object
  ent:SetNotSolid(false) -- Make sure bullet is a solid prop with collisions
  ent:SetModel(fireModel) -- This does not work for custom bombs
  self:BulletAng(ent, dir) -- Use custom angle by population axis vector (local)
  self:BulletPos(ent, pos, dir) -- Position the bullet OBB. Requites model setup
  ent:SetOwner(self) -- Used for bullets fired by their owner
  ent:SetCreator(ply) -- Sets the creator of this entity
  ent:Spawn() -- Spawn the bullet in the world and make sure it is not stuck
  ent:Activate() -- Run bullet think hook when available. Some have it
  ent:SetRenderMode(RENDERMODE_TRANSALPHA) -- Alpha support
  ent:DrawShadow(true) -- Drawn bullet shadow duh..
  ent:PhysWake() -- Wake physics up for mass and force
  self:BulletArm(ent) -- Arm the bullet in case of missile or a bomb
  self:BulletAlign(ent) -- Make forward local bullet velocity alignment
  self:BulletTime(ent, killDelay) -- Spawn a timer to deal with kill delay
  self:DeleteOnRemove(ent) -- Remove all bullets when cannon is removed
  local iPhys, uPhys = self:GetPhysicsObject(), ent:GetPhysicsObject()
  if(not (uPhys and uPhys:IsValid())) then ent:Remove(); return end -- Invalid bullet physics
  if(fireMass > 0) then uPhys:SetMass(fireMass) end -- Apply bullet mass. Requires valid bullet
  uPhys:SetVelocityInstantaneous(self:GetVelocity()) -- Apply relative velocity
  uPhys:ApplyForceCenter(dir * fireForce) -- Fire it off in front of us
  if(recoilAmount > 0) then -- Try to apply recoil amount to cannon gun physics
    if(iPhys and iPhys:IsValid()) then -- Valid cannon physics then continue
      iPhys:ApplyForceCenter(dir * (-fireForce * recoilAmount)) -- Recoil amount
    else self:Remove(); return end -- When recoil is enabled remove cannon
  end -- The cannon could work without a valid physics model
  self:WireWrite("Fired", 0)
  ent.Owner:AddCount("props", ent)
  ent.Owner:AddCleanup("props", ent)
end

local function fireToggle(ply, ent)
  if(not (ent and ent:IsValid())) then return end
  if(ent:GetClass() ~= gsType) then return end
  if(ent:WireIsConnected("AutoFire")) then return end
  if(ent.enabled) then ent:FireDisable() else ent:FireEnable() end
end

local function fireOne(pl, ent)
  if(not (ent and ent:IsValid())) then return end
  if(ent:GetClass() ~= gsType) then return end
  if(ent:WireIsConnected("FireOnce")) then return end
  if(ent:CanFire()) then ent:FireOne() end
end

numpad.Register(gsUnit.."_AF", fireToggle)
numpad.Register(gsUnit.."_FO", fireOne)
