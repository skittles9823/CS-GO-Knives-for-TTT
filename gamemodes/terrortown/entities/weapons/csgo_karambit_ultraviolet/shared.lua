
AddCSLuaFile()

SWEP.HoldType = "knife"

if ( CLIENT ) then
  SWEP.PrintName      = "Karambit Knife | Ultraviolet"
  SWEP.DrawAmmo       = false
  SWEP.DrawCrosshair    = true
  SWEP.ViewModelFOV   = 65
  SWEP.ViewModelFlip    = false
  SWEP.CSMuzzleFlashes  = true
  SWEP.UseHands     = true
  
  SWEP.Slot       = 2
  SWEP.SlotPos      = 0
  --SWEP.IconLetter     = "j"

  --killicon.AddFont("weapon_knife", "CSKillIcons", SWEP.IconLetter, Color( 255, 80, 0, 255 ))
  --surface.CreateFont("CSKillIcons", {font = "csd", size = ScreenScale(30), weight = 500, antialias = true, additive = true})
  --surface.CreateFont("CSSelectIcons", {font = "csd", size = ScreenScale(60), weight = 500, antialias = true, additive = true})
end

SWEP.Base = "csgo_baseknife"

SWEP.Category     = "CS:GO Knives"

SWEP.Spawnable        = true
SWEP.AdminSpawnable     = true

SWEP.ViewModel 			= "models/weapons/v_csgo_karambit.mdl"
SWEP.WorldModel 		= "models/weapons/w_csgo_karambit.mdl" 

SWEP.DrawCrosshair      = false
SWEP.Primary.Damage         = 50
SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Delay = 0.6
SWEP.Primary.Ammo       = "none"
SWEP.Secondary.Damage   = 75
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo     = "none"
SWEP.Secondary.Delay = 1.8

SWEP.DrawWeaponInfoBox    = false

SWEP.Weight         = 5
SWEP.AutoSwitchTo       = false
SWEP.AutoSwitchFrom     = false
SWEP.Skin 					= "models/csgo_knife/karam_ultraviolet.vmt"

SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP2
SWEP.AutoSpawnable = false
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false

SWEP.Primary.ClipSize     = -1
SWEP.Primary.Damage         = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = true
SWEP.Primary.Ammo         ="none"


SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip    = -1
SWEP.Secondary.Damage     = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo         ="none"

function SWEP:SetupDataTables() --This also used for variable declaration and SetVar/GetVar getting work
    self:NetworkVar( "Float", 0, "InspectTime" )
    self:NetworkVar( "Float", 1, "IdleTime" )
    self:NetworkVar( "String", 0, "Classname" ) --Do we need this?
    self:NetworkVar( "Bool", 0, "Thrown" )
    -- self:NetworkVar( "Entity", 0, "Attacker" ) --Do we need this?
    -- self:NetworkVar( "Entity", 1, "Victim" ) --Do we need this?
    self:NetworkVar( "Entity", 2, "ViewModel" )
end



function SWEP:Initialize()
  if ( CLIENT ) then surface.SetMaterial(Material( self.Skin or "models/csgo_knife/cssource" )) end --Ugly hack. Used to "precache" skin's material
    self:SetClassname(self:GetClass())
  self:SetHoldType( self.AreDaggers and "fist" or "knife" ) -- Avoid using SetWeaponHoldType! Otherwise the players could hold it wrong!
end 



function SWEP:ViewModelDrawn(ViewModel)
    self:SetViewModel(ViewModel) -- Stores viewmodel's entity into NetworkVar, NOT actually changes viewmodel. Do we need this?
    self:PaintMaterial(ViewModel)
end



--function SWEP:PostDrawViewModel( vm, ply, weapon )
--    if ( CLIENT ) and IsValid(vm) then vm:SetMaterial() end
--end



