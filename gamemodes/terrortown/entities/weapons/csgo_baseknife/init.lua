AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

SWEP.Weight				= 30
SWEP.AutoSwitchTo		= true 
SWEP.AutoSwitchFrom		= true	

function SWEP:Initialize()
end

function SWEP:OnRemove()
end