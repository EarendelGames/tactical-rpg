class_name BattleUI
extends Control

@onready var end_turn_button: Button = %EndTurnButton
@onready var actions_container: HBoxContainer = %ActionsContainer

@onready var movement: Button = %Movement
@onready var health: Button = %Health

var battle: Battle
var _last_unit: Unit = null
var _action_buttons: Dictionary = {}   # UnitAbility -> Button

func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn)

func update_ui() -> void:
	var unit: Unit = battle.get_current_unit()
	if not unit:
		$BL.visible = false
		return

	$BL.visible = true
	movement.text = "Movement: %.0f" % [unit.movement_points]
	health.text = "Health: %.0f" % [unit.health]

	if unit != _last_unit:
		_last_unit = unit
		_rebuild_action_buttons(unit)

	_update_action_buttons()

func _rebuild_action_buttons(unit: Unit) -> void:
	for child in actions_container.get_children():
		child.queue_free()
	_action_buttons.clear()

	_add_action_button(unit.move_ability)
	for unit_ability: UnitAbility in unit.abilities:
		_add_action_button(unit_ability)

func _add_action_button(unit_ability: UnitAbility) -> void:
	var button := Button.new()
	button.text = unit_ability.ability.name
	button.toggle_mode = true
	button.pressed.connect(unit_ability.prep_for_input)
	actions_container.add_child(button)
	_action_buttons[unit_ability] = button

func _update_action_buttons() -> void:
	for unit_ability: UnitAbility in _action_buttons:
		var button: Button = _action_buttons[unit_ability]
		button.disabled = not unit_ability.can_use()
		button.button_pressed = battle.input_consumer == unit_ability

func _on_end_turn() -> void:
	battle.advance_turn()

func _input(event):
	if event.is_action_pressed("end_turn"):
		battle.advance_turn()
