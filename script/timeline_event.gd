class_name TimelineEvent

var unit: Unit
var side_name: String
var world_time: float
var is_round_end: bool

static func make_action(
	p_unit: Unit,
	p_side_name: String,
	p_world_time: float
) -> TimelineEvent:
	var e := TimelineEvent.new()
	e.unit = p_unit
	e.side_name = p_side_name
	e.world_time = p_world_time
	e.is_round_end = false
	return e

static func make_round_end(p_world_time: float) -> TimelineEvent:
	var e := TimelineEvent.new()
	e.unit = null
	e.side_name = ""
	e.world_time = p_world_time
	e.is_round_end = true
	return e
