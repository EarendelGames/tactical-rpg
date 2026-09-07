class_name Timeline

# Base interface for timeline management. A Timeline decides which unit acts next,
# and when a round ends (which is when environmental effects trigger, e.g. fire
# spreading through grass, units being pushed by water flow).
#
# Implementations:
#   TimelineFluid  - continuous relative-speed scaling; outnumbered sides move
#                    faster through the loop, so a unit can act more than once
#                    per round.
#   TimelineDirect - simple round robin, one action per unit per round.
#                    "Outnumbered" advantages become discrete abilities/stat
#                    changes elsewhere instead of extra turns.

func register_side(side: BattleSide) -> void:
	push_error("Timeline.register_side() is abstract - override in subclass")

func on_combat_start(battle: Battle) -> void:
	pass # optional hook - not every implementation needs to do anything here

func advance(battle: Battle) -> TimelineEvent:
	push_error("Timeline.advance() is abstract - override in subclass")
	return null

func notify_unit_removed(battle: Battle, unit: Unit) -> void:
	push_error("Timeline.notify_unit_removed() is abstract - override in subclass")

func get_predicted_timeline(battle: Battle) -> Array[TimelineEvent]:
	push_error("Timeline.get_predicted_timeline() is abstract - override in subclass")
	return []
