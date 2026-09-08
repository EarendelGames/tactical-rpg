class_name ActionNode

#The action node contains information about what to do to the game state.
# Some actions will need to save data from when they are triggered, others will need to gather data when they are executed, it's case-by-case.

var _owning_ability:UnitAbility

func _init(owning_ability:UnitAbility) -> void:
	_owning_ability = owning_ability
	
# Execute the current action.
func execute(_sequence_tree:SequenceTree) -> bool:
	print("ActionNode execute_function")
	return true
