# battle/event_node.gd
class_name EventNode
#An event node contains information about something that changed in the game state, or a triggered event.

# These could insteab be subclasses to make sure that the required data is present.
enum EventType {
	ABILITY_START,
	ABILITY_END,
	TILE_LEAVE,
	TILE_ENTER,
	ATTACK_BEGIN,
	ATTACK_END,
	ATTACK_HIT,
	ATTACK_MISS,
	UNITS_HP_CHANGE,
	UNITS_STATUS_CHANGE,
	UNITS_DOWNED
}

var event_type: EventType
var cause_ability: UnitAbility
var cause_action: ActionNode

#var instigator: Unit can get from the event tree / context
var source_unit: Unit # the source of the event, not necessarily the instigator

# For attacks, unit status changes, ability start and end
var target_units: Array[Unit] = []

#Enter / leave tile
var from_tile : Vector3i
var to_tile : Vector3i

func _init(_event_type:EventType) -> void:
	event_type = _event_type
	
func from_action(action:ActionNode) -> EventNode:
	cause_action = action
	return self
