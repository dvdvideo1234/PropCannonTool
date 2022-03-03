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
       "fireDirection" , "fireMass"       , "fireClass")

elseif(CLIENT) then
  TOOL.Information = {
    { name = "info",  stage = 1},
    { name = "left"      },
    { name = "right"     },
    { name = "right_use",icon2 = "gui/e.png"},
    { name = "reload"    }
  }
  language.Add("tool."..gsUnit..".1"                   , "Manipulates a movable cannon that can fire props")
  language.Add("tool."..gsUnit..".left"                , "Creates a cannon. Weld to the trace when prop is hit")
  language.Add("tool."..gsUnit..".right"               , "Use trace model as ammo. Hold SHIFT to use as cannon model")
  language.Add("tool."..gsUnit..".right_use"           , "Use trace class as ammo type. Hit world to reset default")
  language.Add("tool."..gsUnit..".reload"              , "Removes the prop cannon")
  language.Add("tool."..gsUnit..".name"                , "Prop Cannon")
  language.Add("tool."..gsUnit..".desc"                , "A movable cannon that can fire props")
  language.Add("tool."..gsUnit..".0"                   , "Click to spawn a cannon. Click on an existing cannon to change it. Right click on a prop to use the model as ammo.")
  language.Add("tool."..gsUnit..".cannon_model_con"    , "Cannon model:")
  language.Add("tool."..gsUnit..".cannon_model"        , "The prop being used for the canon itself")
  language.Add("tool."..gsUnit..".force_con"           , "Force:")
  language.Add("tool."..gsUnit..".force"               , "How much force the cannon fires with")
  language.Add("tool."..gsUnit..".ammo_mass_con"       , "Ammo mass:")
  language.Add("tool."..gsUnit..".ammo_mass"           , "How much does the bullet weight")
  language.Add("tool."..gsUnit..".delay_con"           , "Fire delay:")
  language.Add("tool."..gsUnit..".delay"               , "How many seconds after firing before the cannon can fire again")
  language.Add("tool."..gsUnit..".recoil_con"          , "Recoil:")
  language.Add("tool."..gsUnit..".recoil"              , "How much larger the recoil force is compared to the fire force")
  language.Add("tool."..gsUnit..".kill_delay_con"      , "Prop lifetime:")
  language.Add("tool."..gsUnit..".kill_delay"          , "How many seconds each prop will exist for after being fired (0 to last forever)")
  language.Add("tool."..gsUnit..".explosive_power_con" , "Explosive power:")
  language.Add("tool."..gsUnit..".explosive_power"     , "If the prop is set to explode how much damage does it do")
  language.Add("tool."..gsUnit..".explosive_radius_con", "Explosive radius:")
  language.Add("tool."..gsUnit..".explosive_radius"    , "If the prop is set to explode, how big the explosion should be")
  language.Add("tool."..gsUnit..".explosive_con"       , "Explode ammunition on contact")
  language.Add("tool."..gsUnit..".explosive"           , "Should the fired props explode when they hit something")
  language.Add("tool."..gsUnit..".fire_effect_con"     , "Firing effect:")
  language.Add("tool."..gsUnit..".fire_effect"         , "The effect to play when the cannon fires")
  language.Add("tool."..gsUnit..".keyaf_con"           , "Autofire toggle:")
  language.Add("tool."..gsUnit..".keyaf"               , "The dedicated keypad button to activate the cannon autofire")
  language.Add("tool."..gsUnit..".keyfo_con"           , "Single shot:")
  language.Add("tool."..gsUnit..".keyfo"               , "The dedicated keypad button to preform a single shot when pressed")
  language.Add("tool."..gsUnit..".ammo_model_con"      , "Ammunition model:")
  language.Add("tool."..gsUnit..".ammo_model"          , "The prop being selected for cannon ammunition")
  language.Add("Undone_"..gsUnit, "Undone Prop Cannon")
  language.Add("Cleanup_"..gsLimc, "Prop Cannons")
  language.Add("Cleaned_"..gsLimc, "Cleaned up all Prop Cannons")
  language.Add("SBoxLimit_"..gsLimc, "You've hit the Prop Cannons limit!")

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
  ["keyaf"]            = 44,
  ["keyfo"]            = 46,
  ["force"]            = 70000,
  ["delay"]            = 1,
  ["recoil"]           = 1,
  ["explosive"]        = 1,
  ["kill_delay"]       = 5,
  ["ammo_model"]       = "models/props_junk/watermelon01.mdl",
  ["ammo_mass"]        = 120,
  ["ammo_type"]        = "cannon_prop",
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

