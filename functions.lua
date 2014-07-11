function noisetest.gen_appletree(x, y, z, area, data)
	for j = -1, 6 do
		if j == 5 or j == 6 then
			for i = -3, 3 do
			for k = -3, 3 do
				local vi = area:index(x + i, y + j, z + k)
				local rd = math.random(50)
				if rd == 2 then
					data[vi] = noisetest.c_apple
				elseif rd >= 10 then
					data[vi] = noisetest.c_leaves
				end
			end
			end
		elseif j == 4 then
			for i = -2, 2 do
			for k = -2, 2 do
				if math.abs(i) + math.abs(k) == 2 then
					local vi = area:index(x + i, y + j, z + k)
					data[vi] = noisetest.c_tree
				end
			end
			end
		else
			local vi = area:index(x, y + j, z)
			data[vi] = noisetest.c_tree
		end
	end
end

function noisetest.gen_jungletree(x, y, z, area, data)
	for j = -1, 14 do
		if j == 8 or j == 10 or j == 14 then
			for i = -3, 3 do
			for k = -3, 3 do
				local vil = area:index(x + i, y + j + math.random(0, 1), z + k)
				if math.random(5) ~= 2 then
					data[vil] = noisetest.c_jleaves
				end
			end
			end
		end
		local vit = area:index(x, y + j, z)
		data[vit] = noisetest.c_jtree
	end
end

function noisetest.get_flower()
	local rand = math.random(6)
	local id = noisetest.c_viola
	if rand == 1 then
		id = noisetest.c_danwhi
	elseif rand == 2 then
		id = noisetest.c_rose
	elseif rand == 3 then
		id = noisetest.c_tulip
	elseif rand == 4 then
		id = noisetest.c_danyel
	elseif rand == 5 then
		id = noisetest.c_geranium
	else
		id = noisetest.c_viola
	end
	return id
end

function noisetest.gen_ores(data, area, pos, node)
	local lim = math.random(3, 16)
	if math.random(3) == 2 then
		lim = math.floor(lim * 1.6)
	end
	
	for z = -2, 2 do
	for y = 0, 4 do
		local vil = area:index(pos.x - 2, pos.y - y, pos.z + z)
		for x = -2, 2 do
			if x == 0 and y == 0 and z == 0 then
				data[vil] = node
			elseif data[vil] == noisetest.c_stone or 
					data[vil] == noisetest.c_desert_stone then
				if (math.abs(x) + 1) * (math.abs(y - 2) + 1) * (math.abs(z) + 1) <= lim and math.random(3) == 2 then
					data[vil] = node
				end
			end
			vil = vil + 1
		end
	end
	end
end

function noisetest.gen_cave(data, area, pos, hasLava)
	--random cave sizes
	local lim_x = math.random(6, 14)
	local lim_y = math.random(3, 6)
	local lim_z = math.random(6, 14)
	local lim = lim_x + lim_y + lim_z
	
	local sum = math.random(lim, lim * 3)
	
	for z = -lim_z, lim_z do
	for y = -lim_y, lim_y do
		local vil = area:index(pos.x - lim_x, pos.y + y, pos.z + z)
		for x = -lim_x, lim_x do
			if (math.abs(x) + 1) * (math.abs(y) + 1) * (math.abs(z) + 1) <= sum then
				if hasLava and y <= -lim_y + 3 then
					data[vil] = noisetest.c_lava
				else
					data[vil] = noisetest.c_air
				end
			end
			vil = vil + 1
		end
	end
	end
end

-- WORLD DATA things
function noisetest.load_data()
	if noisetest.load_seed() then
		print("[noisetest] Loaded world seeds")
	else
		print("[noisetest] Created new world seeds")
	end
	
	dofile(noisetest.defaults_path)
	local file = io.open(noisetest.settings_path, "r")
	if file then
		io.close(file)
		dofile(noisetest.settings_path)
		return true
	end
	io.input(noisetest.defaults_path)
	io.output(noisetest.settings_path)
	
	while true do
		local block = io.read(256) -- 256B at once
		if not block then
			io.close()
			break
		end
		io.write(block)
	end
	return false
end

function noisetest.load_seed()
	local success = true
	local seeds = {9, 9, 9}
	local file = io.open(noisetest.file_path, "r")
	if file then
		local data = string.split(file:read('*all'), "\n", 3)
		seeds = { tonumber(data[1]), tonumber(data[2]), tonumber(data[3]) }
	else
		-- generate new seed
		seeds = {
			math.random(100, 9999) * 1335,
			math.random(100, 9999) * 1337,
			math.random(100, 9999) * 1339 }
		
		file = io.open(noisetest.file_path, "w")
		file:write(tostring(seeds[1]).."\n")
		file:write(tostring(seeds[2]).."\n")
		file:write(tostring(seeds[3]))
		success = false
	end
	io.close(file)

	noisetest_params.np_base.seed = seeds[1]
	noisetest_params.np_biome.seed = seeds[2]
	noisetest_params.np_cliffs.seed = seeds[3]
	noisetest_params.np_caves.seed = seeds[1]
	noisetest_params.np_trees.seed = seeds[2]
	return success
end

-- ABM

-- Appletree sapling
minetest.register_abm({
	nodenames = {"noisetest:sapling"},
	interval = 20,
	chance = 10,
	action = function(pos, node)
		local nu = minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name
		if minetest.get_item_group(nu, "soil") == 0 then
			return
		end
		local vm = minetest.get_voxel_manip()
		local emin, emax = vm:read_from_map(
			{x=pos.x-4, y=pos.y-4, z=pos.z-4}, 
			{x=pos.x+4, y=pos.y+10, z=pos.z+4})
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		noisetest.gen_appletree(pos.x, pos.y, pos.z, area, data)
		vm:set_data(data)
		vm:write_to_map()
		vm:update_map()
	end,
})

-- Jungletree sapling
minetest.register_abm({
	nodenames = {"noisetest:junglesapling"},
	interval = 30,
	chance = 20,
	action = function(pos, node)
		local nu = minetest.get_node({x=pos.x, y=pos.y-1, z=pos.z}).name
		if minetest.get_item_group(nu, "soil") == 0 then
			return
		end
		local vm = minetest.get_voxel_manip()
		local emin, emax = vm:read_from_map(
			{x=pos.x-4, y=pos.y-4, z=pos.z-4}, 
			{x=pos.x+4, y=pos.y+16, z=pos.z+4})
		local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
		local data = vm:get_data()
		noisetest.gen_jungletree(pos.x, pos.y, pos.z, area, data)
		vm:set_data(data)
		vm:write_to_map()
		vm:update_map()
	end,
})

minetest.register_abm({
	nodenames = {"group:av_leafdecay"},
	interval = 10,
	chance = 10,

	action = function(pos, node)
		local trunk_name = minetest.registered_nodes[node.name].trunk_name
		if not trunk_name then return end
		if minetest.find_node_near(pos, 4, {"ignore", trunk_name}) then return end
		
		local drops = minetest.get_node_drops(node.name)
		for _, dropitem in ipairs(drops) do
			if dropitem ~= node.name then
				minetest.add_item(pos, dropitem)
			end
		end
		minetest.remove_node(pos)
		nodeupdate(pos)
	end
})