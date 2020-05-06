-- This is the primary barebones gamemode script and should be used to assist in initializing your game mode


-- Set this to true if you want to see a complete debug output of all events/processes done by barebones
-- You can also change the cvar 'barebones_spew' at any time to 1 or 0 for output/no output
BAREBONES_DEBUG_SPEW = false

if GameMode == nil then
		DebugPrint( '[BAREBONES] creating barebones game mode' )
		_G.GameMode = class({})
end

-- This library allow for easily delayed/timed actions
require('libraries/timers')
-- This library can be used for advancted physics/motion/collision of units.  See PhysicsReadme.txt for more information.
require('libraries/physics')
-- This library can be used for advanced 3D projectile systems.
require('libraries/projectiles')
-- This library can be used for sending panorama notifications to the UIs of players/teams/everyone
require('libraries/notifications')
-- This library can be used for starting customized animations on units from lua
require('libraries/animations')

-- These internal libraries set up barebones's events and processes.  Feel free to inspect them/change them if you need to.
require('internal/gamemode')
require('internal/events')

-- settings.lua is where you can specify many different properties for your game mode and is one of the core barebones files.
require('settings')
-- events.lua is where you can specify the actions to be taken when any event occurs and is one of the core barebones files.
require('events')
require('lua_modifiers/resurrect')
require('lua_modifiers/walk_animation')

local evilMagusDied = false

--[[
	This function should be used to set up Async precache calls at the beginning of the gameplay.

	In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
	after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
	be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
	precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
	defined on the unit.

	This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
	time, you can call the functions individually (for example if you want to precache units in a new wave of
	holdout).

	This function should generally only be used if the Precache() function in addon_game_mode.lua is not working.
]]
function GameMode:PostLoadPrecache()
	DebugPrint("[BAREBONES] Performing Post-Load precache")    
	--PrecacheItemByNameAsync("item_example_item", function(...) end)
	--PrecacheItemByNameAsync("example_ability", function(...) end)

	--PrecacheUnitByNameAsync("npc_dota_hero_viper", function(...) end)
	--PrecacheUnitByNameAsync("npc_dota_hero_enigma", function(...) end)
end

--[[
	This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
	It can be used to initialize state that isn't initializeable in InitGameMode() but needs to be done before everyone loads in.
]]
function GameMode:OnFirstPlayerLoaded()
	DebugPrint("[BAREBONES] First Player has loaded")
end

