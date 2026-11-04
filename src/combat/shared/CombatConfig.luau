--!strict
-- CombatConfig.luau
-- Shared configuration for Naruto Storm 4 Camera + Movement + Tekken Defense System

local CombatConfig = {}

-- =========================================================
-- CAMERA SETTINGS (Naruto Storm 4 Style)
-- =========================================================
CombatConfig.Camera = {
	MinDistance    = 15,    -- Minimum camera zoom distance (close combat)
	MaxDistance    = 42,    -- Maximum camera zoom distance (far apart)
	BaseHeight     = 6.5,   -- Default camera height above ground
	HeightFactor   = 0.35,  -- How much camera raises when players are in air
	SideOffset     = 3.2,   -- Over-the-shoulder offset
	SmoothSpeed    = 10,    -- Camera lerp responsiveness (higher = snappier)
	FOV_Default    = 65,
	FOV_Dashing    = 75,    -- Dynamic FOV increase during Ninja Dash
}

-- =========================================================
-- MOVEMENT & DASH SETTINGS (Storm 4 Mobility)
-- =========================================================
CombatConfig.Movement = {
	NormalWalkSpeed = 16,
	CombatRunSpeed  = 24,
	NinjaDashSpeed  = 85,    -- High-speed homing dash toward opponent
	NinjaDashRange  = 75,    -- Max range to lock and dash
	DashDuration    = 0.65,  -- Max duration of a single dash
	StopDistance    = 6.0,   -- Stop dash when within melee range
	
	-- Tekken Sidestep
	DoubleTapWindow = 0.28,  -- Seconds between key presses to trigger sidestep
	SidestepDistance = 16,   -- Studs traveled in sidestep arc
	SidestepDuration = 0.22, -- Fast snappy evasion
	SidestepCooldown = 0.60,
}

-- =========================================================
-- DEFENSE & PARRY SETTINGS (Tekken Style)
-- =========================================================
CombatConfig.Defense = {
	MaxGuardHealth     = 100,
	GuardRegenRate     = 15,    -- Per second when not blocking
	GuardDamageStand   = 20,    -- Guard damage absorbed on high/mid hit
	GuardBreakStunTime = 2.2,   -- Stun duration if guard bar breaks (Guard Crush)
	
	-- Tekken Just-Frame Parry
	ParryWindow        = 0.18,  -- 180ms window from pressing F to achieve Perfect Parry
	ParryStaggerTime   = 1.1,   -- Opponent stagger duration on successful parry
}

return CombatConfig
