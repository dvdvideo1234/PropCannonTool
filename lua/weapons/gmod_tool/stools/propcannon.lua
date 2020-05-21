--[[
  ~ Prop Cannons v2 ~
  ~ lexi ~
--]]

local gsUnit       = "propcannon"
local varRecAmount = GetConVar(gsUnit.."_maxrecamount")
local varFireDelay = GetConVar(gsUnit.."_maxfiredelay")
local varKillDelay = GetConVar(gsUnit.."_maxkilldelay")
local varExpPower  = GetConVar(gsUnit.."_maxexppower" )
local varExpRadius = GetConVar(gsUnit.."_maxexpradius")
local varFireMass  = GetConVar(gsUnit.."_maxfiremass" )
local varFireForce = GetConVar(gsUnit.."_maxfireforce")

cleanup.Register(gsUnit.."s")

if(SERVER) then
  CreateConVar("sbox_max"..gsUnit.."s", 10, "The maximum number of prop cannon guns you can have out at one time.")

  function getFireDirection(dir)
    local bodir = string.Explode(",",dir)
    local fivec = Vector()
          fivec.x = (tonumber(bodir[1]) or 0)
          fivec.y = (tonumber(bodir[2]) or 0)
          fivec.z = (tonumber(bodir[3]) or 0)
    return fivec
  end

  function notifyUser(ply, msg, type, ...) -- Send notification to client that something happened
    ply:SendLua("GAMEMODE:AddNotify(\""..tostring(msg).."\", NOTIFY_"..tostring(type)..", 6)")
    ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
    return ...
  end

  function MakeCannon(ply, pos, ang, keyaf, keyfo, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive, direct, ammoms)
    if (not ply:CheckLimit(gsUnit.."s")) then return false end
    local eCannon = ents.Create("gmod_"..gsUnit)
    eCannon:SetPos(pos)
    eCannon:SetAngles(ang)
    eCannon:Setup(keyaf, keyfo, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive, direct, ammoms)
    eCannon:Spawn()
    eCannon:SetPlayer(ply)
    eCannon:SetMaterial("models/shiny") -- Make it shiny and black
    eCannon:SetRenderMode(RENDERMODE_TRANSALPHA)
    eCannon:SetColor(Color(0, 0, 0, 255))
    eCannon:SetCollisionGroup(COLLISION_GROUP_WORLD)
    ply:AddCount(gsUnit.."s", eCannon)
    return eCannon
  end

  duplicator.RegisterEntityClass( "gmod_"..gsUnit, MakeCannon, "Pos", "Ang",
       "numpadKeyAF" , "numpadKeyFO" , "fireForce" , "cannonModel"   , "fireModel"     ,
       "recoilAmount", "fireDelay"   , "killDelay" , "explosivePower",
       "explosiveRadius", "fireEffect", "fireExplosives", "fireDirection" , "fireMass")

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
  language.Add("tool."..gsUnit..".right"               , "Select the trace model to be used as ammo")
  language.Add("tool."..gsUnit..".right_use"           , "Select the trace model to be used as cannon")
  language.Add("tool."..gsUnit..".reload"              , "Removes the prop cannon")
  language.Add("tool."..gsUnit..".name"                , "Prop cannon")
  language.Add("tool."..gsUnit..".desc"                , "A movable cannon that can fire props")
  language.Add("tool."..gsUnit..".0"                   , "Click to spawn a cannon. Click on an existing cannon to change it. Right click on a prop to use the model as ammo.")
  language.Add("tool."..gsUnit..".cannon_model"        , "Cannon model:")
  language.Add("tool."..gsUnit..".force_con"           , "Force:")
  language.Add("tool."..gsUnit..".force"               , "How much force the cannon fires with")
  language.Add("tool."..gsUnit..".ammo_mass_con"       , "Ammo mass:")
  language.Add("tool."..gsUnit..".ammo_mass"           , "How much does the bullet weight")
  language.Add("tool."..gsUnit..".delay_con"           , "Fire delay:")
  language.Add("tool."..gsUnit..".delay"               , "How many seconds after firing before the cannon can fire again")
  language.Add("tool."..gsUnit..".recoil_con"          , "Recoil:")
  language.Add("tool."..gsUnit..".recoil"              , "How much to multiply the cannon's recoil by")
  language.Add("tool."..gsUnit..".kill_delay_con"      , "Prop lifetime:")
  language.Add("tool."..gsUnit..".kill_delay"          , "How many seconds each fired prop will exist for after being fired (0 to last forever)")
  language.Add("tool."..gsUnit..".explosive_power_con" , "Explosive power:")
  language.Add("tool."..gsUnit..".explosive_power"     , "If the prop is set to explode, how much damage to do")
  language.Add("tool."..gsUnit..".explosive_radius_con", "Explosive radius:")
  language.Add("tool."..gsUnit..".explosive_radius"    , "If the prop is set to explode, how big the explosion should be")
  language.Add("tool."..gsUnit..".explosive_con"       , "Explode on contact:")
  language.Add("tool."..gsUnit..".explosive"           , "Should the fired props explode when they hit something")
  language.Add("tool."..gsUnit..".fire_effect_con"     , "Firing effect:")
  language.Add("tool."..gsUnit..".fire_effect"         , "The effect to play when the cannon fires")
  language.Add("tool."..gsUnit..".keyaf_con"           , "Autofire toggle:")
  language.Add("tool."..gsUnit..".keyaf"               , "The dedicated keypad button to activate the cannon autofire")
  language.Add("tool."..gsUnit..".keyfo_con"           , "Single shot:")
  language.Add("tool."..gsUnit..".keyfo"               , "The dedicated keypad button to preform a single shot when pressed")
  language.Add("tool."..gsUnit..".ammo_model_con"      , "Cannon ammo:")
  language.Add("tool."..gsUnit..".ammo_model"          , "This is the prop being selected for cannon ammunition")
  language.Add("Undone_"..gsUnit, "Undone Prop Cannon")
  language.Add("Cleanup_"..gsUnit.."s", "Prop Cannons")
  language.Add("Cleaned_"..gsUnit.."s", "Cleaned up all Prop Cannons")
  language.Add("SBoxLimit_"..gsUnit.."s", "You've hit the Prop Cannons limit!")

  list.Set("CannonModels","models/dav0r/thruster.mdl",{})
  list.Set("CannonModels","models/props_junk/wood_crate001a.mdl",{})
  list.Set("CannonModels","models/props_junk/metalbucket01a.mdl",{})
  list.Set("CannonModels","models/props_trainstation/trashcan_indoor001b.mdl",{})
  list.Set("CannonModels","models/props_junk/trafficcone001a.mdl",{})
  list.Set("CannonModels","models/props_c17/oildrum001.mdl",{})
  list.Set("CannonModels","models/props_c17/canister01a.mdl",{})
  list.Set("CannonModels","models/props_c17/lampshade001a.mdl",{})
  list.Set("CannonModels","models/props_junk/terracotta01.mdl",{})
  list.Set("CannonModels","models/props_c17/pottery_large01a.mdl",{})
  list.Set("CannonModels","models/props_wasteland/laundry_basket001.mdl",{})
  list.Set("CannonModels","models/props_junk/PlasticCrate01a.mdl",{})

  list.Set("CannonAmmoModels","models/props_junk/propane_tank001a.mdl",{})
  list.Set("CannonAmmoModels","models/props_c17/canister_propane01a.mdl",{})
  list.Set("CannonAmmoModels","models/props_junk/watermelon01.mdl",{})
  list.Set("CannonAmmoModels","models/props_junk/cinderblock01a.mdl",{})
  list.Set("CannonAmmoModels","models/props_debris/concrete_cynderblock001.mdl",{})
  list.Set("CannonAmmoModels","models/props_junk/popcan01a.mdl",{})
  list.Set("CannonAmmoModels","models/props_junk/gascan001a.mdl",{})
  list.Set("CannonAmmoModels","models/props_junk/metalgascan.mdl",{})
  list.Set("CannonAmmoModels","models/props_junk/PropaneCanister001a.mdl",{})

  -- https://wiki.facepunch.com/gmod/Effects
  table.Empty(list.GetForEdit("CannonEffects"))
  list.Add("CannonEffects", {name = "Explosion"     , effect = "Explosion"})
  list.Add("CannonEffects", {name = "Impact (RPG)"  , effect = "RPGShotDown"})
  list.Add("CannonEffects", {name = "Sparks"        , effect = "cball_explode"})
  list.Add("CannonEffects", {name = "Baloon PoP"    , effect = "balloon_pop"})
  list.Add("CannonEffects", {name = "Manhack Sparks", effect = "ManhackSparks"})
  list.Add("CannonEffects", {name = "Flash"         , effect = "HelicopterMegaBomb"})
  list.Add("CannonEffects", {name = "Machine Gun"   , effect = "HelicopterImpact"})
  list.Add("CannonEffects", {name = "Antlion Guts"  , effect = "AntlionGib"})
  list.Add("CannonEffects", {name = "None"          , effect = "none"})

  TOOL.Category = "Entities"
  TOOL.Name     = language.GetPhrase("tool."..gsUnit..".name")
