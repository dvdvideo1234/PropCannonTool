--[[
  ~ Prop Cannons v2 ~
  ~ lexi ~
--]]

TOOL.Category = "Entities"
TOOL.Name     = "#Prop Cannon"

TOOL.ClientConVar["key"]               = 1
TOOL.ClientConVar["force"]             = 20000
TOOL.ClientConVar["delay"]             = 5
TOOL.ClientConVar["recoil"]            = 1
TOOL.ClientConVar["explosive"]         = 1
TOOL.ClientConVar["kill_delay"]        = 5
TOOL.ClientConVar["ammo_model"]        = "models/props_junk/cinderblock01a.mdl"
TOOL.ClientConVar["fire_effect"]       = "Explosion"
TOOL.ClientConVar["cannon_model"]      = "models/props_trainstation/trashcan_indoor001b.mdl"
TOOL.ClientConVar["explosive_power"]   = 10
TOOL.ClientConVar["explosive_radius"]  = 200

cleanup.Register( "propcannons" )

list.Set("CannonModels","models/dav0r/thruster.mdl",{})
list.Set("CannonModels","models/props_junk/wood_crate001a.mdl",{})
list.Set("CannonModels","models/props_junk/metalbucket01a.mdl",{})
list.Set("CannonModels","models/props_trainstation/trashcan_indoor001b.mdl",{})
list.Set("CannonModels","models/props_junk/trafficcone001a.mdl",{})
list.Set("CannonModels","models/props_c17/oildrum001.mdl",{})
list.Set("CannonModels","models/props_c17/canister01a.mdl",{})
list.Set("CannonModels","models/props_c17/lampshade001a.mdl",{})

list.Set("CannonAmmoModels","models/props_junk/propane_tank001a.mdl",{})
list.Set("CannonAmmoModels","models/props_c17/canister_propane01a.mdl",{})
list.Set("CannonAmmoModels","models/props_junk/watermelon01.mdl",{})
list.Set("CannonAmmoModels","models/props_junk/cinderblock01a.mdl",{})
list.Set("CannonAmmoModels","models/props_debris/concrete_cynderblock001.mdl",{})
list.Set("CannonAmmoModels","models/props_junk/popcan01a.mdl",{})

list.Set("CannonEffects", "Explosion",  {propcannon_fire_effect = "Explosion"})
list.Set("CannonEffects", "Sparks",     {propcannon_fire_effect = "cball_explode"})
list.Set("CannonEffects", "Bomb drop",  {propcannon_fire_effect = "RPGShotDown"})
list.Set("CannonEffects", "Flash",      {propcannon_fire_effect = "HelicopterMegaBomb"})
list.Set("CannonEffects", "Machine Gun",{propcannon_fire_effect = "HelicopterImpact"})
list.Set("CannonEffects", "None",       {propcannon_fire_effect = "none"})

if (SERVER) then
  CreateConVar("sbox_maxpropcannons", 10, "The maximum number of prop cannons you can have out at one time.")
  local function onRemove(self, down, up)
    numpad.Remove(down)
    numpad.Remove(up)
  end
  function MakeCannon(ply, pos, angles, key, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive)
    if (not ply:CheckLimit("propcannons")) then
      return false
    end
    local eCannon = ents.Create( "gmod_propcannon" )
    eCannon:SetPos(pos)
    eCannon:SetAngles(angles)
    eCannon:Setup(force, model, ammo, recoil, delay, kill, power, radius, effect, explosive)
    eCannon:Spawn()
    eCannon:SetPlayer(ply)
    -- Make it shiny and black
    eCannon:SetMaterial("models/shiny")
    eCannon:SetColor(Color(0, 0, 0, 255))
    eCannon.numpadKey = key
    eCannon:CallOnRemove("NumpadCleanup", onRemove,
      numpad.OnDown(ply, key, "propcannon_On", eCannon),
      numpad.OnUp  (ply, key, "propcannon_Off",eCannon)
    )
    eCannon:SetCollisionGroup(COLLISION_GROUP_WORLD)

    ply:AddCount("propcannons", eCannon)
    return eCannon
  end
  duplicator.RegisterEntityClass( "gmod_propcannon", MakeCannon, "Pos", "Ang", "numpadKey", "fireForce", "Model", "fireModel", "recoilAmount", "fireDelay", "killDelay", "explosivePower", "explosiveRadius", "fireEffect", "fireExplosives")
