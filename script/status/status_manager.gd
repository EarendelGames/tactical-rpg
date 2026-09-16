# status_manager.gd
class_name StatusManager

# --- Registry ---

static var _registry: Dictionary = {}

static func register(status: StatusBase) -> StatusBase:
	if _registry.has(status.id):
		push_error("StatusBase: duplicate id '%s'" % status.id)
	_registry[status.id] = status
	return status

static func get_status(status_id: String) -> StatusBase:
	if not _registry.has(status_id):
		push_error("StatusBase: unknown id '%s'" % status_id)
	return _registry.get(status_id, null)

static func all() -> Array:
	return _registry.values()
	

# status_base.gd — additions
static func apply_status(statuses: Dictionary, id: String, magnitude: int, duration: int = -1, source: UnitAbility = null) -> void:
	return apply_status_stack(statuses, id, StatusStack.new(magnitude, duration, source))
	
static func apply_status_stack(statuses: Dictionary, id: String, incoming: StatusStack) -> void:
	var status := StatusManager.get_status(id)
	var surviving: Array[StatusStack] = [incoming]

	for opposing_id in status.opposes:
		if incoming.magnitude <= 0:
			break
		surviving = _negate_stack(statuses, opposing_id, incoming)
		if surviving.size() > 1 or incoming.magnitude <= 0:
			break   # incoming was split against itself, or fully spent — nothing left to trade further

	if not surviving.is_empty():
		if not statuses.has(id):
			statuses[id] = StatusInstance.new(id)
		for stack in surviving:
			statuses[id].add_stack(stack)

static func _prune(statuses: Dictionary, id: String) -> void:
	var instance: StatusInstance = statuses.get(id)
	if instance and instance.is_empty():
		statuses.erase(id)

static func _remove_stack(statuses: Dictionary, id: String, stack: StatusStack) -> void:
	var instance: StatusInstance = statuses.get(id)
	if not instance:
		return
	instance.remove_stack(stack)
	_prune(statuses, id)

static func _negate_stack(statuses: Dictionary, opposing_id: String, incoming: StatusStack) -> Array[StatusStack]:
	var instance: StatusInstance = statuses.get(opposing_id)
	if not instance:
		return [incoming]

	var bucket_a: Array[StatusStack] = []
	var bucket_b: Array[StatusStack] = []
	for stack in instance.stacks:
		if incoming.duration >= 0 and (stack.duration < 0 or stack.duration >= incoming.duration):
			bucket_b.append(stack)
		else:
			bucket_a.append(stack)

	bucket_b.sort_custom(func(a, b):
		if a.duration != b.duration:
			return a.duration > b.duration
		return a.magnitude < b.magnitude
	)
	for stack in bucket_b:
		if incoming.magnitude <= 0:
			break
		var trade: int = min(incoming.magnitude, stack.magnitude)
		incoming.magnitude -= trade
		stack.magnitude -= trade
		if stack.magnitude <= 0:
			_remove_stack(statuses, opposing_id, stack)

	if incoming.magnitude <= 0:
		return []

	var budget: int = incoming.magnitude * incoming.duration
	bucket_a.sort_custom(func(a, b):
		if a.duration != b.duration:
			return a.duration > b.duration
		return a.magnitude > b.magnitude
	)
	for stack in bucket_a:
		if budget <= 0:
			break
		budget = _spend_area(statuses, opposing_id, stack, budget)

	if budget > 0 and incoming.duration > 0:
		var split := _spend_area_on_incoming(incoming, budget)
		if split:
			return [incoming, split]

	return [incoming]

static func _spend_area(statuses: Dictionary, id: String, stack: StatusStack, budget: int) -> int:
	var area: int = stack.magnitude * stack.duration
	if budget >= area:
		_remove_stack(statuses, id, stack)
		return budget - area
		
	@warning_ignore("integer_division")
	var full_rows: int = budget / stack.duration
	var remainder: int = budget % stack.duration
	stack.magnitude -= full_rows
	if remainder > 0 and stack.magnitude > 0:
		stack.magnitude -= 1
		statuses[id].add_stack(StatusStack.new(1, stack.duration - remainder, stack.source))
	if stack.magnitude <= 0:
		_remove_stack(statuses, id, stack)
	return 0

static func _spend_area_on_incoming(incoming: StatusStack, budget: int) -> StatusStack:
	@warning_ignore("integer_division")
	var full_rows: int = budget / incoming.duration
	var remainder: int = budget % incoming.duration
	incoming.magnitude -= full_rows
	if remainder > 0 and incoming.magnitude > 0:
		incoming.magnitude -= 1
		return StatusStack.new(1, incoming.duration - remainder, incoming.source)
	return null
	
	
static func remove_status_stacks(statuses: Dictionary, id: String, magnitude: int) -> void:
	var instance: StatusInstance = statuses.get(id)
	if not instance:
		return

	var remaining := magnitude
	var stacks := instance.stacks.duplicate()
	stacks.sort_custom(func(a, b):
		if a.duration != b.duration:
			return a.duration > b.duration
		return a.magnitude < b.magnitude
	)

	for stack in stacks:
		if remaining <= 0:
			break
		var take: int = min(remaining, stack.magnitude)
		stack.magnitude -= take
		remaining -= take
		if stack.magnitude <= 0:
			_remove_stack(statuses, id, stack)
