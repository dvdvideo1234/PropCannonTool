--[[
  ~ Prop Cannons v2 ~
  ~ lexi ~ Ported to Gmod 13 by dvd_video
--]]

local gsUnit       = "propcannon"
local pcnFvars     = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local varLogFile   = CreateConVar(gsUnit.."_logfile", 0, pcnFvars, "Enable logging in a file")
local varLogUsed   = CreateConVar(gsUnit.."_logused", 0, pcnFvars, "Enable logging on error")
local varMenuDigit = CreateConVar(gsUnit.."_maxmenudigit", 5, pcnFvars, "Maximum precision digits for control panel")
local varRecAmount = CreateConVar(gsUnit.."_maxrecamount", 1, pcnFvars, "Maximum cannon fire recoil amount")
local varFireDelay = CreateConVar(gsUnit.."_maxfiredelay", 50, pcnFvars, "Maximum cannon firing delay")
local varKillDelay = CreateConVar(gsUnit.."_maxkilldelay", 30, pcnFvars, "Maximum cannon bullet kill delay")
local varExpPower  = CreateConVar(gsUnit.."_maxexppower" , 200, pcnFvars, "Maximum cannon bullet explosive power")
local varExpRadius = CreateConVar(gsUnit.."_maxexpradius", 500, pcnFvars, "Maximum cannon bullet explosive radius")
local varFireMass  = CreateConVar(gsUnit.."_maxfiremass" , 50000, pcnFvars, "Maximum cannon bullet firing mass")
local varFireForce = CreateConVar(gsUnit.."_maxfireforce", 500000, pcnFvars, "Maximum cannon bullet firing force")

cleanup.Register(gsUnit.."s")

