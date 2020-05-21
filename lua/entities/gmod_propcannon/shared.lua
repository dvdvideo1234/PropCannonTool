--[[
  ~ Prop Cannon (shar'd) ~
  ~ Lexi ~
--]]
ENT.Type            = "anim"
ENT.PrintName       = "Prop Cannon Gun"
if (WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = ENT.PrintName
else
  ENT.Base          = "base_gmodentity"
end
ENT.Author          = "Lexi"              -- Fixed for gmod13 dvd_video
ENT.Contact         = "lexi@lexi.org.uk"  -- dvd_video@abv.bg
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

local gsUnit       = "propcannon"
local pcnFvars     = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local varLogFile   = CreateConVar(gsUnit.."_logfile", 0, pcnFvars, "Enable logging in a file")
local varLogUsed   = CreateConVar(gsUnit.."_logused", 0, pcnFvars, "Enable logging on error")
local varRecAmount = CreateConVar(gsUnit.."_maxrecamount", 10, pcnFvars, "Maximum cannon fire recoil amount")
local varFireDelay = CreateConVar(gsUnit.."_maxfiredelay", 50, pcnFvars, "Maximum cannon firing delay")
local varKillDelay = CreateConVar(gsUnit.."_maxkilldelay", 30, pcnFvars, "Maximum cannon bullet kill delay")
local varExpPower  = CreateConVar(gsUnit.."_maxexppower" , 200, pcnFvars, "Maximum cannon bullet explosive power")
local varExpRadius = CreateConVar(gsUnit.."_maxexpradius", 500, pcnFvars, "Maximum cannon bullet explosive radius")
local varFireMass  = CreateConVar(gsUnit.."_maxfiremass" , 50000, pcnFvars, "Maximum cannon bullet firing mass")
local varFireForce = CreateConVar(gsUnit.."_maxfireforce", 500000, pcnFvars, "Maximum cannon bullet firing force")

if(not file.Exists(gsUnit.."_tool","DATA")) then
  file.CreateDir(gsUnit.."_tool")
end

function ENT:Print(...)
  if(not varLogUsed:GetBool()) then return end;
  local sD = os.date("%y-%m-%d").." "..os.date("%H:%M:%S")
  local sI = (SERVER and "SERVER" or (CLIENT and "CLIENT" or "NOINST"))
  local sLin = "["..sD.."] "..sI.." > "..tostring(self)..":"
  if(varLogFile:GetBool()) then
    local sDel = "\t"
    local tData, nID = {...}, 1
    while(tData[nID]) do
      sLin, nID = sLin..sDel..tostring(tData[nID]), (nID + 1)
    end; file.Append(gsUnit.."_tool/system_log.txt", sLin.."\n")
  else print(sLin,...) end
end