end

TOOL.ClientConVar = {
  ["keyaf"]            = 44,
  ["keyfo"]            = 46,
  ["force"]            = 20000,
  ["delay"]            = 5,
  ["recoil"]           = 1,
  ["explosive"]        = 1,
  ["kill_delay"]       = 5,
  ["ammo_model"]       = "models/props_junk/watermelon01.mdl",
  ["ammo_mass"]        = 120,
  ["fire_effect"]      = "RPGShotDown",
  ["fire_direct"]      = "0,0,1",
  ["cannon_model"]     = "models/props_trainstation/trashcan_indoor001b.mdl",
  ["explosive_power"]  = 10,
  ["explosive_radius"] = 200
}

function TOOL:LeftClick(tr)
  if(not tr.Hit) then return false end
  local trEnt = tr.Entity
  if(trEnt and trEnt:IsPlayer()) then return false
  elseif(CLIENT) then return true
  elseif(not util.IsValidPhysicsObject(trEnt, tr.PhysicsBone)) then return false end
  local ply       = self:GetOwner()
  local keyaf     = self:GetClientNumber("keyaf")
  local keyfo     = self:GetClientNumber("keyfo")
  local force     = self:GetClientNumber("force")
  local delay     = self:GetClientNumber("delay")
  local recoil    = self:GetClientNumber("recoil")
  local kill      = self:GetClientNumber("kill_delay")
  local ammo      = self:GetClientInfo  ("ammo_model")
  local ammoms    = self:GetClientNumber("ammo_mass")
  local effect    = self:GetClientInfo  ("fire_effect")
  local model     = self:GetClientInfo  ("cannon_model")
  local power     = self:GetClientNumber("explosive_power")
  local radius    = self:GetClientNumber("explosive_radius")
  local explosive = tobool(self:GetClientNumber("explosive"))
  local direct    = getFireDirection(self:GetClientInfo("fire_direct"))

  if(not (util.IsValidModel(model) and
          util.IsValidProp (model) and
          util.IsValidModel(ammo)  and
          util.IsValidProp (ammo))) then return false end

  if(trEnt and trEnt:IsValid() and
     trEnt:GetClass()  == "gmod_"..gsUnit and
     trEnt:GetPlayer() == ply) then -- Do not update other people stuff
     trEnt:Setup(keyaf, keyfo, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive, direct, ammoms)
    return true
  end

  local ang = tr.HitNormal:Angle()
        ang.pitch = ang.pitch + 90

  local eCannon = MakeCannon(ply, tr.HitPos, ang, keyaf, keyfo, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive, direct, ammoms)
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
  local trEnt = tr.Entity; if(not tr.Hit) then return false end
  if(not (trEnt and trEnt:IsValid())) then return false end
  local model, ply = trEnt:GetModel(), self:GetOwner()
  if(not util.IsValidModel(model)) then return false end
  if(ply:KeyDown(IN_SPEED)) then
    ply:ConCommand(gsUnit.."_cannon_model "..model.."\n")
    notifyUser(ply, "Cannon: "..model.." !",  "UNDO")
  else
    ply:ConCommand(gsUnit.."_ammo_model "..model.."\n")
    notifyUser(ply, "Ammo: "..model.." !",  "UNDO")
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
  if (SERVER and !game.SinglePlayer()) then return end
  if (CLIENT and  game.SinglePlayer()) then return end
  local model = string.lower(self:GetClientInfo("cannon_model"))
  local ghEnt = self.GhostEntity
  if(not (ghEnt and
          ghEnt:IsValid() and
          ghEnt:GetModel() == model)) then
    self:MakeGhostEntity(model, Vector(), Angle())
  end; self:UpdateGhost(ghEnt, self:GetOwner())