else
  language.Add("Tool.propcannon.name", "Prop Cannon")
  language.Add("Tool.propcannon.desc", "A movable cannon that can fire props")
  language.Add("Tool.propcannon.0",    "Click to spawn a cannon. Click on an existing cannon to change it. Right click on a prop to use the model as ammo.")
  language.Add("SBoxLimit_propcannons", "You've hit the Prop Cannonslimit!")
  language.Add("Undone_propcannon",     "Undone Prop Cannon")
  language.Add("Cleanup_propcannons",   "Prop Cannons")
  language.Add("Cleaned_propcannons",   "Cleaned up all Prop Cannons")
end

function TOOL:LeftClick(tr)
  if (not tr.Hit or tr.Entity:IsPlayer()) then
    return false
  elseif (CLIENT) then
    return true
  elseif (not util.IsValidPhysicsObject(tr.Entity, tr.PhysicsBone)) then
    return false
  end

  local ply = self:GetOwner()
  local key, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive
  key       = self:GetClientNumber("key")
  force     = self:GetClientNumber("force")
  delay     = self:GetClientNumber("delay")
  recoil    = self:GetClientNumber("recoil")
  explosive = self:GetClientNumber("explosive")
  kill      = self:GetClientNumber("kill_delay")
  ammo      = self:GetClientInfo  ("ammo_model")
  effect    = self:GetClientInfo  ("fire_effect")
  model     = self:GetClientInfo  ("cannon_model")
  power     = self:GetClientNumber("explosive_power")
  radius    = self:GetClientNumber("explosive_radius")
  explosive = tobool(explosive)

  if (not (util.IsValidModel(model) and util.IsValidProp(model) and util.IsValidModel(ammo) and util.IsValidProp(ammo))) then
    return false
  end

  local trEnt = tr.Entity
  if (IsValid(trEnt) and
      trEnt:GetClass()  == "gmod_propcannon" and
      trEnt:GetPlayer() == ply
  ) then
    trEnt:Setup(force, model, ammo, recoil, delay, kill, power, radius, effect, explosive)
    return true
  end

  local angles = tr.HitNormal:Angle()
  angles.pitch = angles.pitch + 90

  local eCannon = MakeCannon(ply, tr.HitPos, angles, key, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive)
  if (not eCannon) then return false end
  eCannon:SetPos(tr.HitPos - tr.HitNormal * eCannon:OBBMins().z)

  local cWeld
  if (IsValid(trEnt)) then
    cWeld = constraint.Weld(eCannon, trEnt, 0, tr.PhysicsBone, 0)
    trEnt:DeleteOnRemove(eCannon)
  else
    local phPhys = eCannon:GetPhysicsObject()
    if (IsValid(phPhys)) then
      phPhys:EnableMotion(false)
    end
  end

  undo.Create("propcannon")
  undo.SetPlayer(ply)
  undo.AddEntity(eCannon)
  undo.AddEntity(cWeld)
  undo.Finish()
  ply:AddCleanup("propcannons", eCannon)
  ply:AddCleanup("propcannons", cWeld)
  return true
end

function TOOL:RightClick(tr)
  if (CLIENT) then return true end
  if (not (tr.Hit and
           IsValid(tr.Entity) and
           tr.Entity:GetClass() == "prop_physics")
  ) then
    return false
  end

  local model = tr.Entity:GetModel()
  if (not util.IsValidModel(model)) then -- you never know
    return false
  end
  local ply = self:GetOwner()
  ply:ConCommand("propcannon_ammo_model " .. model .. "\n")
  ply:PrintMessage(HUD_PRINTCENTER, "New ammo model selected!")
end

function TOOL:UpdateGhost(ent, ply) --( ent, player )
  if (not IsValid(ent)) then
    return
  end
  local tr = ply:GetEyeTrace()
  if (not tr.Hit or
      (IsValid(tr.Entity) and
        (tr.Entity:IsPlayer() or
          tr.Entity:GetClass() == "gmod_propcannon"))
    ) then
    ent:SetNoDraw(true)
    return
  end
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
  if (not (IsValid(self.GhostEntity) and self.GhostEntity:GetModel() == model)) then
    self:MakeGhostEntity(model, vector_origin, Angle())
  end
  self:UpdateGhost(self.GhostEntity, self:GetOwner())
end

