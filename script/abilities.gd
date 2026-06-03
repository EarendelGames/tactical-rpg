# abilities.gd
class_name AbilityBase
extends RefCounted

# --- Registry ---

static var _registry: Dictionary = {}

static func get_ability(ability_id: String) -> AbilityBase:
	return _registry.get(ability_id, null)

static func all() -> Array:
	return _registry.values()

# --- Fields ---

var id: String
var name: String
var description: String
var tags: Array[BattleEnums.Tag]
var inputs: Array[BattleEnums.AbilityInput]

var cost_mana: float = 0.0
var cost_movement: float = 0.0
var cost_health: float = 0.0
var max_uses_per_turn: int = 1
var has_max_uses_per_turn: bool = true

var _execute_fn: Callable
var _trigger_fn: Callable

# --- Init and registration ---

func _init(
	p_id: String,
	p_name: String,
	p_description: String,
	p_tags: Array[BattleEnums.Tag]
) -> void:
	id = p_id
	name = p_name
	description = p_description
	tags = p_tags
	inputs = []
	if AbilityBase._registry.has(id):
		push_error("AbilityBase: duplicate id '%s'" % id)
	AbilityBase._registry[id] = self

# --- Builder methods ---

func input_cell(input_range: float, p_min: int = 1, p_max: int = 1) -> AbilityBase:
	inputs.append(BattleEnums.AbilityInput.cell(input_range, p_min, p_max))
	return self

func input_unit(input_range: float, p_min: int = 1, p_max: int = 1) -> AbilityBase:
	inputs.append(BattleEnums.AbilityInput.unit(input_range, p_min, p_max))
	return self

func input_cell_corner(input_range: float, p_min: int = 1, p_max: int = 1) -> AbilityBase:
	inputs.append(BattleEnums.AbilityInput.cell_corner(input_range, p_min, p_max))
	return self

func input_direction(input_range: float) -> AbilityBase:
	inputs.append(BattleEnums.AbilityInput.direction(input_range))
	return self

func mana(amount: float) -> AbilityBase:
	cost_mana = amount
	return self

func movement(amount: float) -> AbilityBase:
	cost_movement = amount
	return self

func health(amount: float) -> AbilityBase:
	cost_health = amount
	return self

func uses_per_turn(value: Variant) -> AbilityBase:
	if value == false:
		has_max_uses_per_turn = false
		max_uses_per_turn = 0
	else:
		has_max_uses_per_turn = true
		max_uses_per_turn = value
	return self

func with_execute(fn: Callable) -> AbilityBase:
	_execute_fn = fn
	return self

func with_trigger(fn: Callable) -> AbilityBase:
	_trigger_fn = fn
	return self

# --- Runtime ---

func is_basic() -> bool:
	return BattleEnums.Tag.BASIC in tags

func execute(tree: EventTree) -> void:
	if _execute_fn.is_valid():
		_execute_fn.call(tree)

func register_trigger(unit: Unit, battle: Battle) -> void:
	if _trigger_fn.is_valid():
		_trigger_fn.call(unit, battle)

# --- Definitions ---

static var fireball := AbilityBase.new(
	"fireball", "Fireball",
	"Hurl a ball of fire at a target cell, dealing fire damage in an area.",
	[BattleEnums.Tag.MAGIC, BattleEnums.Tag.FIRE]
) \
.input_cell(5.0) \
.mana(30.0) \
.with_execute(func(tree: EventTree) -> void:
	var target_cell: HexCell = tree.resolved_inputs[0][0]
	var setup_node := EventNode.new(
		BattleEnums.EventTiming.IMMEDIATE, func(): pass, tree.caster)
	tree.add_root_node(setup_node)
	tree.fire_setup_event(BattleEnums.SetupEvent.PRE_SPELLCAST, tree.caster, setup_node)
	for cell in tree.battle.grid.get_cells_in_radius(target_cell, 1.7):
		if cell.occupant:
			var target: Unit = cell.occupant
			tree.add_root_node(EventNode.new(
				BattleEnums.EventTiming.IMMEDIATE,
				func(): target.take_damage(30.0, BattleEnums.DamageType.FIRE, tree, null),
				tree.caster
			))
)

