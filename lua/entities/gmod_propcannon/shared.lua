--[[
  ~ Prop Cannon (shar'd) ~
  ~ Lexi ~
--]]
ENT.Type            = "anim"
if (WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = "Prop Cannon"
else
  ENT.Base          = "base_gmodentity"
end
ENT.PrintName       = "Prop Cannon"
ENT.Author          = "Lexi"              -- Fixed for gmod13 dvd_video
ENT.Contact         = "lexi@lexi.org.uk"  -- dvd_video@abv.bg
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

function RoundValue(exact, frac)
  local q,f = math.modf(exact/frac)
  return frac * (q + (f > 0.5 and 1 or 0))
end