function TOOL.BuildCPanel(cp)
  cp:AddControl( "Header", { Text         = "#Tool.propcannon.name",
                             Description  = "#Tool.propcannon.desc" } )
  local Combo = {}
  Combo["Label"] = "#Presets"
  Combo["MenuButton"] = "1"
  Combo["Folder"] = "propcannon"
  Combo["Options"] = {}
  Combo["Options"]["Default"] = {}
  Combo["Options"]["Default"]["propcannon_key"]               = "1"
  Combo["Options"]["Default"]["propcannon_force"]             = "20000"
  Combo["Options"]["Default"]["propcannon_delay"]             = "5"
  Combo["Options"]["Default"]["propcannon_recoil"]            = "1"
  Combo["Options"]["Default"]["propcannon_explosive"]         = "1"
  Combo["Options"]["Default"]["propcannon_kill_delay"]        = "5"
  Combo["Options"]["Default"]["propcannon_ammo_model"]        = "models/props_junk/cinderblock01a.mdl"
  Combo["Options"]["Default"]["propcannon_fire_effect"]       = "Explosion"
  Combo["Options"]["Default"]["propcannon_cannon_model"]      = "models/props_trainstation/trashcan_indoor001b.mdl"
  Combo["Options"]["Default"]["propcannon_explosive_power"]   = "10"
  Combo["Options"]["Default"]["propcannon_explosive_radius"]  = "100"
  Combo["CVars"] = {}
  Combo["CVars"]["0"]  = "propcannon_key"
  Combo["CVars"]["1"]  = "propcannon_force"
  Combo["CVars"]["2"]  = "propcannon_delay"
  Combo["CVars"]["3"]  = "propcannon_recoil"
  Combo["CVars"]["4"]  = "propcannon_explosive"
  Combo["CVars"]["5"]  = "propcannon_kill_delay"
  Combo["CVars"]["6"]  = "propcannon_ammo_model"
  Combo["CVars"]["7"]  = "propcannon_fire_effect"
  Combo["CVars"]["8"]  = "propcannon_cannon_model"
  Combo["CVars"]["9"]  = "propcannon_explosive_power"
  Combo["CVars"]["10"] = "propcannon_explosive_radius"
  cp:AddControl("ComboBox", Combo )

  cp:AddControl( "PropSelect", {
    Label = "Cannon Model:",
    ConVar = "propcannon_cannon_model",
    Category = "Cannons",
    Models = list.Get( "CannonModels" )
  })

    cp:AddControl( "Numpad", {
    Label = "Keypad button:",
    Command = "propcannon_key",
    Buttonsize = "22"
  })
    cp:AddControl( "Slider", {
    Label = "Force:",
    Description = "How much force the cannon fires with",
    Type = "float",
    Min = "0",
    Max = "100000",
    Command = "propcannon_force"
  })
    cp:AddControl( "Slider", {
    Label = "Reload Delay:",
    Description = "How many seconds after firing before the cannon can fire again",
    Type = "float",
    Min = "0",
    Max = "50",
    Command = "propcannon_delay"
  })
    cp:AddControl( "Slider", {
    Label = "Recoil:",
    Description = "How much to multiply the cannon's recoil by.",
    Type = "float",
    Min = "0",
    Max = "10",
    Command = "propcannon_recoil"
  })
    cp:AddControl( "Slider", {
    Label = "Prop Lifetime:",
    Description = "How many seconds each fired prop will exist for after being fired (0 to last forever)",
    Type = "float",
    Min = "0",
    Max = "30",
    Command = "propcannon_kill_delay"
  })
    cp:AddControl( "Slider", {
    Label = "Explosive Power:",
    Description = "If the prop is set to explode, how much damage to do.",
    Type = "float",
    Min = "0",
    Max = "200",
    Command = "propcannon_explosive_power"
  })
    cp:AddControl( "Slider", {
    Label = "Explosive Radius:",
    Description = "If the prop is set to explode, how big the explosion should be.",
    Type = "float",
    Min = "0",
    Max = "500",
    Command = "propcannon_explosive_radius"
  })
    cp:AddControl( "Checkbox", {
    Label = "Explode on contact:",
    Description = "Should the fired props explode when they hit something",
    Command = "propcannon_explosive"
  })
  cp:AddControl( "PropSelect", {
    Label = "Cannon Ammo:",
    ConVar = "propcannon_ammo_model",
    Category = "Ammo",
    Models = list.Get( "CannonAmmoModels" )
  })
  cp:AddControl( "ComboBox", {
    Label = "Firing Effect:",
    Description = "The effect to play when the cannon fires",
    MenuButton = "0",
    Options = list.Get( "CannonEffects" )
  })
end