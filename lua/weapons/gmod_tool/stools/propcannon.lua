--[[
  ~ Prop Cannons v2 ~
  ~ lexi ~ Ported to Gmod 13 by dvd_video
--]]

local gsUnit = PCannonLib.GetUnit()
local gsLimc = PCannonLib.GetUnit(nil, "s")
local gsType = PCannonLib.GetUnit("gmod_")

cleanup.Register(gsLimc)

if(SERVER) then

  duplicator.RegisterEntityClass(gsType, PCannonLib.Cannon, "Pos" ,  "Ang",
       "numpadKeyAF"   , "numpadKeyFO"    , "fireForce" , "cannonModel"   ,
       "fireModel"     , "recoilAmount"   , "fireDelay" , "killDelay"     ,
       "explosivePower", "explosiveRadius", "fireEffect", "fireExplosives",
       "fireDirection" , "fireMass"       , "fireClass" , "fireSpreadX"   , "fireSpreadY")

elseif(CLIENT) then
  TOOL.Information = {
    { name = "info",  stage = 1},
    { name = "left"      },
    { name = "right"     },
    { name = "right_use",icon2 = "gui/e.png"},
    { name = "reload"    }
  }

  table.Empty(list.GetForEdit("CannonModels"))
  list.Add("CannonModels","models/dav0r/thruster.mdl")
  list.Add("CannonModels","models/props_junk/wood_crate001a.mdl")
  list.Add("CannonModels","models/props_junk/metalbucket01a.mdl")
  list.Add("CannonModels","models/props_trainstation/trashcan_indoor001b.mdl")
  list.Add("CannonModels","models/props_junk/trafficcone001a.mdl")
  list.Add("CannonModels","models/props_c17/oildrum001.mdl")
  list.Add("CannonModels","models/props_c17/canister01a.mdl")
  list.Add("CannonModels","models/props_c17/lampshade001a.mdl")
  list.Add("CannonModels","models/props_junk/terracotta01.mdl")
  list.Add("CannonModels","models/props_c17/pottery_large01a.mdl")
  list.Add("CannonModels","models/props_wasteland/laundry_basket001.mdl")
  list.Add("CannonModels","models/props_junk/PlasticCrate01a.mdl")

  table.Empty(list.GetForEdit("CannonAmmoModels"))
  list.Add("CannonAmmoModels","models/props_junk/propane_tank001a.mdl")
  list.Add("CannonAmmoModels","models/props_c17/canister_propane01a.mdl")
  list.Add("CannonAmmoModels","models/props_junk/watermelon01.mdl")
  list.Add("CannonAmmoModels","models/props_junk/cinderblock01a.mdl")
  list.Add("CannonAmmoModels","models/props_debris/concrete_cynderblock001.mdl")
  list.Add("CannonAmmoModels","models/props_junk/popcan01a.mdl")
  list.Add("CannonAmmoModels","models/props_junk/gascan001a.mdl")
  list.Add("CannonAmmoModels","models/props_junk/metalgascan.mdl")
  list.Add("CannonAmmoModels","models/props_junk/PropaneCanister001a.mdl")
  list.Add("CannonAmmoModels","models/props_junk/metal_paintcan001a.mdl")
  list.Add("CannonAmmoModels","models/props_combine/breenglobe.mdl")
  list.Add("CannonAmmoModels","models/props_junk/plasticbucket001a.mdl")
  list.Add("CannonAmmoModels","models/props_interiors/pot01a.mdl")

  -- https://wiki.facepunch.com/gmod/Effects
  table.Empty(list.GetForEdit("CannonEffects"))
  list.Add("CannonEffects", {name = "Explosion"     , effect = "Explosion"})
  list.Add("CannonEffects", {name = "Sparks"        , effect = "cball_explode"})
  list.Add("CannonEffects", {name = "Baloon PoP"    , effect = "balloon_pop"})
  list.Add("CannonEffects", {name = "Manhack Spark" , effect = "ManhackSparks"})
  list.Add("CannonEffects", {name = "Flash"         , effect = "HelicopterMegaBomb"})
  list.Add("CannonEffects", {name = "Machine Gun"   , effect = "HelicopterImpact"})
  list.Add("CannonEffects", {name = "Antlion Guts"  , effect = "AntlionGib"})
  list.Add("CannonEffects", {name = "Airboat Gun"   , effect = "AirboatGunImpact"})
  list.Add("CannonEffects", {name = "Impact RPG"    , effect = "RPGShotDown"})
  list.Add("CannonEffects", {name = "Surface Hit"   , effect = "Impact"})
  list.Add("CannonEffects", {name = "Blood Splat"   , effect = "BloodImpact"})
  list.Add("CannonEffects", {name = "None"          , effect = "none"})

  TOOL.Category = "Construction"
  TOOL.Name     = language.GetPhrase("tool."..gsUnit..".name")
