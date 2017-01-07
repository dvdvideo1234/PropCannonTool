--[[
  ~ Prop Cannon (shar'd) ~
  ~ Lexi ~
--]]
ENT.Type            = "anim"
if (WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = "Prop Cannon Gun"
else
  ENT.Base          = "base_gmodentity"
end
ENT.PrintName       = "Prop Cannon Gun"
ENT.Author          = "Lexi"              -- Fixed for gmod13 dvd_video
ENT.Contact         = "lexi@lexi.org.uk"  -- dvd_video@abv.bg
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

function pcnRoundValue(exact, frac)
  local q,f = math.modf(exact/frac)
  return frac * (q + (f > 0.5 and 1 or 0))
end

local pcnPrefx   = ENT.PrintName:gsub(" ", "_"):lower()
local pcnFvars   = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local varLogFile = CreateConVar(pcnPrefx.."logfile", "1", pcnFvars, "Enable logging in a file")
local varLogUsed = CreateConVar(pcnPrefx.."logused", "1", pcnFvars, "Enable logging on error")

if(not file.Exists("prop_cannon_tool","DATA") and varLogFile:GetBool()) then
  file.CreateDir("prop_cannon_tool")
end

function ENT:Print(...)
  if(not varLogUsed:GetBool()) then return end;
  local sLin = "["..os.date().."] "..self.PrintName.." > "..tostring(self)..":"
  if(varLogFile:GetBool()) then
    local sDel = "\t"
    local tData, nID = {...}, 1
    while(tData[nID]) do
      sLin, nID = sLin..sDel..tostring(tData[nID]), (nID + 1)
    end; file.Append("prop_cannon_tool/system_log.txt", sLin.."\n")
  else print(sLin,...) end
end
