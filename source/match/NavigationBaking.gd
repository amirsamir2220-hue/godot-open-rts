# Navigation mesh baking that never reads mesh data back from the GPU.
#
# NavigationRegion3D.bake_navigation_mesh() parses visual meshes through the RenderingServer,
# which stalls the main thread and hangs indefinitely on newer Godot versions (4.7) once the
# game is already rendering (e.g. starting a match from the loading screen). Here, collision
# shapes are parsed as usual (they live in CPU memory) and primitive meshes in the source group
# (map terrain, air reference plane) are added from their CPU-generated arrays instead.
# The result is the same navigation mesh as before.

static func collect_source_geometry(navigation_mesh, root_node):
	var source_geometry = NavigationMeshSourceGeometryData3D.new()
	if (
		navigation_mesh.geometry_parsed_geometry_type
		!= NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
	):
		var parsed_geometry_type = navigation_mesh.geometry_parsed_geometry_type
		navigation_mesh.geometry_parsed_geometry_type = (
			NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		)
		NavigationServer3D.parse_source_geometry_data(navigation_mesh, source_geometry, root_node)
		navigation_mesh.geometry_parsed_geometry_type = parsed_geometry_type
	for node in root_node.get_tree().get_nodes_in_group(navigation_mesh.geometry_source_group_name):
		if node is MeshInstance3D and node.mesh is PrimitiveMesh:
			source_geometry.add_mesh_array(node.mesh.get_mesh_arrays(), node.global_transform)
	return source_geometry


## Bakes synchronously and updates the region.
static func bake(region):
	var navigation_mesh = region.navigation_mesh
	var source_geometry = collect_source_geometry(navigation_mesh, region)
	NavigationServer3D.bake_from_source_geometry_data(navigation_mesh, source_geometry)
	NavigationServer3D.region_set_navigation_mesh(region.get_region_rid(), navigation_mesh)


## Bakes on a background thread; `on_finished` is called on the main thread afterwards.
static func bake_async(region, on_finished):
	var navigation_mesh = region.navigation_mesh
	var source_geometry = collect_source_geometry(navigation_mesh, region)
	NavigationServer3D.bake_from_source_geometry_data_async(
		navigation_mesh,
		source_geometry,
		func():
			if is_instance_valid(region) and region.is_inside_tree():
				NavigationServer3D.region_set_navigation_mesh(
					region.get_region_rid(), navigation_mesh
				)
			on_finished.call()
	)