function SWEP:PaintMaterial(vm)
    if ( CLIENT ) and IsValid(vm) then
            local Mat = self:GetThrown() and "" or ( self.Skin or "" )
      if IsValid(vm) and vm:GetModel() == self.ViewModel then vm:SetMaterial(Mat) end
  end
end



function SWEP:ClearMaterial()
    if IsValid(self.Owner) then
    local Viewmodel = self.Owner:GetViewModel()
    if IsValid(Viewmodel) then Viewmodel:SetMaterial("") end
  end
end



function SWEP:Think()
  if CurTime()>=self:GetIdleTime() then
      self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
      self:SetIdleTime( CurTime() + self.Owner:GetViewModel():SequenceDuration() )
  end
end



function SWEP:DrawWorldModel()
  self:SetMaterial(self.Skin or "")
  self:DrawModel()
end



function SWEP:Deploy()
    self:SetInspectTime( 0 )
  self:SetIdleTime( CurTime() + self.Owner:GetViewModel():SequenceDuration() )
  self.Weapon:SendWeaponAnim( ACT_VM_DRAW )
    local NextAttack = 1
  self.Weapon:SetNextPrimaryFire( CurTime() + NextAttack )
  self.Weapon:SetNextSecondaryFire( CurTime() + NextAttack )
  -- self.Weapon:EmitSound( "Weapon_Knife.Deploy" ) -- The deploy sound should be played only from v_ model
  return true
end



function SWEP:EntityFaceBack(ent)
  local angle = self.Owner:GetAngles().y -ent:GetAngles().y
  if angle < -180 then angle = 360 +angle end
  if angle <= 90 and angle >= -90 then return true end
  return false
end



function SWEP:PrimaryAttack()
    if CurTime() < self.Weapon:GetNextPrimaryFire() then return end
    self:DoAttack( false )
end



function SWEP:SecondaryAttack()
    if CurTime() < self.Weapon:GetNextSecondaryFire() then return end
    self:DoAttack( true )
end