end

local gtConvarList = TOOL:BuildConVarList()

function TOOL.BuildCPanel(cp) local pItem
  cp:ClearControls()
  cp:SetName(language.GetPhrase("tool."..gsUnit..".name"))
  cp:Help   (language.GetPhrase("tool."..gsUnit..".desc"))

  local pItem = vgui.Create("ControlPresets", cp)
        pItem:SetPreset(gsUnit)
        pItem:AddOption("default", gtConvarList)
        for key, val in pairs(table.GetKeys(gtConvarList)) do
          pItem:AddConVar(val) end
  cp:AddItem(pItem)

  cp:AddControl( "PropSelect", {
    Label    = language.GetPhrase("tool."..gsUnit..".cannon_model"),
    ConVar   = gsUnit.."_cannon_model",
    Category = "Cannons",
    Models   = list.Get("CannonModels")
  })

  pItem = vgui.Create("CtrlNumPad", cp)
  pItem:SetLabel1(language.GetPhrase("tool."..gsUnit..".keyaf_con"))
  pItem:SetLabel2(language.GetPhrase("tool."..gsUnit..".keyfo_con"))
  pItem:SetConVar1(gsUnit.."_keyaf")
  pItem:SetConVar2(gsUnit.."_keyfo")
  pItem.NumPad1:SetTooltip(language.GetPhrase("tool."..gsUnit..".keyaf"))
  pItem.NumPad2:SetTooltip(language.GetPhrase("tool."..gsUnit..".keyfo"))
  cp:AddPanel(pItem)

  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".force_con"), gsUnit.."_force", 0, varFireForce:GetFloat(), 7)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".force"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".ammo_mass_con"), gsUnit.."_ammo_mass", 1, varFireMass:GetFloat(), 7)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".ammo_mass"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".delay_con"), gsUnit.."_delay", 0, varFireDelay:GetFloat(), 7)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".delay"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".recoil_con"), gsUnit.."_recoil", 0, varRecAmount:GetFloat(), 7)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".recoil"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".kill_delay_con"), gsUnit.."_kill_delay", 0, varKillDelay:GetFloat(), 7)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".kill_delay"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".explosive_power_con"), gsUnit.."_explosive_power", 0, varExpPower:GetFloat(), 7)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".explosive_power"))
  pItem = cp:NumSlider(language.GetPhrase("tool."..gsUnit..".explosive_radius_con"), gsUnit.."_explosive_radius", 0, varExpRadius:GetFloat(), 7)
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".explosive_radius"))
  pItem = cp:CheckBox(language.GetPhrase("tool."..gsUnit..".explosive_con"), gsUnit.."_explosive")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".explosive"))

  cp:AddControl( "PropSelect", {
    Label    = language.GetPhrase("tool."..gsUnit..".ammo_model"),
    ConVar   = "propcannon_ammo_model",
    Category = "Ammo",
    Models   = list.Get("CannonAmmoModels")
  })

  pItem = cp:ComboBox(language.GetPhrase("tool."..gsUnit..".fire_effect_con"), gsUnit.."_fire_effect")
  pItem:SetTooltip(language.GetPhrase("tool."..gsUnit..".fire_effect"))
  local tE = list.GetForEdit("CannonEffects")
  for iE = 1, #tE do pItem:AddChoice(tE[iE].name, tE[iE].effect) end
end
