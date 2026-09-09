class_name Battle
extends Node3D

@onready var grid: GridHandler = $GridHandler
@onready var battle_ui: BattleUI = $"BattleUI"

var units: Array[Unit] = []          # Every unit that has ever existed in this battle. Append-only; index == unit_id.
var current_units: Array[Unit] = []  # Units currently alive and present on the map.
var current_unit: Unit = null        # Direct reference to whichever unit's turn it is.
var selected_unit: Unit = null
var sequence_tree: SequenceTree = null
var sequence_timer: float = 0
var battle_sides: Dictionary = {}    # BattleSide.Side -> BattleSide
var timeline: Timeline
var input_consumer: UnitAbility = null

func register_unit(unit: Unit) -> void:
	unit.battle = self
	unit.unit_id = units.size()
	units.append(unit)
	current_units.append(unit)
	if not battle_sides.has(unit.side_enum):
		battle_sides[unit.side_enum] = BattleSide.new(unit.side_enum)
	battle_sides[unit.side_enum].units.append(unit)

func remove_unit_from_play(unit: Unit) -> void:
	current_units.erase(unit)
	if unit.current_cell:
		unit.current_cell.occupant = null
		unit.current_cell = null
	if timeline:
		timeline.notify_unit_removed(self, unit)

func _ready() -> void:
	print("Battle ready")
	grid.battle = self
	battle_ui.battle = self
	timeline = TimelineDirect.new() # swap TimelineDirect and TimelineFluid to switch systems
	get_viewport().physics_object_picking = true
	for unit: Unit in $Units.get_children():
		register_unit(unit)
	for side_enum in battle_sides:
		timeline.register_side(battle_sides[side_enum])
	start_combat()

func start_combat() -> void:
	print("Battle start_combat")
	for unit in current_units:
		unit.setup_abilities()
		unit.roll_initiative()
	timeline.on_combat_start(self)
	grid.rebuild_pos_lookup()
	_assign_units_to_cells()
	for unit in current_units:
		unit.register_ability_triggers()
	_advance_to_next_turn()

func _advance_to_next_turn() -> void:
	var event: TimelineEvent = timeline.advance(self)
	while event.is_round_end or event.unit.is_dead:
		if event.is_round_end:
			_on_round_end()
		event = timeline.advance(self)
	current_unit = event.unit
	print("Turn: %s (initiative %.2f)" % [current_unit.unit_name, current_unit.initiative])
	current_unit.turn_start()
	current_unit.move_ability.prep_for_input()

func _on_round_end() -> void:
	pass # TODO: environmental effects - fire spread, water flow, etc.

func _process(delta: float) -> void:
	if not sequence_tree: return
	sequence_timer += delta
	if sequence_timer > 0.0:
		sequence_timer = 0.0
		print("Battle _process")
		if not sequence_tree.process_next_action():
			sequence_tree = null
			var unit := get_current_unit()
			if unit and unit.movement_points > 0:
				unit.move_ability.prep_for_input()

# --- Movement ---
func place_on_cell(unit:Unit, cell: HexCell) -> void:
	var occupant = cell.occupant
	var start_cell = unit.current_cell
	unit.current_cell = cell
	unit.global_position = cell.global_position
	cell.occupant = unit
	if start_cell:
		start_cell.occupant = null
	if occupant:
		print("Swap positions")
		occupant.current_cell = start_cell
		occupant.global_position = start_cell.global_position
		start_cell.occupant = occupant

func move_to_cell(unit:Unit, cell: HexCell) -> void:
	var occupant = cell.occupant
	var start_cell = unit.current_cell
	unit.current_cell = cell
	cell.occupant = unit
	if start_cell:
		start_cell.occupant = null

	var delay := 0.3
	var from = unit.global_position
	var to = cell.global_position
	var tween:Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(unit, "global_position",to, delay).set_custom_interpolator(Easing.in_out_faint)
	tween.tween_property(unit, "rotation:y", wrapf(atan2(to.x - from.x, to.z - from.z), unit.rotation.y - PI, unit.rotation.y + PI), 0.5 * delay)

	if occupant:
		print("Swap positions")
		occupant.current_cell = start_cell
		start_cell.occupant = occupant
		from = occupant.global_position
		to = start_cell.global_position
		tween.tween_property(occupant, "global_position", to, delay).set_custom_interpolator(Easing.in_out_faint)
		tween.tween_property(occupant, "rotation:y", wrapf(atan2(to.x - from.x, to.z - from.z), occupant.rotation.y - PI, occupant.rotation.y + PI), 0.5 * delay)

	sequence_timer -= delay
	tween.play()

# --- Turn management ---

func advance_turn() -> void:
	clear_highlights()
	_advance_to_next_turn()

func clear_highlights() -> void:
	for cell:HexCell in grid.cells_array:
		cell.set_range_layer(Color(0,0,0,0))
		cell.set_effect_layer(Color(0,0,0,0))

func set_input_consumer(ua:UnitAbility) -> void:
	input_consumer = ua

func cell_clicked(cell: HexCell, pos, normal) -> void:
	selected_unit = null
	if input_consumer:
		input_consumer.cell_clicked(cell, pos, normal)
	else:
		if cell.occupant:
			selected_unit = cell.occupant
			selected_unit.show_move_range()
		print("no input consumer")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 2:
		selected_unit = null
		clear_highlights()
		input_consumer = null

# --- Setup ---

func _assign_units_to_cells() -> void:
	for unit in current_units:
		var best_cell := _find_closest_open_cell(unit.global_position)
		if best_cell:
			place_on_cell(unit, best_cell)
		else:
			push_error("No open cell found for unit: " + unit.unit_name)

func _find_closest_open_cell(world_pos: Vector3) -> HexCell:
	var best_cell: HexCell = null
	var best_dist: float = INF
	for child in grid.get_children():
		var cell := child as HexCell
		if not cell:
			continue
		if cell.occupant != null:
			continue
		var dist := world_pos.distance_squared_to(cell.global_position)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
	return best_cell

func new_sequence_tree(unit_ability:UnitAbility, inputs:Dictionary) -> SequenceTree:
	sequence_tree = SequenceTree.new(self, unit_ability, inputs)
	return sequence_tree

func get_current_unit() -> Unit:
	return current_unit
