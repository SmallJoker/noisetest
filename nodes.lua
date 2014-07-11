local leaf_visual_scale = 1
local leaf_drawtype = "allfaces_optional"
if noisetest_params.amazing_leaves then
	--new leaf style!
	leaf_visual_scale = 1.2
	leaf_drawtype = "plantlike"
end

local trees = {
	--name = { desc leaves, desc sapling, {textures leaves}, {textures sapling} }
	[""] = "Apple tree",
	jungle = "Jungle",
}

for i,d in pairs(trees) do
minetest.register_node("noisetest:"..i.."leaves", {
	description = d.." leaves",
	drawtype = leaf_drawtype,
	visual_scale = leaf_visual_scale,
	tiles = {"default_"..i.."leaves.png"},
	inventory_image = "default_"..i.."leaves.png",
	paramtype = "light",
	trunk_name = "default:"..i.."tree",
	groups = {snappy=3, flammable=2, av_leafdecay=1},
	drop = {
		max_items = 1,
		items = {
			{items = {"noisetest:"..i.."sapling"}, rarity = 20},
			{items = {"noisetest:"..i.."leaves"}}
		}
	},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("noisetest:"..i.."sapling", {
	description = d.." sapling",
	drawtype = "plantlike",
	tiles = {"default_"..i.."sapling.png"},
	inventory_image = "default_"..i.."sapling.png",
	paramtype = "light",
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
	},
	groups = {snappy=2, dig_immediate=3, flammable=2, attached_node=1},
	sounds = default.node_sound_leaves_defaults(),
})
end

noisetest.c_air			=	minetest.get_content_id("air")
noisetest.c_ignore		=	minetest.get_content_id("ignore")
noisetest.c_grass		=	minetest.get_content_id("default:dirt_with_grass")
noisetest.c_dirt		=	minetest.get_content_id("default:dirt")
noisetest.c_stone		=	minetest.get_content_id("default:stone")
noisetest.c_water		=	minetest.get_content_id("default:water_source")
noisetest.c_lava		=	minetest.get_content_id("default:lava_source")
noisetest.c_ice			=	minetest.get_content_id("default:ice")
noisetest.c_sand		=	minetest.get_content_id("default:sand")

noisetest.c_desert_stone	=	minetest.get_content_id("default:desert_stone")
noisetest.c_desert_sand		=	minetest.get_content_id("default:desert_sand")
noisetest.c_cactus			=	minetest.get_content_id("default:cactus")
noisetest.c_dry_shrub		=	minetest.get_content_id("default:dry_shrub")
noisetest.c_dirt_snow		=	minetest.get_content_id("default:dirt_with_snow")
noisetest.c_snow			=	minetest.get_content_id("default:snow")

noisetest.c_tree		=	minetest.get_content_id("default:tree")
noisetest.c_apple		=	minetest.get_content_id("default:apple")
noisetest.c_leaves		=	minetest.get_content_id("noisetest:leaves")
noisetest.c_jtree		=	minetest.get_content_id("default:jungletree")
noisetest.c_jleaves		=	minetest.get_content_id("noisetest:jungleleaves")
noisetest.c_papyrus		=	minetest.get_content_id("default:papyrus")

noisetest.c_sdiamond	=	minetest.get_content_id("default:stone_with_diamond")
noisetest.c_smese		=	minetest.get_content_id("default:stone_with_mese")
noisetest.c_sgold		=	minetest.get_content_id("default:stone_with_gold")
noisetest.c_scopper		=	minetest.get_content_id("default:stone_with_copper")
noisetest.c_siron		=	minetest.get_content_id("default:stone_with_iron")
noisetest.c_scoal		=	minetest.get_content_id("default:stone_with_coal")

noisetest.c_jgrass		=	minetest.get_content_id("default:junglegrass")
for i=1,5 do
	noisetest["c_grass"..i] = minetest.get_content_id("default:grass_"..i)
end
noisetest.c_danwhi		=	minetest.get_content_id("flowers:dandelion_white")
noisetest.c_danyel		=	minetest.get_content_id("flowers:dandelion_yellow")
noisetest.c_rose		=	minetest.get_content_id("flowers:rose")
noisetest.c_tulip		=	minetest.get_content_id("flowers:tulip")
noisetest.c_geranium	=	minetest.get_content_id("flowers:geranium")
noisetest.c_viola		=	minetest.get_content_id("flowers:viola")