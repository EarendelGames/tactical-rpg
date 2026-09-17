# effect_move.gd
class_name EffectMove
extends AbilityEffect

var consume_movement: bool = true

func with_consume_movement(p_consume_movement: bool) -> EffectMove:
	consume_movement = p_consume_movement
	return self

func apply_to_cell(unit_ability: UnitAbility, cell: HexCell, tree: SequenceTree, node: ActionNode) -> bool:
	print("move", unit_ability.unit.current_cell.int_pos, cell.int_pos)
	unit_ability.unit.battle.move_to_cell(unit_ability.unit, cell)
	if consume_movement:
		unit_ability.unit.movement_points -= 1
		print("-1 movement")
	return true