function TOOL:LeftClick(tr)
  if(CLIENT) then return true end
  if(not tr.Hit) then return false end
  local trEnt, trBone = tr.Entity, tr.PhysicsBone
  if(trEnt and trEnt:IsPlayer()) then return false end
  if(not util.IsValidPhysicsObject(trEnt, trBone)) then return false end
  local ply    = self:GetOwner()
  local direct = self:GetFireDirection()
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
     trEnt:GetPlayer() == ply and
     trEnt:GetCreator() == ply
  ) then -- Do not update other people stuff
     trEnt:Setup(keyaf , keyfo , force , nil ,
                 ammo  , recoil, delay , kill,
                 power , radius, effect, doboom, direct, ammoms, ammoty)
    return true -- Model automatically polulated to avoid difference in visuals and collisions
  end

  local ang = tr.HitNormal:Angle()
        ang.pitch = ang.pitch + 90

  local eCannon = PCannonLib.Cannon(ply   , tr.HitPos, ang   , keyaf ,
                                    keyfo , force    , model , ammo  ,
                                    recoil, delay    , kill  , power ,
                                    radius, effect   , doboom, direct, ammoms, ammoty)
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
    undo.SetPlayer(ply)
    undo.AddEntity(eCannon)
    undo.AddEntity(cWeld)
  undo.Finish()
  ply:AddCleanup(gsLimc, eCannon)
  ply:AddCleanup(gsLimc, cWeld)
  return true
end

function TOOL:RightClick(tr)
  if(CLIENT) then return true end
  local trEnt = tr.Entity
  local ply = self:GetOwner()
  if(not tr.Hit) then return false end
  if(tr.HitWorld) then
    PCannonLib.ConCommand(ply, "ammo_type", "")
    PCannonLib.Notify(ply, "Ammo type clear !",  "UNDO"); return true
  else
    if(not (trEnt and trEnt:IsValid())) then return false end
    local escs = trEnt:GetClass()
    local emou = trEnt:GetModel()
    if(ply:KeyDown(IN_SPEED)) then
      if(not util.IsValidModel(emou)) then return false end
      PCannonLib.ConCommand(ply, "cannon_model", emou)
      PCannonLib.Notify(ply, "Cannon model: ["..emou.."] !",  "UNDO"); return true
    elseif(ply:KeyDown(IN_USE)) then
      if(PCannonLib.IsOther(trEnt)) then return false else
        PCannonLib.ConCommand(ply, "ammo_type", escs)
        PCannonLib.Notify(ply, "Ammo type ["..escs.."] !",  "UNDO"); return true
      end
    else
      if(gsType == escs) then
        PCannonLib.ConCommand(ply, "force", trEnt.fireForce)
        PCannonLib.ConCommand(ply, "delay", trEnt.fireDelay)
        PCannonLib.ConCommand(ply, "recoil", trEnt.recoilAmount)
        PCannonLib.ConCommand(ply, "ammo_mass", trEnt.fireMass)
        PCannonLib.ConCommand(ply, "ammo_type", trEnt.fireClass)
        PCannonLib.ConCommand(ply, "kill_delay", trEnt.killDelay)
        PCannonLib.ConCommand(ply, "ammo_model", trEnt.fireModel)
        PCannonLib.ConCommand(ply, "fire_effect" , trEnt.fireEffect)
        PCannonLib.ConCommand(ply, "cannon_model" , trEnt.cannonModel)
        PCannonLib.ConCommand(ply, "explosive_power" , trEnt.explosivePower)
        PCannonLib.ConCommand(ply, "explosive_radius" , trEnt.explosiveRadius)
        PCannonLib.ConCommand(ply, "explosive" , (trEnt.fireExplosives and 1 or 0))
        PCannonLib.Notify(ply, "Cannon copy !",  "UNDO"); return true
      else
        if(not util.IsValidModel(emou)) then return false end
        PCannonLib.ConCommand(ply, "ammo_model", emou)
        PCannonLib.Notify(ply, "Ammo model: ["..emou.."] !",  "UNDO"); return true
      end
    end; return false
  end
end