function SWEP:DoAttack( Altfire )
    local Weapon    = self.Weapon
    local Attacker  = self:GetOwner()
    local Range     = Altfire and 48 or 64
    local Forward   = Attacker:GetAimVector()
  local AttackSrc = Attacker:EyePos()
  local AttackEnd = AttackSrc + Forward * Range
    local Act
    local Snd
    local Backstab
    local Damage
    
    Attacker:LagCompensation(true)
    
    local tracedata = {}

  tracedata.start     = AttackSrc
  tracedata.endpos    = AttackEnd
  tracedata.filter    = Attacker
    tracedata.mask      = MASK_SOLID
    tracedata.mins      = Vector( -16 , -16 , -18 )
    tracedata.maxs      = Vector( 16, 16 , 18 )
  
    -- We should calculate trajectory twice. If TraceHull hits entity, then we use second trace, otherwise - first.
    -- It's needed to prevent head-shooting since in CS:GO you cannot headshot with knife
    local tr1 = util.TraceLine( tracedata )
    local tr2 = util.TraceHull( tracedata )
    local tr = IsValid(tr2.Entity) and tr2 or tr1
    
    Attacker:LagCompensation(false) -- Don't forget to disable it!
    
    local DidHit            = tr.Hit and not tr.HitSky
    -- local trHitPos          = tr.HitPos -- Unused
    local HitEntity         = tr.Entity
    local DidHitPlrOrNPC    = HitEntity and ( HitEntity:IsPlayer() or HitEntity:IsNPC() ) and IsValid( HitEntity )
    
    -- Calculate damage and deal hurt if we can
    if DidHit then
        if HitEntity and IsValid( HitEntity ) then
            Backstab = DidHitPlrOrNPC and self:EntityFaceBack( HitEntity ) -- Because we can only backstab creatures
            Damage = ( Altfire and (Backstab and 180 or 65) ) or ( Backstab and 90 ) or ( ( math.random(0,5) == 3 ) and 40 ) or 25
            
            local damageinfo = DamageInfo()
            damageinfo:SetAttacker( Attacker )
            damageinfo:SetInflictor( self )
            damageinfo:SetDamage( Damage )
            damageinfo:SetDamageType( bit.bor( DMG_BULLET , DMG_NEVERGIB ) )
            damageinfo:SetDamageForce( Forward * 1000 )
            damageinfo:SetDamagePosition( AttackEnd )
            HitEntity:DispatchTraceAttack( damageinfo, tr, Forward )
            
        else
            util.Decal("ManhackCut", tr.HitPos + tr.HitNormal, tr.HitPos - tr.HitNormal)
            -- Old bullet's mechanic. Caused an one hilarious bug. Left for history.
            
            --local Dir = ( trHitPos - AttackSrc )
            --local Bulletinfo = {}
            --Bulletinfo.Attacker = Attacker
            --Bulletinfo.Num      = 1
            --Bulletinfo.Damage   = 0 
            --Bulletinfo.Distance = Range
            --Bulletinfo.Force    = 10
            --Bulletinfo.Tracer   = 0
            --Bulletinfo.Dir      = Dir
            --Bulletinfo.Src      = AttackSrc
            --self:FireBullets( Bulletinfo )
        end
    end
    
    --Change next attack time
    local NextAttack = Altfire and 1.0 or DidHit and 0.5 or 0.4
    Weapon:SetNextPrimaryFire( CurTime() + NextAttack )
  Weapon:SetNextSecondaryFire( CurTime() + NextAttack )
    
    --Send animation to attacker
    Attacker:SetAnimation( PLAYER_ATTACK1 )
    
    --Send animation to viewmodel
    Act = DidHit and ( Altfire and ( Backstab and ACT_VM_SWINGHARD or ACT_VM_HITCENTER2 ) or ( Backstab and ACT_VM_SWINGHIT or ACT_VM_HITCENTER) ) or ( Altfire and ACT_VM_MISSCENTER2 or ACT_VM_MISSCENTER)
    if Act then
        Weapon:SendWeaponAnim( Act )
        self:SetIdleTime( CurTime() + self.Owner:GetViewModel():SequenceDuration() )
    end
    
    --Play sound
    local Oldsounds
    if GetConVar("csgo_knives_oldsounds") then Oldsounds = GetConVar("csgo_knives_oldsounds"):GetBool() else Oldsounds = false end
    local StabSnd    = "csgo_knife.Stab"
    local HitSnd     = "csgo_knife.Hit"
    local HitwallSnd = Oldsounds and "csgo_knife.HitWall_old" or "csgo_knife.HitWall"
    local SlashSnd   = Oldsounds and "csgo_knife.Slash_old" or "csgo_knife.Slash"
    Snd = DidHitPlrOrNPC and (Altfire and StabSnd or HitSnd) or DidHit and HitwallSnd or SlashSnd
    if Snd then Weapon:EmitSound( Snd ) end
    
    return true
end



function SWEP:Reload()
  
  local getseq = self:GetSequence()
  local act = self:GetSequenceActivity(getseq) --GetActivity() method doesn't work :\
  if (act == ACT_VM_IDLE_LOWERED and CurTime() < self:GetInspectTime()) then
        self:SetInspectTime( CurTime() + 0.1 ) -- We should press R repeately instead of holding it to loop
        return end

  self.Weapon:SendWeaponAnim(ACT_VM_IDLE_LOWERED)
  self:SetIdleTime( CurTime() + self.Owner:GetViewModel():SequenceDuration() )
    self:SetInspectTime( CurTime() + 0.1 )
  return true
end



function SWEP:Equip()
    self:SetThrown(false)
end

function SWEP:OwnerChanged()
    self:ClearMaterial()
  return true
end

function SWEP:OnRemove()
    self:ClearMaterial()
  return true
end

--function SWEP:OnDrop()
--    self:Remove()
--end

function SWEP:Holster()
    self:ClearMaterial()
    return true
end

--YOU'RE WINNER!