end

TOOL.ClientConVar = {
  ["keyaf"]            = 50,
  ["keyfo"]            = 51,
  ["force"]            = 150000,
  ["delay"]            = 0.5,
  ["recoil"]           = 1,
  ["explosive"]        = 1,
  ["kill_delay"]       = 5,
  ["axis_size"]        = 0,
  ["ammo_model"]       = "models/props_junk/watermelon01.mdl",
  ["ammo_mass"]        = 120,
  ["ammo_type"]        = "cannon_prop",
  ["ammo_sprx"]        = 0,
  ["ammo_spry"]        = 0,
  ["fire_effect"]      = "RPGShotDown",
  ["fire_direct"]      = "0,0,1",
  ["cannon_model"]     = "models/props_trainstation/trashcan_indoor001b.mdl",
  ["explosive_power"]  = 10,
  ["explosive_radius"] = 200
}

function TOOL:GetFireDirection()
  local sDir = self:GetClientInfo("fire_direct")
  local tDir = (","):Explode(sDir)
  local nX = (tonumber(tDir[1]) or 0)
  local nY = (tonumber(tDir[2]) or 0)
  local nZ = (tonumber(tDir[3]) or 0)
  return Vector(nX, nY, nZ)
end

function TOOL:GetFireSpread()
  local sx = self:GetClientNumber("ammo_sprx")
  local sy = self:GetClientNumber("ammo_spry")
  return math.Clamp(sx, 0, 180), math.Clamp(sy, 0, 180)
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return true end
  if(not tr.Hit) then return false end
  local trEnt, trBone = tr.Entity, tr.PhysicsBone
  if(trEnt and trEnt:IsPlayer()) then return false end
  if(not util.IsValidPhysicsObject(trEnt, trBone)) then return false end
  local user   = self:GetOwner()
  local direct = self:GetFireDirection()
  local amsprx, amspry = self:GetFireSpread()
  local keyaf  = self:GetClientNumber("keyaf")
  local keyfo  = self:GetClientNumber("keyfo")
  local force  = self:GetClientNumber("force")
  local delay  = self:GetClientNumber("delay")
  local recoil = self:GetClientNumber("recoil")
  local kill   = self:GetClientNumber("kill_delay")
  local ammo   = self:GetClientInfo  ("ammo_model")
  local ammoms = self:GetClientNumber("ammo_mass")
  local ammoty = self:GetClientInfo  ("ammo_type")
  local effect = self:GetClientInfo  ("fire_effect")
  local model  = self:GetClientInfo  ("cannon_model")
  local power  = self:GetClientNumber("explosive_power")
  local radius = self:GetClientNumber("explosive_radius")
  local doboom = tobool(self:GetClientNumber("explosive"))

  if(not (util.IsValidModel(model) and
          util.IsValidProp (model) and
          util.IsValidModel(ammo)  and
          util.IsValidProp (ammo))) then return false end

  if(trEnt and trEnt:IsValid() and
     trEnt:GetClass() == gsType and
     trEnt:GetPlayer() == user and
     trEnt:GetCreator() == user
  ) then -- Do not update other people stuff
     trEnt:Setup(keyaf , keyfo , force , nil ,
                 ammo  , recoil, delay , kill,
                 power , radius, effect, doboom,
                 direct, ammoms, ammoty, amsprx, amspry)
    return true -- Model automatically polulated to avoid difference in visuals and collisions
  end

  local ang = tr.HitNormal:Angle()
        ang.pitch = ang.pitch + 90

  local eCannon = PCannonLib.Cannon(user  , tr.HitPos, ang   , keyaf ,
                                    keyfo , force    , model , ammo  ,
                                    recoil, delay    , kill  , power ,
                                    radius, effect   , doboom, direct,
                                    ammoms, ammoty   , amsprx, amspry)
  if(not (eCannon and eCannon:IsValid())) then return false end
  eCannon:SetPos(tr.HitPos - tr.HitNormal * eCannon:OBBMins().z)

  local cWeld
  if(trEnt and trEnt:IsValid()) then
    cWeld = constraint.Weld(eCannon, trEnt, 0, tr.PhysicsBone, 0)
    trEnt:DeleteOnRemove(eCannon)
  else
    local phPhys = eCannon:GetPhysicsObject()
    if(phPhys and phPhys:IsValid()) then
      phPhys:EnableMotion(false) end
  end
  undo.Create(gsUnit)
    undo.SetPlayer(user)
    undo.AddEntity(eCannon)
    undo.AddEntity(cWeld)
  undo.Finish()
  user:AddCleanup(gsLimc, eCannon)
  user:AddCleanup(gsLimc, cWeld)
  return true
