# initiative.gd
class_name Timeline

# This was intended to allow a smoother transition of the Banner Saga player turns system with concepts like rounds. 
# Now the plan is instead to have a more traditional 1 unit turn per round.
# Specific units may be able to take multiple turns if outnumbered,
# but that would be a special ability, not a default aspect of the rounds system. 

const MIN_PREDICTED_ACTIONS: int = 10

var world_time: float = 0.0
var loop_positions: Dictionary  # side_enum -> float
var waiting_units: Dictionary   # unit_id -> bool

func _init() -> void:
	loop_positions = {}
	waiting_units = {}

func duplicate() -> Timeline:
	var clone := Timeline.new()
	clone.world_time = world_time
	clone.loop_positions = loop_positions.duplicate()
	clone.waiting_units = waiting_units.duplicate()
	return clone

func register_side(side:BattleSide) -> void:
	loop_positions[side.side_enum] = 0.0
	for u in side.units:
		waiting_units[u.unit_id] = false



# ---------------------------------------------------------------------------
# Side speeds
# ---------------------------------------------------------------------------

static func get_side_speeds(battle: Battle, timeline: Timeline) -> Dictionary:
	var side_speeds: Dictionary = {}
	var side_participating_units: Dictionary = {}
	var max_side_units: int = 0

	for side_enum: BattleSide.Side in battle.battle_sides:
		if side_enum == BattleSide.Side.NEUTRAL:
			side_participating_units[side_enum] = 0 #Neutral units don't contribute to max.
		else:
			side_participating_units[side_enum] = get_participating_units(battle.battle_sides[side_enum], timeline)
		max_side_units = max(max_side_units, side_participating_units[side_enum])

	for side_enum: BattleSide.Side in battle.battle_sides:
		if side_enum == BattleSide.Side.NEUTRAL:
			side_speeds[side_enum] = 1.0 # Neutral are always speed 1
		else: 
			side_speeds[side_enum] = pow(float(max_side_units) / float(side_participating_units[side_enum]), 0.5)

	return side_speeds

# ---------------------------------------------------------------------------
# Unit loop positions
# ---------------------------------------------------------------------------

static func get_unit_loop_position(unit_index: int, side_size: int) -> float:
	return (float(unit_index) + 0.5) / float(side_size)

# ---------------------------------------------------------------------------
# Participating units (for speed calculation), excludes waiting
# ---------------------------------------------------------------------------

static func get_participating_units(side: BattleSide, timeline: Timeline) -> int:
	var participating_units: int = 0;
	for unit in side.units:
		if not timeline.waiting_units[unit.unit_id]:
			participating_units += 1
	return participating_units

# ---------------------------------------------------------------------------
# Core timeline advancement
# ---------------------------------------------------------------------------

static func _advance_timeline(battle: Battle, timeline: Timeline) -> TimelineEvent:
	var side_speeds: Dictionary = get_side_speeds(battle, timeline)

	var best_world_time: float = INF
	var best_side_enum: BattleSide.Side = BattleSide.Side.NEUTRAL
	var best_unit: Unit

	for side_enum: BattleSide.Side in battle.battle_sides:
		var side: BattleSide = battle.battle_sides[side_enum]
		if side.units.is_empty():
			continue

		var side_speed: float = side_speeds[side_enum]
		var loop_pos: float = timeline.loop_positions[side_enum]
		var side_size: int = side.units.size()

		for i: int in range(side_size):
			var unit_pos: float = get_unit_loop_position(i, side_size)
			var side_loop_dist: float = fmod(unit_pos - loop_pos + 1.0, 1.0)
			if is_zero_approx(side_loop_dist):
				side_loop_dist = 1.0
			var arrival: float = timeline.world_time + side_loop_dist / side_speed
			if arrival < best_world_time:
				best_world_time = arrival
				best_side_enum = side_enum
				best_unit = side.units[i]

	# Check round boundary before next unit action
	var next_round_time: float = ceil(timeline.world_time + 1e-4)
	if next_round_time <= best_world_time and not is_equal_approx(next_round_time, timeline.world_time):
		timeline.world_time = next_round_time
		return TimelineEvent.make_round_end(next_round_time)

	# Advance winning side loop_pos
	var loop_dist: float = (best_world_time - timeline.world_time) * side_speeds[best_side_enum]
	timeline.loop_positions[best_side_enum] = fmod(
		timeline.loop_positions[best_side_enum] + loop_dist, 1.0
	)
	timeline.world_time = best_world_time

	# Clear waiting flag when the unit's turn arrives
	if best_unit:
		timeline.waiting_units[best_unit.unit_id] = false

	return TimelineEvent.make_action(
		best_unit,
		best_side_enum,
		best_world_time
	)

