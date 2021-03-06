--[[
  ~ Prop Cannon (shar'd) ~
  ~ lexi ~ Ported to Gmod 13 by dvd_video
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
local gsFormHead   = "[%s] %s > %s: "
local gsFormItem   = " {%s}"
local varLogFile   = GetConVar(gsUnit.."_logfile")
local varLogUsed   = GetConVar(gsUnit.."_logused")
local varRecAmount = GetConVar(gsUnit.."_maxrecamount")
local varFireDelay = GetConVar(gsUnit.."_maxfiredelay")
local varKillDelay = GetConVar(gsUnit.."_maxkilldelay")
local varExpPower  = GetConVar(gsUnit.."_maxexppower" )
local varExpRadius = GetConVar(gsUnit.."_maxexpradius")
local varFireMass  = GetConVar(gsUnit.."_maxfiremass" )
local varFireForce = GetConVar(gsUnit.."_maxfireforce")

AddCSLuaFile(gsUnit.."/wire_wrapper.lua")
include(gsUnit.."/wire_wrapper.lua")

if(not file.Exists(gsUnit.."_tool","DATA")) then
  file.CreateDir(gsUnit.."_tool")
end

function ENT:Print(...)
  if(not varLogUsed:GetBool()) then return end;
  local sD = os.date("%y-%m-%d").." "..os.date("%H:%M:%S")
  local sI = (SERVER and "SERVER" or (CLIENT and "CLIENT" or "NOINST"))
  local sL = gsFormHead:format(sD, sI, tostring(self))
  if(varLogFile:GetBool()) then local tD, iD = {...}, 1
    sL = sL..tostring(tD[1]); iD = (iD + 1)
    while(tD[iD]) do local sS = tostring(tD[iD])
      sL, iD = sL..gsFormItem:format(sS), (iD + 1) end
    file.Append(gsUnit.."_tool/system_log.txt", sL.."\n")
  else print(sL, ...) end
end