static var apply_oil := AbilityBase.new(
	"apply_oil", "Apply Oil",
	"Douse a target unit in oil, making them vulnerable to fire.",
	[BattleEnums.Tag.BASIC]
) \
.input_unit(3.0) \
.with_execute(func(tree: EventTree) -> void:
	var target_cell: HexCell = tree.resolved_inputs[0][0]
	if not target_cell.occupant:
		return
	var target: Unit = target_cell.occupant
	tree.add_root_node(EventNode.new(
		BattleEnums.EventTiming.IMMEDIATE,
		func(): target.apply_status("oil", 3),
		tree.caster
	))
)

static var preemptive_counter := AbilityBase.new(
	"preemptive_counter", "Preemptive Counter",
	"Strike an attacker before their attack lands.",
	[BattleEnums.Tag.MELEE, BattleEnums.Tag.PHYSICAL]
) \
.uses_per_turn(false) \
.with_trigger(func(unit: Unit, _battle: Battle) -> void:
	unit.add_setup_trigger(
		"preemptive_counter",
		BattleEnums.SetupEvent.PRE_ATTACK,
		func(tree: EventTree, parent_node: EventNode, source: Unit) -> void:
			if source == unit or unit.is_dead or source.force == unit.force:
				return
			parent_node.add_child_node(EventNode.new(
				BattleEnums.EventTiming.IMMEDIATE,
				func(): source.take_damage(
					15.0, BattleEnums.DamageType.PHYSICAL, tree, parent_node),
				unit, true,
				func(_n, _t): return unit.is_dead
			)),
		func(): return unit.is_dead
	)
)

static var move_and_attack := AbilityBase.new(
	"move_and_attack", "Move and Attack",
	"When an ally takes damage, dash toward a nearby enemy and strike them.",
	[BattleEnums.Tag.MELEE, BattleEnums.Tag.PHYSICAL]
) \
.uses_per_turn(false) \
.with_trigger(func(unit: Unit, battle: Battle) -> void:
	unit.add_trigger(
		"move_and_attack",
		BattleEnums.EventTiming.RESPONSE,
		func(tree: EventTree, parent_node: EventNode) -> void:
			var damaged: Unit = tree.caster
			if damaged.force != unit.force or damaged == unit or unit.is_dead:
				return
			var target: Unit = null
			for cell in battle.grid.get_neighbours(damaged.current_cell):
				if cell.occupant and cell.occupant.force != unit.force:
					target = cell.occupant
					break
			if not target:
				return
			parent_node.add_child_node(EventNode.new(
				BattleEnums.EventTiming.RESPONSE,
				func():
					var path := battle.grid.find_path(unit.current_cell, target.current_cell)
					if path.size() > 1:
						unit.place_on_cell(path[path.size() - 2])
					target.take_damage(20.0, BattleEnums.DamageType.PHYSICAL, tree, parent_node),
				unit, true,
				func(_n, _t): return unit.is_dead
			)),
		true
	)
)

static var trap_stop_movement := AbilityBase.new(
	"trap_stop_movement", "Movement Trap",
	"A trap placed on a cell that stops any unit's movement when they enter it.",
	[]
) \
.uses_per_turn(false)
# Note: call trap_stop_movement.register_on_cell(cell) when placing the trap.
# This cannot be done via with_trigger as it targets a cell, not a unit.

func register_on_cell(cell: HexCell) -> void:
	cell.add_movement_trigger(
		func(tree: EventTree, parent_node: EventNode, moving_unit: Unit) -> void:
			parent_node.add_child_node(EventNode.new(
				BattleEnums.EventTiming.RESPONSE,
				func():
					moving_unit.movement_points = 0
					tree.cancel_movement()
					print("%s was stopped by a movement trap!" % moving_unit.unit_name),
				null, false
			))
	)