if(SERVER) then

  CreateConVar("sbox_max"..gsUnit.."s", 10, "The maximum number of prop cannon guns you can have out at one time.")

  function notifyUser(ply, msg, type, ...) -- Send notification to client that something happened
    ply:SendLua("GAMEMODE:AddNotify(\""..tostring(msg).."\", NOTIFY_"..tostring(type)..", 6)")
    ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
    return ...
  end

  function MakeCannon(ply   , pos   , ang   , keyaf ,
                      keyfo , force , model , ammo  ,
                      recoil, delay , kill  , power ,
                      radius, effect, doboom, direct, ammoms, ammoty)
    if(not ply:CheckLimit(gsUnit.."s")) then return nil end
    local eCannon = ents.Create("gmod_"..gsUnit)
    if(not (eCannon and eCannon:IsValid())) then return nil end
    eCannon:SetPos(pos)
    eCannon:SetAngles(ang)
    eCannon:SetModel(model)
    eCannon:Spawn()
    eCannon:SetPlayer(ply)
    eCannon:SetMaterial("models/shiny") -- Make it shiny and black
    eCannon:SetRenderMode(RENDERMODE_TRANSALPHA)
    eCannon:SetColor(Color(0, 0, 0, 255))
    eCannon:SetCollisionGroup(COLLISION_GROUP_WORLD)
    eCannon:Setup(keyaf , keyfo , force , model ,
                  ammo  , recoil, delay , kill  ,
                  power , radius, effect, doboom, direct, ammoms, ammoty)
    ply:AddCount(gsUnit.."s", eCannon)
    return eCannon
  end

  duplicator.RegisterEntityClass( "gmod_"..gsUnit, MakeCannon, "Pos", "Ang",
       "numpadKeyAF"   , "numpadKeyFO"    , "fireForce" , "cannonModel"    ,
       "fireModel"     , "recoilAmount"   , "fireDelay" , "killDelay"      ,
       "explosivePower", "explosiveRadius", "fireEffect", "fireExplosives" ,
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
  language.Add("Cleanup_"..gsUnit.."s", "Prop Cannons")
  language.Add("Cleaned_"..gsUnit.."s", "Cleaned up all Prop Cannons")
  language.Add("SBoxLimit_"..gsUnit.."s", "You've hit the Prop Cannons limit!")

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
     trEnt:GetClass()  == "gmod_"..gsUnit and trEnt:GetPlayer() == ply) then -- Do not update other people stuff
     trEnt:Setup(keyaf , keyfo , force , nil ,
                 ammo  , recoil, delay , kill,
                 power , radius, effect, doboom, direct, ammoms, ammoty)
    return true -- Model automatically polulated to avoid difference in visuals and collisions
  end

  local ang = tr.HitNormal:Angle()
        ang.pitch = ang.pitch + 90

  local eCannon = MakeCannon(ply   , tr.HitPos, ang   , keyaf ,
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
  ply:AddCleanup(gsUnit.."s", eCannon)
  ply:AddCleanup(gsUnit.."s", cWeld)
  return true
end

function TOOL:RightClick(tr)
  if(CLIENT) then return true end
  local trEnt = tr.Entity
  local ply = self:GetOwner()
  if(not tr.Hit) then return false end
  if(tr.HitWorld) then
    ply:ConCommand(gsUnit.."_ammo_type \"\"\n")
    notifyUser(ply, "Ammo type clear !",  "UNDO"); return true
  else
    if(not (trEnt and trEnt:IsValid())) then return false end
    if(ply:KeyDown(IN_SPEED)) then
      local amod = trEnt:GetModel()
      if(not util.IsValidModel(amod)) then return false end
      ply:ConCommand(gsUnit.."_cannon_model "..amod.."\n")
      notifyUser(ply, "Cannon: ["..amod.."] !",  "UNDO"); return true
    elseif(ply:KeyDown(IN_USE)) then
      local atyp = trEnt:GetClass()
      ply:ConCommand(gsUnit.."_ammo_type "..atyp.."\n")
      notifyUser(ply, "Ammo type ["..atyp.."] !",  "UNDO"); return true
    else
      local amod = trEnt:GetModel()
      if(not util.IsValidModel(amod)) then return false end
      ply:ConCommand(gsUnit.."_ammo_model "..amod.."\n")
      notifyUser(ply, "Ammo: ["..amod.."] !",  "UNDO"); return true
    end; return false
  end
end

function TOOL:Reload(tr)
  if(CLIENT) then return true end
  if(not tr.Hit) then return false end
  local trEnt = tr.Entity
  if(not (trEnt and trEnt:IsValid())) then return false end
  if(trEnt:GetClass() ~= "gmod_"..gsUnit) then return false end
  trEnt:Remove(); return true
end

function TOOL:UpdateGhost(ent, ply) --( ent, player )
  if(not (ent and ent:IsValid())) then return end
  local tr = ply:GetEyeTrace()
  local trEnt, trHit = tr.Entity, tr.Hit
  if(not trHit or
       ((trEnt and trEnt:IsValid()) and
        (trEnt:IsPlayer() or
         trEnt:GetClass() == "gmod_"..gsUnit))) then
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
  local iDecm = math.Clamp(math.floor(varMenuDigit:GetInt()), 0, 10)
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

  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".force_con"), gsUnit.."_force", 0, varFireForce:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".force"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".ammo_mass_con"), gsUnit.."_ammo_mass", 1, varFireMass:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".ammo_mass"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".delay_con"), gsUnit.."_delay", 0, varFireDelay:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".delay"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".recoil_con"), gsUnit.."_recoil", 0, varRecAmount:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".recoil"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".kill_delay_con"), gsUnit.."_kill_delay", 0, varKillDelay:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".kill_delay"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".explosive_power_con"), gsUnit.."_explosive_power", 0, varExpPower:GetFloat(), iDecm)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".explosive_power"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".explosive_radius_con"), gsUnit.."_explosive_radius", 0, varExpRadius:GetFloat(), iDecm)
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
      ply:ConCommand(gsUnit.."_ammo_type \"\"\n")
      ply:ConCommand(gsUnit.."_ammo_model \""..self.Model.."\"\n")
    end
  end
  cp:AddPanel(pProp)
end
