class Unit:
	const Movement = preload("res://source/match/utils/UnitMovementUtils.gd")
	const Placement = preload("res://source/match/utils/UnitPlacementUtils.gd")


const Resources = preload("res://source/match/utils/ResourceUtils.gd")


static func traverse_node_tree_and_replace_materials_matching_albedo(
	starting_node, albedo_to_match, epsilon, material_to_set
):
	if starting_node == null:
		return
	for child in starting_node.find_children("*"):
		if not "mesh" in child:
			continue
		for surface_id in range(child.mesh.get_surface_count()):
			var surface_material = child.mesh.get("surface_{0}/material".format([surface_id]))
			if (
				surface_material != null
				and Utils.Colour.is_equal_approx_with_epsilon(
					surface_material.albedo_color, albedo_to_match, epsilon
				)
			):
				child.set("surface_material_override/{0}".format([surface_id]), material_to_set)


## Waits until the navigation map has been synchronized at least once. Queries made before that
## return Vector3.ZERO (and Godot 4.4+ reports an error), which would teleport units to (0, 0).
static func wait_for_navigation_map(node, navigation_map_rid):
	await node.get_tree().process_frame
	while NavigationServer3D.map_get_iteration_id(navigation_map_rid) == 0:
		await node.get_tree().physics_frame


static func select_units(units_to_select):
	if not units_to_select.empty() and not Input.is_action_pressed("shift_selecting"):
		MatchSignals.deselect_all_units.emit()
	for unit in units_to_select.iterate():
		var selection = unit.find_child("Selection")
		if selection != null:
			selection.select()
