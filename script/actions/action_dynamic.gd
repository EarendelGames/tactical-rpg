class_name ActionDynamic
extends ActionNode

#The action node contains information about what to do to the game state.
# Some actions will need to save data from when they are triggered, others will need to gather data when they are executed, it's case-by-case.

var _execute_function: Callable
var _saved_data:Dictionary = {} # any daved data for later use.

func _init(owning_ability:UnitAbility) -> void:
	_owning_ability = owning_ability

func with_function(execute_function:Callable = Callable(), saved_data:Dictionary = {}) -> ActionDynamic:
	_execute_function = execute_function
	_saved_data = saved_data
	return self

# Execute the current action.
func execute(sequence_tree:SequenceTree) -> bool:
	_execute_function.call(sequence_tree, _saved_data)
	return true
