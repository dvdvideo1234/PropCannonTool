--[[
  ~ Prop Cannons v2 ~
  ~ lexi ~
--]]

cleanup.Register( "propcannons" )

if(SERVER) then
  CreateConVar("sbox_maxpropcannons", 10, "The maximum number of prop cannons you can have out at one time.")

  function getFireDirection(dir)
    local bodir = string.Explode(",",dir)
    local fivec = Vector()
          fivec.x = (tonumber(bodir[1]) or 0)
          fivec.y = (tonumber(bodir[2]) or 0)
          fivec.z = (tonumber(bodir[3]) or 0)
    return fivec
  end

  local function onRemove(self, down, up)
    numpad.Remove(down)
    numpad.Remove(up)
  end

  function MakeCannon(ply, pos, angles, key, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive, direct, ammoms)
    if (not ply:CheckLimit("propcannons")) then return false end
    local eCannon = ents.Create( "gmod_propcannon" )
    eCannon:SetPos(pos)
    eCannon:SetAngles(angles)
    eCannon:Setup(force, model, ammo, recoil, delay, kill, power, radius, effect, explosive, direct, ammoms)
    eCannon:Spawn()
    eCannon:SetPlayer(ply)
    eCannon:SetMaterial("models/shiny") -- Make it shiny and black
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

  duplicator.RegisterEntityClass( "gmod_propcannon", MakeCannon, "Pos", "Ang",
       "numpadKey"      , "fireForce" , "cannonModel"   , "fireModel"     ,
       "recoilAmount"   , "fireDelay" , "killDelay"     , "explosivePower",
       "explosiveRadius", "fireEffect", "fireExplosives", "fireDirection" , "fireMass")
elseif(CLIENT)
  language.Add("Tool.propcannon.name" , "Prop Cannon")
  language.Add("Tool.propcannon.desc" , "A movable cannon that can fire props")
  language.Add("Tool.propcannon.0"    , "Click to spawn a cannon. Click on an existing cannon to change it. Right click on a prop to use the model as ammo.")
  language.Add("Undone_propcannon"    , "Undone Prop Cannon")
  language.Add("Cleanup_propcannons"  , "Prop Cannons")
  language.Add("Cleaned_propcannons"  , "Cleaned up all Prop Cannons")
  language.Add("SBoxLimit_propcannons", "You've hit the Prop Cannons limit!")

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

end

TOOL.Category = "Entities"
TOOL.Name     = languageGetPhrase("Tool."..gsToolNameL..".name")

TOOL.ClientConVar = {
  ["key"]              = 1,
  ["force"]            = 20000,
  ["delay"]            = 5,
  ["recoil"]           = 1,
  ["explosive"]        = 1,
  ["kill_delay"]       = 5,
  ["ammo_model"]       = "models/props_junk/cinderblock01a.mdl",
  ["ammo_mass"]        = 120,
  ["fire_effect"]      = "Explosion",
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
  local key       = self:GetClientNumber("key")
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

  if(trEnt and trEnt:IsValid()) and
      trEnt:GetClass()  == "gmod_propcannon" and
      trEnt:GetPlayer() == ply) then -- Do not update other ppl stuff
    trEnt:Setup(force, model, ammo, recoil, delay, kill, power, radius, effect, explosive, direct, ammoms)
    return true
  end

  local angles = tr.HitNormal:Angle()
  angles.pitch = angles.pitch + 90

  local eCannon = MakeCannon(ply, tr.HitPos, angles, key, force, model, ammo, recoil, delay, kill, power, radius, effect, explosive, direct, ammoms)
  if(not eCannon) then return false end
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
  if(CLIENT) then return true end
  local trEnt, trHit = tr.Entity, tr.Hit
  if(not (trHit and
         (trEnt and trEnt:IsValid()) and
          trEnt:GetClass() == "prop_physics")) then return false end
  local model = trEnt:GetModel()
  if(not util.IsValidModel(model)) then -- you never know
    return false end
  local ply = self:GetOwner()
  ply:ConCommand("propcannon_ammo_model "..model.."\n")
  ply:PrintMessage(HUD_PRINTCENTER, "New ammo model <"..string.GetFileFromFilename(model).."> selected!")
end

function TOOL:UpdateGhost(ent, ply) --( ent, player )
  if(not (ent and ent:IsValid())) then return end
  local tr = ply:GetEyeTrace()
  local trEnt, trHit = tr.Entity, tr.Hit
  if(not trHit or
       ((trEnt and trEnt:IsValid()) and
        (trEnt:IsPlayer() or
         trEnt:GetClass() == "gmod_propcannon"))) then
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

local ConVarList = TOOL:BuildConVarList()
function TOOL.BuildCPanel(cp)
  cp:SetName(language.GetPhrase("Tool.propcannon.name"))
  cp:Help   (language.GetPhrase("Tool.propcannon.desc"))

  cp:AddControl("ComboBox",{
                 Label      = "#Presets"
                 MenuButton = 1,
                 Folder     = "propcannon",
                 Options    = {["Default"] = ConVarList},
                 CVars      = table.GetKeys(ConVarList)})

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
    Label = "Ammo mass:",
    Description = "How much does the bullet weight",
    Type = "float",
    Min = "1",
    Max = "50000",
    Command = "propcannon_ammo_mass"
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