end

function TOOL:RightClick(tr)
  if(CLIENT) then return true end
  local trEnt = tr.Entity
  local user = self:GetOwner()
  if(not tr.Hit) then return false end
  if(tr.HitWorld) then
    PCannonLib.ConCommand(user, "ammo_type", "")
    PCannonLib.Notify(user, "Ammo type clear !",  "UNDO"); return true
  else
    if(not IsValid(trEnt)) then return false end
    local escs = trEnt:GetClass()
    local emou = trEnt:GetModel()
    local vmou = util.IsValidModel(emou)
    if(gsType == escs) then
      if(user:KeyDown(IN_SPEED)) then
        if(not vmou) then return false end
        PCannonLib.ConCommand(user, "cannon_model", emou)
        PCannonLib.Notify(user, "Cannon model: ["..emou.."] !",  "UNDO"); return true
      else
        PCannonLib.ConCommand(user, "force", trEnt.fireForce)
        PCannonLib.ConCommand(user, "delay", trEnt.fireDelay)
        PCannonLib.ConCommand(user, "recoil", trEnt.recoilAmount)
        PCannonLib.ConCommand(user, "ammo_mass", trEnt.fireMass)
        PCannonLib.ConCommand(user, "ammo_type", trEnt.fireClass)
        PCannonLib.ConCommand(user, "kill_delay", trEnt.killDelay)
        PCannonLib.ConCommand(user, "ammo_model", trEnt.fireModel)
        PCannonLib.ConCommand(user, "fire_effect" , trEnt.fireEffect)
        PCannonLib.ConCommand(user, "cannon_model" , trEnt.cannonModel)
        PCannonLib.ConCommand(user, "explosive_power" , trEnt.explosivePower)
        PCannonLib.ConCommand(user, "explosive_radius" , trEnt.explosiveRadius)
        PCannonLib.ConCommand(user, "explosive" , (trEnt.fireExplosives and 1 or 0))
        PCannonLib.Notify(user, "Cannon copy !",  "UNDO"); return true
      end
    else
      if(user:KeyDown(IN_SPEED)) then
        if(not vmou) then return false end
        PCannonLib.ConCommand(user, "cannon_model", emou)
        PCannonLib.Notify(user, "Cannon model: ["..emou.."] !",  "UNDO"); return true
      elseif(user:KeyDown(IN_USE)) then
        if(PCannonLib.IsOther(trEnt)) then return false else
          PCannonLib.ConCommand(user, "ammo_type", escs)
          PCannonLib.ConCommand(user, "ammo_model", emou)
          PCannonLib.Notify(user, "Ammo type ["..escs.."] !",  "UNDO"); return true
        end
      else
        if(not vmou) then return false end
        PCannonLib.ConCommand(user, "ammo_model", emou)
        PCannonLib.Notify(user, "Ammo model: ["..emou.."] !",  "UNDO"); return true
      end
    end; return false
  end
end

