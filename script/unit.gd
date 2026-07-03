# unit.gd
@tool
class_name Unit
extends Node3D

enum Force { PLAYER, ENEMY, NEUTRAL }

@export var unit_name: String = "Unit"
@export var initiative_modifier: float = 0.0
@export var force: Force = Force.ENEMY

# Base stats
@export var max_health: float = 100.0
@export var max_mana: float = 50.0
@export var max_movement_points: float = 4
@export var movement_range: float = 3

# Runtime stats
var health: float = 0.0
var mana: float = 0.0
var movement_points: float = 0
var initiative: float = 0.0
var current_cell: HexCell = null
var is_dead: bool = false

var move_ability: UnitAbility
var abilities: Array[UnitAbility] = []
var statuses: Array = []           # Array of StatusBase.Instance
var ability_slots: Array[UnitAbility] = []

# Triggers: { id, timing, callable, interruptible, cancel_if }
var _triggers: Array = []
# Setup triggers: { id, setup_event, callable, cancel_if }
var _setup_triggers: Array = []

var battle: Battle = null

func _ready() -> void:
	if not Engine.is_editor_hint():
		health = max_health
		mana = max_mana
		movement_points = max_movement_points

func initialise(_battle: Battle) -> void:
	battle = battle
	move_ability = Abilities.basic_move.as_unit_ability(self)

func roll_initiative() -> void:
	initiative = randf_range(0.0, 10.0) + initiative_modifier

func get_int_pos() -> Vector3i:
	if current_cell:
		return current_cell.int_pos
	return Vector3i.ZERO

# --- Turn start ---

func turn_start(battle: Battle) -> void:
	_tick_statuses(battle)
	if is_dead:
		return
	movement_points = max_movement_points
	_reset_ability_uses()
	_roll_ability_slots()

func _reset_ability_uses() -> void:
	if move_ability: move_ability.reset_uses()
	for unit_ability : UnitAbility in abilities:
		unit_ability.reset_uses()

func _tick_statuses(battle: Battle) -> void:
	var snapshot := statuses.duplicate()
	for instance in snapshot:
		var status := StatusBase.get_status(instance.status_id)
		if status:
			status.on_turn_start(self, instance, battle)
		if is_dead:
			return

func _roll_ability_slots() -> void:
	ability_slots.clear()
	var available := abilities.duplicate()
	var basics := available.filter(func(i: UnitAbility): return i.ability.is_basic())
	if basics.size() > 0:
		var chosen: UnitAbility = basics[randi() % basics.size()]
		ability_slots.append(chosen)
		available.erase(chosen)
	available.shuffle()
	for instance in available:
		if ability_slots.size() >= 10:
			break
		ability_slots.append(instance)

# --- Trigger registration ---

func add_trigger(
	id: String,
	timing: BattleEnums.EventTiming,
	callable: Callable,
	interruptible: bool = false,
	cancel_if: Callable = Callable()
) -> void:
	_triggers.append({
		"id": id,
		"timing": timing,
		"callable": callable,
		"interruptible": interruptible,
		"cancel_if": cancel_if,
	})

func add_setup_trigger(
	id: String,
	setup_event: BattleEnums.SetupEvent,
	callable: Callable,
	cancel_if: Callable = Callable()
) -> void:
	_setup_triggers.append({
		"id": id,
		"setup_event": setup_event,
		"callable": callable,
		"cancel_if": cancel_if,
	})

func remove_trigger(id: String) -> void:
	var i := _triggers.size() - 1
	while i >= 0:
		if _triggers[i]["id"] == id:
			_triggers.remove_at(i)
		i -= 1
	i = _setup_triggers.size() - 1
	while i >= 0:
		if _setup_triggers[i]["id"] == id:
			_setup_triggers.remove_at(i)
		i -= 1

func get_triggers_for_timing(timing: BattleEnums.EventTiming) -> Array:
	return _triggers.filter(func(t): return t["timing"] == timing)

func get_triggers_for_setup_event(event: BattleEnums.SetupEvent) -> Array:
	return _setup_triggers.filter(func(t): return t["setup_event"] == event)

func register_ability_triggers(battle: Battle) -> void:
	for instance in abilities:
		instance.ability.register_trigger(self, battle)

# --- Status management ---

func get_status(id: String) -> StatusBase.Instance:
	for instance in statuses:
		if instance.status_id == id:
			return instance
	return null

func has_status(id: String) -> bool:
	return get_status(id) != null

func apply_status(id: String, stacks: int, data: Dictionary = {}) -> void:
	var existing := get_status(id)
	if existing:
		existing.stacks += stacks
	else:
		statuses.append(StatusBase.Instance.new(id, stacks, data))

func remove_status(id: String) -> void:
	var i := statuses.size() - 1
	while i >= 0:
		if statuses[i].status_id == id:
			statuses.remove_at(i)
			return
		i -= 1

# --- Damage and death ---

func take_damage(
	amount: float,
	type: BattleEnums.DamageType,
	tree: SequenceTree,
	parent_node: EventNode
) -> void:

	health -= amount
	print("%s took %.1f %s damage, %.1f health remaining" % [
		unit_name, amount, BattleEnums.DamageType.keys()[type], health
	])

	if health <= 0.0:
		_die(tree, parent_node)

func heal(amount: float) -> void:
	health = minf(health + amount, max_health)

func _die(_tree: SequenceTree, _parent_node: EventNode) -> void:
	is_dead = true
	if current_cell:
		current_cell.occupant = null
		current_cell = null
	print("%s died" % unit_name)
