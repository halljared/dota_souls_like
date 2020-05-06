require('../libraries/timers')

function Enable(args)
	DebugPrint('zombie_spawner.lua:Enable')
	for k,v in pairs(args) do
		print (args)
	end
end

function Spawn(args)
	DebugPrint('zombie_spawner.lua:Spawn')
	local spawnLocation = Entities:FindByName( nil, "zombie_spawner" ):GetAbsOrigin()
	Timers:CreateTimer(0, function()
			--local units = {'npc_dota_creature_icelord', 'npc_dota_creature_corpselord', 'npc_dota_creature_evil_magus', 'npc_dota_creature_werewolf'}
			local units = {'npc_dota_creature_evil_magus'}
			local unit = units[ RandomInt(1, #units) ]
			--unit = CreateUnitByName( unit, spawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS )
			return 60
		end
	)
end

function Activate(args)
	DebugPrint('zombie_spawner.lua:Activate')
	if args then
		for k,v in pairs(args) do
			print (args)
		end
	end
end

function SpawnNPC(args)
	DebugPrint('zombie_spawner.lua:SpawnNPC')
	if args then
		for k,v in pairs(args) do
			print (args)
		end
	end
end
