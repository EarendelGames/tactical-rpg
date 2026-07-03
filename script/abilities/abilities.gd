class_name Abilities

static var basic_move := AbilityBase.new(
	"basic_move", "Move",
	"Move to a new tile",
	[BattleEnums.Tag.MOVEMENT]
) \
.input_cell(5.0) \
.with_execute(func(unit_ability:UnitAbility, input:Dictionary) -> void:
	print("AbilityBase Move")
	var start_cell := unit_ability.unit.current_cell
	var target_cell : HexCell = input.target_cell
	var battle = unit_ability.unit.battle
	var path : Array[HexCell] = battle.grid.find_path(start_cell, target_cell)
	if path.size() <= 1:
		return
	path.remove_at(0)
	var sequence_tree = SequenceTree.new(battle, unit_ability, {"to" = target_cell})
	sequence_tree.battle = battle
	battle.sequence_tree = sequence_tree
	for cell:HexCell in path:
		var action = ActionMove.new(unit_ability, unit_ability.unit, cell)
		sequence_tree.append_sequential_action(action)
)

#
#static var fireball := AbilityBase.new(
	#"fireball", "Fireball",
	#"Hurl a ball of fire at a target cell, dealing fire damage in an area.",
	#[BattleEnums.Tag.MAGIC, BattleEnums.Tag.FIRE]
#) \
#.input_cell(5.0) \
#.mana(30.0) \
#.with_execute(func(unit_ability:UnitAbility) -> void:
	#var target_cell: HexCell = tree.resolved_inputs[0][0]
	#var setup_node := EventNode.new(
		#BattleEnums.EventTiming.IMMEDIATE, func(): pass, tree.caster)
	#tree.add_root_node(setup_node)
	#tree.fire_setup_event(BattleEnums.SetupEvent.PRE_SPELLCAST, tree.caster, setup_node)
	#for cell in tree.battle.grid.get_cells_in_radius(target_cell, 1.7):
		#if cell.occupant:
			#var target: Unit = cell.occupant
			#tree.add_root_node(EventNode.new(
				#BattleEnums.EventTiming.IMMEDIATE,
				#func(): target.take_damage(30.0, BattleEnums.DamageType.FIRE, tree, null),
				#tree.caster
			#))
#)
#
#static var apply_oil := AbilityBase.new(
	#"apply_oil", "Apply Oil",
	#"Douse a target unit in oil, making them vulnerable to fire.",
	#[BattleEnums.Tag.BASIC]
#) \
#.input_unit(3.0) \
#.with_execute(func(unit_ability:UnitAbility) -> void:
	#var target_cell: HexCell = tree.resolved_inputs[0][0]
	#if not target_cell.occupant:
		#return
	#var target: Unit = target_cell.occupant
	#tree.add_root_node(EventNode.new(
		#BattleEnums.EventTiming.IMMEDIATE,
		#func(): target.apply_status("oil", 3),
		#tree.caster
	#))
#)
#
#static var preemptive_counter := AbilityBase.new(
	#"preemptive_counter", "Preemptive Counter",
	#"Strike an attacker before their attack lands.",
	#[BattleEnums.Tag.MELEE, BattleEnums.Tag.PHYSICAL]
#) \
#.uses_per_turn(false) \
#.with_trigger(func(unit: Unit, _battle: Battle) -> void:
	#unit.add_setup_trigger(
		#"preemptive_counter",
		#BattleEnums.SetupEvent.PRE_ATTACK,
		#func(tree: SequenceTree, parent_node: EventNode, source: Unit) -> void:
			#if source == unit or unit.is_dead or source.force == unit.force:
				#return
			#parent_node.add_child_node(EventNode.new(
				#BattleEnums.EventTiming.IMMEDIATE,
				#func(): source.take_damage(
					#15.0, BattleEnums.DamageType.PHYSICAL, tree, parent_node),
				#unit, true,
				#func(_n, _t): return unit.is_dead
			#)),
		#func(): return unit.is_dead
	#)
#)
#
#static var move_and_attack := AbilityBase.new(
	#"move_and_attack", "Move and Attack",
	#"When an ally takes damage, dash toward a nearby enemy and strike them.",
	#[BattleEnums.Tag.MELEE, BattleEnums.Tag.PHYSICAL]
#) \
#.uses_per_turn(false) \
#.with_trigger(func(unit: Unit, battle: Battle) -> void:
	#unit.add_trigger(
		#"move_and_attack",
		#BattleEnums.EventTiming.RESPONSE,
		#func(tree: SequenceTree, parent_node: EventNode) -> void:
			#var damaged: Unit = tree.caster
			#if damaged.force != unit.force or damaged == unit or unit.is_dead:
				#return
			#var target: Unit = null
			#for cell in battle.grid.get_neighbours(damaged.current_cell):
				#if cell.occupant and cell.occupant.force != unit.force:
					#target = cell.occupant
					#break
			#if not target:
				#return
			#parent_node.add_child_node(EventNode.new(
				#BattleEnums.EventTiming.RESPONSE,
				#func():
					#var path := battle.grid.find_path(unit.current_cell, target.current_cell)
					#if path.size() > 1:
						#unit.place_on_cell(path[path.size() - 2])
					#target.take_damage(20.0, BattleEnums.DamageType.PHYSICAL, tree, parent_node),
				#unit, true,
				#func(_n, _t): return unit.is_dead
			#)),
		#true
	#)
#)
#
#static var trap_stop_movement := AbilityBase.new(
	#"trap_stop_movement", "Movement Trap",
	#"A trap placed on a cell that stops any unit's movement when they enter it.",
	#[]
#) \
#.uses_per_turn(false)
## Note: call trap_stop_movement.register_on_cell(cell) when placing the trap.
## This cannot be done via with_trigger as it targets a cell, not a unit.
#
#func register_on_cell(cell: HexCell) -> void:
	#cell.add_movement_trigger(
		#func(tree: SequenceTree, parent_node: EventNode, moving_unit: Unit) -> void:
			#parent_node.add_child_node(EventNode.new(
				#BattleEnums.EventTiming.RESPONSE,
				#func():
					#moving_unit.movement_points = 0
					#tree.cancel_movement()
					#print("%s was stopped by a movement trap!" % moving_unit.unit_name),
				#null, false
			#))
	#)
