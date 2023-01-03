PCannonLib = PCannonLib or {} -- Initialize the global variable of the library

local gsFormHead     = "[%s] %s > %s: "
local gsFormItem     = " {%s}"
local gsToolItem     = "propcannon"
local gsGmodLimc     = gsToolItem.."s"
local gsFormIcon     = "icon16/%s.png"
local gsGmodType     = "gmod_"..gsToolItem
local gsToolNotA     = "GAMEMODE:AddNotify(\"%s\", NOTIFY_%s, 6)"
local gsToolNotB     = "surface.PlaySound(\"ambient/water/drip%d.wav\")"
local pcnFvars       = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
PCannonLib.LOGFILE   = CreateConVar(gsToolItem.."_logfile", 0, pcnFvars, "Enable logging in a file")
PCannonLib.LOGUSED   = CreateConVar(gsToolItem.."_logused", 0, pcnFvars, "Enable logging on error")
PCannonLib.MENUDIGIT = CreateConVar(gsToolItem.."_maxmenudigit", 5, pcnFvars, "Maximum precision digits for control panel")
PCannonLib.RECAMOUNT = CreateConVar(gsToolItem.."_maxrecamount", 1, pcnFvars, "Maximum cannon fire recoil amount")
PCannonLib.FIREDELAY = CreateConVar(gsToolItem.."_maxfiredelay", 50, pcnFvars, "Maximum cannon firing delay")
PCannonLib.KILLDELAY = CreateConVar(gsToolItem.."_maxkilldelay", 30, pcnFvars, "Maximum cannon bullet kill delay")
PCannonLib.EXPPOWER  = CreateConVar(gsToolItem.."_maxexppower" , 200, pcnFvars, "Maximum cannon bullet explosive power")
PCannonLib.EXPRADIUS = CreateConVar(gsToolItem.."_maxexpradius", 500, pcnFvars, "Maximum cannon bullet explosive radius")
PCannonLib.FIREMASS  = CreateConVar(gsToolItem.."_maxfiremass" , 50000, pcnFvars, "Maximum cannon bullet firing mass")
PCannonLib.FIREFORCE = CreateConVar(gsToolItem.."_maxfireforce", 500000, pcnFvars, "Maximum cannon bullet firing force")
PCannonLib.EFFECTSCL = CreateConVar(gsToolItem.."_maxeffectscl", 10, pcnFvars, "Maximum blast and explosion effect scale")
PCannonLib.MASCANNON = CreateConVar("sbox_max"..gsToolItem.."s", 10, "The maximum number of prop cannon guns you can have out at one time")

local tOther = {
  Data = {}, -- Hash lookup
  "IsPlayer" , "IsVehicle", "IsNPC"   ,
  "IsRagdoll", "IsWeapon" , "IsWidget"
}; tOther.Size = #tOther

local tAngle = {
  Data = Angle(),
  "Forward", "Right", "Up"
}; tAngle.Size = #tAngle

function PCannonLib.GetCase(bC, vT, vF)
  if(bC) then return vT end -- True condition
  return vF -- Return the false condition value
end

function PCannonLib.ToIcon(nam)
  return gsFormIcon:format(nam)
end

function PCannonLib.GetUnit(s, e)
  local s = tostring(s or "")
  local e = tostring(e or "")
  return (s..gsToolItem..e)
end

function PCannonLib.GetRadius(mar)
  return (tonumber(mar) or 0.6)
end

local function Other(ent, rem, reg)
  if(rem) then ent:Remove() end
  return true
end

function PCannonLib.IsOther(ent, rem)
  if(not ent) then return true end
  if(not IsValid(ent)) then return true end
  local css = ent:GetClass() -- Entity class
  local vao = tOther.Data[css] -- Other value
  if(vao ~= nil) then -- Entity class is checked
    if(vao) then return Other(ent, rem) end
    return vao end -- Entity is not other class
  end; vao = false -- Assume the entity is not other
  for idx = 1, tOther.Size do -- Integer for loop
    local nam = tOther[idx] -- Retrieve method name
    local src = ent[nam]    -- Index entity method
    if(src) then local s, v = pcall(src, ent)
      if(not s) then vao = Other(ent, rem) end
      if(v) then vao = Other(ent, rem) end
    else vao = Other(ent, rem) end
  end; tOther.Data[css] = vao; return vao
