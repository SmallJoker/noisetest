-- noisetest by Krock based on noisegrid 0.2.3 by paramat
-- License: WTFPL

noisetest = {}
noisetest_params = {}
noisetest.mod_path = minetest.get_modpath("noisetest")
noisetest.file_path = minetest.get_worldpath().."/noisetest_params.txt"
noisetest.defaults_path = noisetest.mod_path.."/config.default.txt"
noisetest.settings_path = minetest.get_worldpath().."/noisetest_settings.txt"

-- noise definitions
noisetest_params.np_base = {
	offset = 0,
	scale = 1,
	spread = {x=1024, y=1024, z=1024},
	octaves = 6,
	persist = 0.6
}

-- "flat" noise for biomes
noisetest_params.np_biome = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=512, z=512},
	octaves = 1,
	persist = 0.2
}

noisetest_params.np_cliffs = {
	offset = 0,
	scale = 1,
	spread = {x=32, y=32, z=32},
	octaves = 1,
	persist = 0.2
}

-- tree chances - forests
noisetest_params.np_trees = {
	offset = 0,
	scale = 1,
	spread = {x=128, y=128, z=128},
	octaves = 1,
	persist = 0.2
}

noisetest_params.np_caves = {
	offset = 0,
	scale = 1,
	spread = {x=16, y=16, z=16},
	octaves = 1,
	persist = 0.2
}

noisetest_params.np_flatten = {
	offset = 0,
	scale = 1,
	spread = {x=32, y=32, z=32},
	octaves = 2,
	persist = 0.2
}

-- Stuff
dofile(noisetest.mod_path.."/functions.lua")
if noisetest.load_data() then
	print("[noisetest] Loaded world config")
else
	print("[noisetest] Created new world config")
end
dofile(noisetest.mod_path.."/nodes.lua")

-- set mapgen to singlenote
minetest.register_on_mapgen_init(function(mgparams)
	minetest.set_mapgen_params({mgname="singlenode"})
end)