# ---------------------------------------------------------------------------
# Public advancement (mutates real battle timeline)
# ---------------------------------------------------------------------------

static func advance_battle(battle: Battle) -> TimelineEvent:
	return _advance_timeline(battle, battle.timeline)

# ---------------------------------------------------------------------------
# Predicted timeline (stateless, does not mutate battle)
# ---------------------------------------------------------------------------

static func get_predicted_timeline(battle: Battle) -> Array[TimelineEvent]:
	var prediction_timeline: Timeline = battle.timeline.duplicate()
	var events: Array[TimelineEvent] = []
	var action_count: int = 0
	var target_world_time: float = ceil(battle.timeline.world_time + 1e-4) + 1.0

	while action_count < MIN_PREDICTED_ACTIONS or prediction_timeline.world_time < target_world_time:
		var event: TimelineEvent = _advance_timeline(battle, prediction_timeline)
		events.append(event)
		if not event.is_round_end:
			action_count += 1
		if events.size() > 200:
			break

	return events

# ---------------------------------------------------------------------------
# Unit removal
# ---------------------------------------------------------------------------

static func remove_unit(unit: Unit) -> void:
	var battle: Battle = unit.battle
	var side: BattleSide = unit.side
	var side_enum: String = side.name
	var timeline: Timeline = battle.timeline

	var unit_index: int = side.units.find(unit)
	if unit_index == -1:
		push_error("Initiative.remove_unit: unit not found in side")
		return
		
	timeline.waiting_units.erase(unit.unit_id)

	var side_size: int = side.units.size()
	var unit_pos: float = get_unit_loop_position(unit_index, side_size)
	var loop_pos: float = timeline.loop_positions[side_enum]

	var loop_distance_to_unit: float = fmod(unit_pos - loop_pos + 1.0, 1.0)
	var was_acting: bool = is_zero_approx(loop_distance_to_unit) \
		or loop_distance_to_unit > 1.0 - 1e-4

	var predecessor_index: int = (unit_index - 1 + side_size) % side_size
	var successor_index: int = (unit_index + 1) % side_size

	side.units.remove_at(unit_index)
	timeline.waiting_units[side_enum].remove_at(unit_index)
	var new_size: int = side.units.size()

	if new_size == 0:
		timeline.loop_positions[side_enum] = 0.0
		return

	if was_acting:
		var predecessor_new_index: int = predecessor_index \
			if predecessor_index < unit_index \
			else predecessor_index - 1
		predecessor_new_index = predecessor_new_index % new_size
		timeline.loop_positions[side_enum] = get_unit_loop_position(
			predecessor_new_index, new_size
		)
	else:
		var predecessor_pos: float = get_unit_loop_position(predecessor_index, side_size)
		var successor_pos: float = get_unit_loop_position(successor_index, side_size)

		var old_interval: float = fmod(successor_pos - predecessor_pos + 1.0, 1.0)
		var progress_in_interval: float = 0.0
		if old_interval > 0.0:
			var raw: float = fmod(loop_pos - predecessor_pos + 1.0, 1.0)
			progress_in_interval = clampf(raw / old_interval, 0.0, 1.0)

		var predecessor_new_index: int = predecessor_index \
			if predecessor_index < unit_index \
			else predecessor_index - 1
		var successor_new_index: int = successor_index - 1 \
			if successor_index > unit_index \
			else successor_index
		predecessor_new_index = predecessor_new_index % new_size
		successor_new_index = successor_new_index % new_size

		var predecessor_new_pos: float = get_unit_loop_position(predecessor_new_index, new_size)
		var successor_new_pos: float = get_unit_loop_position(successor_new_index, new_size)

		var new_interval: float = fmod(successor_new_pos - predecessor_new_pos + 1.0, 1.0)
		timeline.loop_positions[side_enum] = fmod(
			predecessor_new_pos + progress_in_interval * new_interval, 1.0
		)