end

-- Send notification to client that something happened
function PCannonLib.Notify(ply, msg, typ, ...)
  if(CLIENT) then return ... end
  local msg, typ = tostring(msg or ""), tostring(typ or "")
  ply:SendLua(gsToolNotA:format(msg, typ))
  ply:SendLua(gsToolNotB:format(math.random(1, 4)))
  return ...
end

function PCannonLib.Print(ent, ...)
  if(not PCannonLib.LOGUSED:GetBool()) then return end
  local sD = os.date("%y-%m-%d").." "..os.date("%H:%M:%S")
  local sI = (SERVER and "SERVER" or (CLIENT and "CLIENT" or "NOINST"))
  local sL = gsFormHead:format(sD, sI, tostring(ent))
  if(PCannonLib.LOGFILE:GetBool()) then local tD, iD = {...}, 1
    sL = sL..tostring(tD[1]); iD = (iD + 1)
    while(tD[iD]) do local sS = tostring(tD[iD])
      sL, iD = sL..gsFormItem:format(sS), (iD + 1) end
    file.Append(gsToolItem.."/system_log.txt", sL.."\n")
  else print(sL, ...) end
end

function PCannonLib.Cannon(ply   , pos   , ang   , keyaf ,
                           keyfo , force , model , ammo  ,
                           recoil, delay , kill  , power ,
                           radius, effect, doboom, direct,
                           ammoms, ammoty, amsprx, amspry)
  if(CLIENT) then return nil end
  if(not ply:CheckLimit(gsGmodLimc)) then return nil end
  local ent = ents.Create(gsGmodType)
  if(not (ent and ent:IsValid())) then return nil end
  ent:SetPos(pos)
  ent:SetAngles(ang)
  ent:SetModel(model)
  ent:Spawn()
  ent:SetPlayer(ply)
  ent:SetCreator(ply)
  ent:SetMaterial("models/shiny") -- Make it shiny and black
  ent:SetRenderMode(RENDERMODE_TRANSALPHA)
  ent:SetColor(Color(0, 0, 0, 255))
  ent:SetCollisionGroup(COLLISION_GROUP_WORLD)
  ent:Setup(keyaf , keyfo , force , model ,
            ammo  , recoil, delay , kill  ,
            power , radius, effect, doboom,
            direct, ammoms, ammoty, amsprx, amspry)
  ply:AddCount(gsGmodLimc, ent)
  return ent
end

--[[
 * Attempts to find the non-rotated UP direction
 * based on the provided forward direction
]]
function PCannonLib.GetUp(fwd)
  local vup = Vector()
  local ang, dot = tAngle.Data
  for iD = 1, tAngle.Size do
    local dir = ang[tAngle[iD]](ang)
    local mar = math.abs(dir:Dot(fwd))
    if(not dot or mar <= dot) then
      dot = mar; vup:Set(dir)
    end
  end
  local rgh = fwd:Cross(vup)
  vup:Set(rgh:Cross(fwd))
  vup:Normalize()
  return vup
end

function PCannonLib.ConCommand(ply, nam, val)
  if(IsValid(ply)) then
    ply:ConCommand(gsToolItem.."_"..nam.." \""..tostring(val).."\"\n")
  else
    RunConsoleCommand(gsToolItem.."_"..nam, tostring(val))
  end
end

function PCannonLib.NumSlider(panel, name, vmin, vmax, conv, decim)
  local long = gsToolItem.."_"..name
  local item = panel:NumSlider(language.GetPhrase(
    "tool."..gsToolItem.."."..name.."_con"), long, vmin, vmax, decim)
  item:SetTooltip(language.GetPhrase("tool."..gsToolItem.."."..name))
  if(conv) then local def = tonumber(conv[long])
    if(def) then item:SetDefaultValue(def) end
  end
end

function PCannonLib.CheckBox(panel, name)
  local long = gsToolItem.."_"..name
  local item = panel:CheckBox(language.GetPhrase("tool."..gsToolItem.."."..name.."_con"), long)
  item:SetTooltip(language.GetPhrase("tool."..gsToolItem.."."..name))
end