minetest.register_chatcommand("regenerate", {
	description = "Regenerates 16^3 nodes around you",
	privs = {server=true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		local pos = vector.round(player:getpos())
		
		local pos1 = vector.new(pos)
		local minp = vector.subtract(pos1, {x=26,y=16,z=26})
		local pos2 = vector.new(pos)
		local maxp = vector.add(pos2, {x=26,y=16,z=26})
		noisetest.generate(minp, maxp, -6.66)
		
		minetest.chat_send_player(name, "Done!")
	end
})

local biomes = { VERY_COLD = -3, COLD_ARCTIC = -2, ARCTIC = -1, GRASS = 0, JUNGLE = 1, DESERT = 2, HOT_DESERT = 3}
local lastPos = {x=6.66,y=6.66,z=6.66}

noisetest.generate = function(minp, maxp, seed)
	if vector.equals(minp, lastPos) then
		print("[noisetest] Nope.")
		return
	end
	lastPos = vector.new(minp)
	
	local t1 = os.clock()
	local sidelen = maxp.x - minp.x + 1
	local chucen = math.floor((sidelen / 2) + 0.5)
	local doBiomes = maxp.y < noisetest_params.limit_top and (minp.y + sidelen > -40)
	
	local vm, emin, emax
	if seed == -6.66 then
		vm = minetest.get_voxel_manip()
		emin, emax = vm:read_from_map(minp, maxp)
		print("[noisetest] Generate on request")
	else
		vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	end
	
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	if seed == -6.66 then
		for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			local vi = area:index(minp.x, y, z)
			for x = minp.x, maxp.x do
				data[vi] = noisetest.c_air
				vi = vi + 1
			end
		end
		end
	end
	
	local chulens = {x=sidelen, y=sidelen, z=sidelen}
	local nvals_base = minetest.get_perlin_map(noisetest_params.np_base, chulens):get2dMap_flat({x=minp.x, y=minp.z})
	local nvals_biome, nvals_cliffs, nvals_caves, nvals_flatten
	if doBiomes then -- limits
		nvals_flatten = minetest.get_perlin_map(noisetest_params.np_flatten, chulens):get2dMap_flat({x=minp.x, y=minp.z})
		nvals_biome = minetest.get_perlin_map(noisetest_params.np_biome, chulens):get2dMap_flat({x=minp.x, y=minp.z})
		nvals_trees = minetest.get_perlin_map(noisetest_params.np_trees, chulens):get2dMap_flat({x=minp.x, y=minp.z})
		if noisetest_params.generate_cliffs then
			nvals_cliffs = minetest.get_perlin_map(noisetest_params.np_cliffs, chulens):get2dMap_flat({x=minp.x, y=minp.z})
		end
	end
	if noisetest_params.cave_style == 1 and minp.y < -20 then
		nvals_caves = minetest.get_perlin_map(noisetest_params.np_caves, chulens):get2dMap_flat({x=minp.x + minp.z, y=minp.y})
	end
	
	local ysurf_cache = {}
	local biome_cache = {}
	local nixz = 1
	for x = minp.x, maxp.x do
	for z = minp.z, maxp.z do
		local ysurf = (nvals_base[nixz] * 60)	--surface Y
		local biome, under = biomes.GRASS, noisetest.c_dirt
		local canyon, river_water, sand = 0, false, true --defaults
		ysurf = math.abs(ysurf) - 10
		
		if doBiomes then
			local n_biome = nvals_biome[nixz] * 10
			if n_biome > noisetest_params.hot_desert then
				biome = biomes.HOT_DESERT
				under = noisetest.c_desert_sand
			elseif n_biome > noisetest_params.desert then
				biome = biomes.DESERT
				under = noisetest.c_desert_sand
			elseif n_biome > noisetest_params.jungle then
				biome = biomes.JUNGLE
			elseif n_biome < noisetest_params.very_cold then
				biome = biomes.VERY_COLD
				under = noisetest.c_ice
			elseif n_biome < noisetest_params.cold_arctic then
				biome = biomes.COLD_ARCTIC
			elseif n_biome < noisetest_params.arctic then
				biome = biomes.ARCTIC
			end
			
			if n_biome < 0.1 and n_biome > -0.1 then
				canyon = math.abs(n_biome) * 8
			end
			
			if noisetest_params.generate_cliffs then
				local n_cliffs = math.abs(nvals_cliffs[nixz] * 6)
				if ysurf > noisetest_params.water_level then
					--generate cliffs!
					if n_biome < -0.8 then
						n_cliffs = n_cliffs + (n_biome / 2)
					end
					if n_cliffs > 2.5 then
						ysurf = ysurf + n_cliffs
					end
				end
				--dirty beaches!
				if n_cliffs < 3 and biome <= biomes.GRASS then
					sand = false
				end
			end
			
			if ysurf < 80 and ysurf > -30 and canyon ~= 0 then -- canyons
				local depth = (1 - canyon) * 6
				ysurf = ysurf - depth
				if depth > 4.1 then
					river_water = true
				end
			end
			local snow = biome <= biomes.COLD_ARCTIC
			if not snow and n_biome < noisetest_params.arctic / 2 then
				local snowchance = 20 + math.floor(n_biome * 5)
				if snowchance <= 1 or math.random(snowchance) == 1 then
					snow = true
				end
			end
			
			biome_cache[nixz] = {biome, river_water, sand, under, snow, n_biome}
		end
		if ysurf > noisetest_params.limit_top then
			ysurf = noisetest_params.limit_top
		end
		
		ysurf_cache[nixz] = ysurf
		nixz = nixz + 1
	end
	end
	
	if doBiomes and noisetest_params.area_flatten then
	--Flatten
	local maxIndx = nixz
	for x = 4, sidelen - 4, 4 do
	for z = 4, sidelen - 4, 4 do
		nixz = (z * sidelen) + x
		local n_flatten = nvals_flatten[nixz] * 5 + 2
		local biome = biome_cache[nixz][6]
		if n_flatten > 2 and math.abs(biome) > 0.8 then
			n_flatten = math.floor(n_flatten + 0.5)
			if n_flatten > 4 then n_flatten = 4 end
			
			local avg, count = 0, 0
			for i = -n_flatten, n_flatten do --x
			for j = -n_flatten, n_flatten do --z
				if (i * i) + (j * j) < n_flatten * n_flatten * 1.4 then
					local g = ((z + j) * sidelen) + (x + i)
					if g < maxIndx and g > 0 then
						avg = avg + ysurf_cache[g]
						count = count + 1
					end
				end
			end
			end
			
			if count > 3 then
				local heigh = avg / count + 0.7
				for i = -n_flatten, n_flatten do --x
				for j = -n_flatten, n_flatten do --z
					if (i * i) + (j * j) < n_flatten * n_flatten * 1.4 then
						local g = ((z + j) * sidelen) + (x + i)
						if g < maxIndx and g > 0 then
							ysurf_cache[g] = heigh
						end
					end
				end
				end
			end
		end
	end
	end
	end
	
	nixz = 1
	local real_ore_chance = -1
	for z = minp.z, maxp.z do
	for y = minp.y, maxp.y do
		local vi = area:index(minp.x, y, z)
		local via = area:index(minp.x, y+1, z)
		for x = minp.x, maxp.x do
			local ysurf = math.floor(ysurf_cache[nixz] + 0.5)
			local biome, under = biomes.GRASS, 0
			local river_water, sand, snow = false, false, false
			local stone = noisetest.c_stone
			
			if doBiomes then
				local biome_arr = biome_cache[nixz]
				biome = biome_arr[1]
				river_water = biome_arr[2]
				sand = biome_arr[3]
				under = biome_arr[4]
				snow = biome_arr[5]
			end
			
			if biome >= biomes.DESERT then
				stone = noisetest.c_desert_stone
			end
			
			-- cave generation part
			local is_cave, is_lava = false, false
			if noisetest_params.cave_style == 1 and y < -20 then
				local caves = {}
				local orgpos = {x=x-minp.x, y=y-minp.y,z=z-minp.z}
				caves[1] = nvals_caves[(orgpos.z * sidelen) + orgpos.y + 1]
				caves[2] = nvals_caves[(orgpos.y * sidelen) + orgpos.x + 1]
				
				is_cave = math.abs(caves[1]) > 0.7 and math.abs(caves[2]) > 0.7
				if y < -50 then
					local caves_lava = nvals_caves[(orgpos.x * sidelen) + orgpos.z + 1]
					is_lava = caves_lava > noisetest_params.lava_amount
				end
			end
			
			if is_cave then
				if is_lava then
					data[vi] = noisetest.c_lava
				else
					data[vi] = noisetest.c_air
				end
			elseif y < ysurf and y >= ysurf - 3 then
				data[vi] = under
			elseif y <= ysurf - 4 then
				-- calculate ore chance by depth, if not calculated yet
				if real_ore_chance < 0 then
					real_ore_chance = noisetest_params.ore_chance - ((ysurf - y) / 6)
					real_ore_chance = math.max(math.floor(real_ore_chance), noisetest_params.ore_min_chance)
				end
				
				if math.random(real_ore_chance) == 2 then
					local osel = math.random(50)
					local ore = noisetest.c_scoal
					if osel >= 48 then
						ore = noisetest.c_sdiamond
					elseif osel >= 45 then
						ore = noisetest.c_smese
					elseif osel == 42 then
						ore = noisetest.c_sgold
					elseif osel >= 36 then
						ore = noisetest.c_scopper
					elseif osel >= 18 then
						ore = noisetest.c_siron
					end
					-- spread sphere-like the ores
					noisetest.gen_ores(data, area, {x=x, y=y, z=z}, ore)
				elseif data[vi] == noisetest.c_air then
					data[vi] = stone
				end
			elseif snow and y == ysurf and y > noisetest_params.beaches_y_start and not sand and not river_water then
				-- Snow
				
				data[vi] = noisetest.c_dirt_snow
				if biome <= biomes.ARCTIC then
					data[via] = noisetest.c_snow
				end
			elseif y >= ysurf and y <= noisetest_params.beaches_y_start then
				if y == ysurf then
					-- Beaches
					
					if y <= noisetest_params.beaches_y_end then
						data[vi] = stone
					elseif snow and y >= noisetest_params.water_level then
						-- Snow beaches
						data[vi] = noisetest.c_dirt_snow
						if biome <= biomes.COLD_ARCTIC then
							data[via] = noisetest.c_snow
						end
					else
						-- Oceans
						if sand then
							data[vi] = noisetest.c_sand
						elseif y >= noisetest_params.water_level then
							data[vi] = noisetest.c_grass
							if y == noisetest_params.water_level and math.random(noisetest_params.papyrus_chance) == 2 then
								for i=1, math.random(4, 6) do
									data[area:index(x, y + i, z)] = noisetest.c_papyrus
								end
							end
						else
							data[vi] = noisetest.c_dirt
						end
					end
				elseif y <= noisetest_params.water_level then
					-- Oceans & ice
					
					if biome <= biomes.COLD_ARCTIC and y > - noisetest_params.beaches_y_start then
						if biome <= biomes.VERY_COLD then
							data[vi] = noisetest.c_ice
						else
							if snow or math.random(6) == 2 then
								data[vi] = noisetest.c_ice
							else
								data[vi] = noisetest.c_water
							end
						end
					else
						data[vi] = noisetest.c_water
					end
				end
			elseif y == ysurf then
				-- Normal biomes & rivers
				
				if river_water then
					data[vi] = noisetest.c_water
				elseif biome == biomes.GRASS or biome == biomes.JUNGLE then
					local dirt = false
					local forest = (nvals_trees[nixz] - 0.2) * noisetest_params.forest_factor
					forest = math.floor(forest + 0.5)
					
					if biome == biomes.JUNGLE then
						if math.random(noisetest_params.jungle_tree_chance) == 2 then
							noisetest.gen_jungletree(x, y + 1, z, area, data)
							dirt = true
						elseif math.random(noisetest_params.jungle_grass_chance) == 2 then
							data[via] = noisetest.c_jgrass
						end
					else
						if math.random(noisetest_params.apple_tree_chance + forest) == 2 then
							noisetest.gen_appletree(x, y + 1, z, area, data)
							dirt = true
						else
							if math.random(noisetest_params.flora_chance) == 2 then
								data[via] = noisetest.get_flower()
							elseif math.random(noisetest_params.grass_chance) == 2 then
								data[via] = noisetest["c_grass"..(math.random(5))]
							end
						end
					end
					if dirt then
						data[vi] = noisetest.c_dirt
					else
						data[vi] = noisetest.c_grass
					end
				elseif biome >= biomes.DESERT then -- desert
					if math.random(noisetest_params.cactus_chance) == 2 then
						for i=1, math.random(4, 7) do
							data[area:index(x, y + i, z)] = noisetest.c_cactus
						end
					elseif biome == biomes.HOT_DESERT then
						data[via] = noisetest.c_desert_sand
					elseif math.random(noisetest_params.cactus_chance / 2) == 2 then
						data[via] = noisetest.c_dry_shrub
					end
					data[vi] = noisetest.c_desert_sand
				elseif biome <= biomes.VERY_COLD then
					data[vi] = noisetest.c_ice
				elseif biome <= biomes.ARCTIC then
					if math.random(noisetest_params.apple_tree_chance * 3) == 2 then
						noisetest.gen_appletree(x, y+1, z, area, data)
					end
					if biome == biomes.ARCTIC then
						data[vi] = noisetest.c_grass
					else
						data[vi] = noisetest.c_dirt_snow
					end
				end
			end
			
			nixz = nixz + 1
			vi = vi + 1
			via = via + 1
		end
		nixz = nixz - sidelen
	end
	nixz = nixz + sidelen
	end
	
	if noisetest_params.cave_style == 2 and maxp.y < -20 then
		local rand = center - 20
		for i=1,5 do
			if math.random(i + 1) >= i - 1 then
				noisetest.gen_cave(data, area, {
					x = minp.x + chucen + math.random(-rand, rand), 
					y = minp.y + chucen + math.random(-rand, rand),
					z = minp.z + chucen + math.random(-rand, rand)
				}, math.random(4) == 1)
			end
		end
	end
	
	if seed == -6.66 then
		vm:set_data(data)
		vm:write_to_map()
		vm:update_map()
	else
		vm:set_data(data)
		vm:set_lighting({day=0, night=0})
		vm:calc_lighting()
		vm:write_to_map(data)
		vm:update_liquids()
	end
	local chugent = math.ceil((os.clock() - t1) * 1000)
	print ("[noisetest] "..minetest.pos_to_string(minp).." - "..chugent.." ms")
end

minetest.register_on_generated(noisetest.generate)