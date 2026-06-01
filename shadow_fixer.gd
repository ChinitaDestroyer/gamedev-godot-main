@tool
extends EditorScript

func _run() -> void:
	# Get the currently open map scene
	var scene = get_editor_interface().get_edited_scene_root()
	var tilemap = scene.get_node("Walls")
	
	if not tilemap or not tilemap.tile_set:
		print("Error: Please open first_round_map.tscn in the 2D view first!")
		return
		
	var tileset: TileSet = tilemap.tile_set
	
	# 1. Add the Shadow (Occlusion) Layer to the TileSet
	if tileset.get_occlusion_layers_count() == 0:
		tileset.add_occlusion_layer(0)
		tileset.set_occlusion_layer_light_mask(0, 1)
		print("Added Occlusion Layer 0.")
		
	# Grab the sprite sheet
	var source = tileset.get_source(0) as TileSetAtlasSource
	var modified_count = 0
	
	# 2. Loop through every tile and copy collisions to shadows!
	for i in range(source.get_tiles_count()):
		var coords = source.get_tile_id(i)
		var tile_data = source.get_tile_data(coords, 0)
		
		# If the tile is a solid wall (has a collision shape)...
		if tile_data.get_collision_polygons_count(0) > 0:
			var coll_points = tile_data.get_collision_polygon_points(0, 0)
			
			# ...create a perfectly matching shadow block for it!
			var occluder = OccluderPolygon2D.new()
			occluder.polygon = coll_points
			
			tile_data.set_occluder(0, occluder)
			modified_count += 1
			
	print("SUCCESS! Generated perfect shadows for ", modified_count, " wall tiles.")
	print("IMPORTANT: Click on your 2D map and press Ctrl+S to save the changes!")