function TOOL:Reload(tr)
  if(CLIENT) then return true end
  if(not tr.Hit) then return false end
  local ply, trEnt = self:GetOwner(), tr.Entity
  if(not (trEnt and trEnt:IsValid())) then return false end
  if(trEnt:GetClass() ~= gsType) then return false end
  if(trEnt:GetPlayer() ~= ply) then return false end
  if(trEnt:GetCreator() ~= ply) then return false end
  trEnt:Remove(); return true
end

function TOOL:UpdateGhost(ent, ply) --( ent, player )
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

local gtConvarList = TOOL:BuildConVarList()

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(cp)
  cp:ClearControls()
  cp:SetName(language.GetPhrase("tool."..gsUnit..".name"))
  cp:Help   (language.GetPhrase("tool."..gsUnit..".desc"))
  local iDecm = math.Clamp(math.floor(PCannonLib.MENUDIGIT:GetInt()), 0, 10)
  local pItem, pProp = vgui.Create("ControlPresets", cp)
        pItem:SetPreset(gsUnit)
        pItem:AddOption("Default", gtConvarList)
        for key, val in pairs(table.GetKeys(gtConvarList)) do pItem:AddConVar(val) end
  cp:AddItem(pItem)

  pItem = vgui.Create("PropSelect", cp)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".cannon_model"))
  pItem:ControlValues({convar = gsUnit.."_cannon_model", label = language.GetPhrase("tool."..gsUnit..".cannon_model_con")})
  local tC = list.GetForEdit("CannonModels")
  for iC = 1, #tC do pItem:AddModel(tC[iC]) end
  cp:AddPanel(pItem)

  pItem = vgui.Create("CtrlNumPad", cp)
  pItem:SetLabel1(language.GetPhrase("tool."..gsUnit..".keyaf_con"))
  pItem:SetLabel2(language.GetPhrase("tool."..gsUnit..".keyfo_con"))
  pItem:SetConVar1(gsUnit.."_keyaf")
  pItem:SetConVar2(gsUnit.."_keyfo")
  pItem.NumPad1:SetTooltip(language.GetPhrase("tool."..gsUnit..".keyaf"))
  pItem.NumPad2:SetTooltip(language.GetPhrase("tool."..gsUnit..".keyfo"))
  cp:AddPanel(pItem)

  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".force_con"), gsUnit.."_force", 0, PCannonLib.FIREFORCE:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".force"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".ammo_mass_con"), gsUnit.."_ammo_mass", 1, PCannonLib.FIREMASS:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".ammo_mass"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".delay_con"), gsUnit.."_delay", 0, PCannonLib.FIREDELAY:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".delay"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".recoil_con"), gsUnit.."_recoil", 0, PCannonLib.RECAMOUNT:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".recoil"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".kill_delay_con"), gsUnit.."_kill_delay", 0, PCannonLib.KILLDELAY:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".kill_delay"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".explosive_power_con"), gsUnit.."_explosive_power", 0, PCannonLib.EXPPOWER:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".explosive_power"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".explosive_radius_con"), gsUnit.."_explosive_radius", 0, PCannonLib.EXPRADIUS:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".explosive_radius"))

  pItem = cp:ComboBox(language.GetPhrase("tool."..gsUnit..".fire_effect_con"), gsUnit.."_fire_effect")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".fire_effect"))
  local tE = list.GetForEdit("CannonEffects")
  for iE = 1, #tE do pItem:AddChoice(tE[iE].name, tE[iE].effect) end
  cp:AddPanel(pItem)

  pItem = cp:CheckBox(language.GetPhrase("tool."..gsUnit..".explosive_con"), gsUnit.."_explosive")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".explosive"))

  pProp = vgui.Create("PropSelect", cp)
  pProp:SetTooltip(language.GetPhrase("tool."..gsUnit..".ammo_model"))
  pProp:ControlValues({label = language.GetPhrase("tool."..gsUnit..".ammo_model_con")})
  local tA = list.GetForEdit("CannonAmmoModels")
  for iA = 1, #tA do
    local pIcon = pProp:AddModel(tA[iA])
    function pIcon:DoClick() local ply = LocalPlayer()
      PCannonLib.ConCommand(ply, "ammo_type", "")
      PCannonLib.ConCommand(ply, "ammo_model", self.Model)
    end
  end
  cp:AddPanel(pProp)
end
