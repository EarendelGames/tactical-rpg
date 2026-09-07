class_name TimelineDirect
extends Timeline

# Simple round robin: every living unit acts exactly once per round, in
# initiative order. Outnumbered bonuses live elsewhere as abilities/stat
# changes rather than extra turns.

var turn_order: Array[Unit] = []
var turn_index: int = -1

func register_side(side: BattleSide) -> void:
	for u in side.units:
		if not turn_order.has(u):
			turn_order.append(u)

func on_combat_start(battle: Battle) -> void:
	turn_order = battle.current_units.duplicate()
	turn_order.sort_custom(func(a: Unit, b: Unit): return a.initiative > b.initiative)
	turn_index = -1

func advance(battle: Battle) -> TimelineEvent:
	turn_index += 1
	if turn_index >= turn_order.size():
		turn_index = -1
		return TimelineEvent.make_round_end(0.0)
	var unit := turn_order[turn_index]
	return TimelineEvent.make_action(unit, unit.side_enum, float(turn_index))

func notify_unit_removed(battle: Battle, unit: Unit) -> void:
	var removed_index := turn_order.find(unit)
	turn_order.erase(unit)
	if removed_index != -1 and removed_index <= turn_index:
		turn_index -= 1

func get_predicted_timeline(battle: Battle) -> Array[TimelineEvent]:
	var events: Array[TimelineEvent] = []
	var idx := turn_index
	for i in range(turn_order.size() * 2):
		idx += 1
		if idx >= turn_order.size():
			events.append(TimelineEvent.make_round_end(0.0))
			idx = -1
			continue
		var unit := turn_order[idx]
		events.append(TimelineEvent.make_action(unit, unit.side_enum, float(idx)))
	return events