function TOOL:Reload(tr)
  if(CLIENT) then return true end
  if(not tr.Hit) then return false end
  local user, trEnt = self:GetOwner(), tr.Entity
  if(not IsValid(trEnt)) then return false end
  local ownr = PCannonLib.GetOwner(trEnt)
  if(trEnt:GetClass() == gsType) then
    if(ownr == user or user:IsAdmin()) then
      trEnt:Remove(); return true end; return false
  else -- Try to remove the cannon bullets
    local cann = trEnt:GetOwner()
    if(not IsValid(cann)) then return false end
    if(cann:GetClass() ~= gsType) then return false end
    local ownr = PCannonLib.GetOwner(cann)
    if(ownr == user or user:IsAdmin()) then
      trEnt:Remove(); return true end; return false
  end
end

function TOOL:UpdateGhost(ent, ply)
  if(not (ent and ent:IsValid())) then return end
  local tr = ply:GetEyeTrace()
  local trEnt, trHit = tr.Entity, tr.Hit
  if(not trHit or
       ((trEnt and trEnt:IsValid()) and
        (trEnt:IsPlayer() or
         trEnt:GetClass() == gsType))) then
    ent:SetNoDraw(true); return end
  local angles = tr.HitNormal:Angle()
  angles.pitch = angles.pitch + 90
  ent:SetAngles(angles)
  ent:SetPos(tr.HitPos - tr.HitNormal * ent:OBBMins().z)
  ent:SetNoDraw(false)
end

function TOOL:Think()
  if(CLIENT and game.SinglePlayer()) then return end
  if(SERVER and not game.SinglePlayer()) then return end
  local model = string.lower(self:GetClientInfo("cannon_model"))
  local ghEnt = self.GhostEntity
  if(not (ghEnt and ghEnt:IsValid() and
          ghEnt:GetModel() == model)) then
    self:MakeGhostEntity(model, Vector(), Angle())
  end; self:UpdateGhost(ghEnt, self:GetOwner())
end

function TOOL:GetPosRadius(oPly, vHit, nAxs)
  local nRad = (vHit - oPly:GetPos()):Length()
  return math.Clamp(20 * nAxs / nRad, 1, 100)
end

function TOOL:DrawHUD()
  if(SERVER) then return end
  local oPly = self:GetOwner()
  local stTr = oPly:GetEyeTrace()
  if(stTr and oPly) then
    local axislen = self:GetClientNumber("axis_size")
    if(axislen > 0) then local oEnt = stTr.Entity
      if(oEnt and oEnt:IsValid() and oEnt:GetClass() == gsType) then
        local eAng = oEnt:GetAngles()
        local nRad = self:GetPosRadius(oPly, stTr.HitPos, axislen)
        local vDir = Vector(oEnt:GetNWVector(gsType.."_firedr"))
        local vUpa = Vector(oEnt:GetNWVector(gsType.."_fireup"))
        local bPos = oEnt:GetBulletBase(vDir)
        vUpa:Rotate(eAng); vDir:Rotate(eAng)
        local P = bPos:ToScreen();
        local D = (bPos + axislen * vDir):ToScreen()
        local U = (bPos + axislen * vUpa):ToScreen()
        -- Bullet direction and spawn
        surface.SetDrawColor(255,0,0,255)
        surface.DrawLine(P.x, P.y, D.x, D.y)
        surface.SetDrawColor(0,0,255,255)
        surface.DrawLine(P.x, P.y, U.x, U.y)
        surface.DrawCircle(P.x, P.y, nRad * 2, Color(255,255,0,255))
      end
    end
  end
end