--[[
	This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
	It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function GameMode:OnAllPlayersLoaded()
	DebugPrint("[BAREBONES] All Players have loaded into the game")
end

--[[
	This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
	if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
	levels, changing the starting gold, removing/adding abilities, adding physics, etc.

	The hero parameter is the hero entity that just spawned in
]]
function GameMode:OnHeroInGame(hero)
	DebugPrint("[BAREBONES] Hero spawned in game for first time -- " .. hero:GetUnitName())

	-- This line for example will set the starting gold of every hero to 500 unreliable gold
	hero:SetGold(500, false)
	hero:SetAbilityPoints(0)
	for i=0,hero:GetAbilityCount()-1 do
		local ability = hero:GetAbilityByIndex(i)
		if ability then ability:SetLevel(1) end
	end
	-- These lines will create an item and add it to the player, effectively ensuring they start with the item
	-- local item = CreateItem("item_example_item", hero, hero)
	-- hero:AddItem(item)
end

--[[
	This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
	gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
	is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function GameMode:OnGameInProgress()
	DebugPrint("[BAREBONES] The game has officially begun")
	--GameMode:DoStartSequence()
	Convars:RegisterCommand('do_start_sequence', Dynamic_Wrap(GameMode, 'DoStartSequence'), "do_start_sequence", 0)
	Convars:RegisterCommand('do_vscript_check', Dynamic_Wrap(GameMode, 'DoVscriptCheck'), "do_vscript_check", 0)
	Convars:RegisterCommand('do_freeze_players', Dynamic_Wrap(GameMode, 'DoFreezePlayers'), "do_freeze_players", 0)
	Convars:RegisterCommand('do_unfreeze_players', Dynamic_Wrap(GameMode, 'DoUnfreezePlayers'), "do_unfreeze_players", 0)

	GameMode:RefreshGame()

	Timers:CreateTimer(30, -- Start this timer 30 game-time seconds later
		function()
			DebugPrint("This function is called 30 seconds after the game begins, and every 30 seconds thereafter")
			return 30.0 -- Rerun this timer every 30 game-time seconds 
		end)
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initiggGggalize any values/tables that will be needed later
function GameMode:InitGameMode()
	GameMode = self
	DebugPrint('[BAREBONES] Starting to load Barebones gamemode...')

	-- Call the internal function to set up the rules/behaviors specified in constants.lua
	-- This also sets up event hooks for all event handlers in events.lua
	-- Check out internals/gamemode to see/modify the exact code
	GameMode:_InitGameMode()
	DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')
end

function GameMode:KillNPCs()
	local units = Entities:FindAllByClassname('npc_dota_creature')
	for i=1, table.getn(units) do
		if units[i] then units[i]:ForceKill(false) end
	end
end

function GameMode:SpawnNPCs()
	local spawnLocation0 = Entities:FindByName( nil, "zombie_spawner0" ):GetAbsOrigin()
	local unit = CreateUnitByName( 'npc_dota_creature_evil_magus', spawnLocation0, true, nil, nil, DOTA_TEAM_BADGUYS )
end

function GameMode:RefreshGame()
	DebugPrint("gamemode.lua:GameMode:RefreshGame")
	GameMode:KillNPCs()
	local heroes = GetPlayerHeroes()
	evilMagusDied = false
	for i=1, table.getn(heroes) do
		local hero = heroes[i]
		hero:SetRespawnsDisabled(false)
		if not hero:IsAlive() then
			hero:RespawnHero(false, false, false)
		end
		hero:AddNewModifier(hero, nil, 'modifier_resurrect_lua', {})
		local modifier = hero:FindModifierByName('modifier_resurrect_lua')
		if modifier then 
			modifier:SetStackCount(2)
		end
	end
end

function GameMode:DoStartSequence()
	DebugPrint("gamemode.lua:GameMode:DoStartSequence")
	GameMode:RefreshGame()
end

function GameMode:DoVscriptCheck()
	DebugPrint("gamemode.lua:GameMode:DoVscriptCheck")
	Timers:CreateTimer(0, function()
		local spawnLocation = Entities:FindByName( nil, "zombie_spawner" ):GetAbsOrigin()
		local unit = CreateUnitByName( 'npc_dota_creature_ghostlord', spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS )
		local _rpgAI = unit._rpgAI
		return nil
	end)
end

function GameMode:DoFreezePlayers()
	DebugPrint("gamemode.lua:GameMode:DoFreezePlayers")
	local heroes = GetPlayerHeroes()
	for i=1, table.getn(heroes) do
		if heroes[i] then heroes[i]:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE) end
	end
end

function GameMode:DoUnfreezePlayers()
	DebugPrint("gamemode.lua:GameMode:DoUnfreezePlayers")
	local heroes = GetPlayerHeroes()
	for i=1, table.getn(heroes) do
		if heroes[i] then heroes[i]:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND) end
	end
end

function GameMode:EvilMagusDied()
	DebugPrint("gamemode.lua:GameMode:EvilMagusDied")
	if not evilMagusDied then
		evilMagusDied = true
		local spawnLocation1 = Entities:FindByName( nil, "zombie_spawner1" ):GetAbsOrigin()
		local spawnLocation2 = Entities:FindByName( nil, "zombie_spawner2" ):GetAbsOrigin()
		local unit = CreateUnitByName( 'npc_dota_creature_icelord', spawnLocation1, true, nil, nil, DOTA_TEAM_BADGUYS )
		local unit = CreateUnitByName( 'npc_dota_creature_ghostlord', spawnLocation2, true, nil, nil, DOTA_TEAM_BADGUYS )
	end
end