local gtConvarList = TOOL:BuildConVarList()

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(cp)
  cp:ClearControls()
  cp:SetName(language.GetPhrase("tool."..gsUnit..".name"))
  cp:Help   (language.GetPhrase("tool."..gsUnit..".desc"))
  local iDecm = math.Clamp(math.floor(PCannonLib.MENUDIGIT:GetInt()), 0, 10)
  -- Control panel presets
  local pItem, pProp, vItem = vgui.Create("ControlPresets", cp)
        pItem:SetPreset(gsUnit)
        pItem:AddOption("Default", gtConvarList)
        for key, val in pairs(table.GetKeys(gtConvarList)) do pItem:AddConVar(val) end
  cp:AddItem(pItem)
  -- Cannon model
  pItem = vgui.Create("PropSelect", cp)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".cannon_model"))
  pItem:ControlValues({convar = gsUnit.."_cannon_model", label = language.GetPhrase("tool."..gsUnit..".cannon_model_con")})
  local tC = list.GetForEdit("CannonModels")
  for iC = 1, #tC do pItem:AddModel(tC[iC]) end
  cp:AddPanel(pItem)
  -- Cannon numad control
  pItem = vgui.Create("CtrlNumPad", cp)
  pItem:SetLabel1(language.GetPhrase("tool."..gsUnit..".keyaf_con"))
  pItem:SetLabel2(language.GetPhrase("tool."..gsUnit..".keyfo_con"))
  pItem:SetConVar1(gsUnit.."_keyaf")
  pItem:SetConVar2(gsUnit.."_keyfo")
  pItem.NumPad1:SetTooltip(language.GetPhrase("tool."..gsUnit..".keyaf"))
  pItem.NumPad2:SetTooltip(language.GetPhrase("tool."..gsUnit..".keyfo"))
  cp:AddPanel(pItem)
  -- Cannon setup values
  PCannonLib.NumSlider(cp, "force"           , 0, PCannonLib.FIREFORCE:GetFloat(), gtConvarList, iDecm)
  PCannonLib.NumSlider(cp, "ammo_mass"       , 0, PCannonLib.FIREMASS:GetFloat() , gtConvarList, iDecm)
  PCannonLib.NumSlider(cp, "delay"           , 0, PCannonLib.FIREDELAY:GetFloat(), gtConvarList, iDecm)
  PCannonLib.NumSlider(cp, "recoil"          , 0, PCannonLib.RECAMOUNT:GetFloat(), gtConvarList, iDecm)
  PCannonLib.NumSlider(cp, "kill_delay"      , 0, PCannonLib.KILLDELAY:GetFloat(), gtConvarList, iDecm)
  PCannonLib.NumSlider(cp, "explosive_power" , 0, PCannonLib.EXPPOWER:GetFloat() , gtConvarList, iDecm)
  PCannonLib.NumSlider(cp, "explosive_radius", 0, PCannonLib.EXPRADIUS:GetFloat(), gtConvarList, iDecm)
  PCannonLib.NumSlider(cp, "ammo_sprx"       , 0, 180, gtConvarList, iDecm)
  PCannonLib.NumSlider(cp, "ammo_spry"       , 0, 180, gtConvarList, iDecm)
  -- Effects
  vItem = GetConVar(gsUnit.."_fire_effect"):GetString()
  pItem = cp:ComboBox(language.GetPhrase("tool."..gsUnit..".fire_effect_con"), gsUnit.."_fire_effect")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".fire_effect"))
  local tE = list.GetForEdit("CannonEffects") -- http://www.famfamfam.com/lab/icons/silk/preview.php
  for iE = 1, #tE do local vE = tE[iE]
    local nam, eff, use, ico = vE.name, vE.effect, (vItem == eff), vE.icon
    pItem:AddChoice(nam, eff, use, PCannonLib.ToIcon(ico or "wand"))
  end; cp:AddPanel(pItem)
  -- Explosive ammunition flag
  PCannonLib.CheckBox(cp, "explosive")
  -- Ammo model
  pProp = vgui.Create("PropSelect", cp)
  pProp:SetTooltip(language.GetPhrase("tool."..gsUnit..".ammo_model"))
  pProp:ControlValues({label = language.GetPhrase("tool."..gsUnit..".ammo_model_con")})
  local tA = list.GetForEdit("CannonAmmoModels")
  for iA = 1, #tA do
    local pIcon = pProp:AddModel(tA[iA])
    function pIcon:DoClick() local user = LocalPlayer()
      PCannonLib.ConCommand(user, "ammo_type", "")
      PCannonLib.ConCommand(user, "ammo_model", self.Model)
    end
  end; cp:AddPanel(pProp)
  -- Coordinate system
  PCannonLib.NumSlider(cp, "axis_size", 0, 25, gtConvarList, iDecm)
end
