class_name BattleUI 
extends Control

@onready var end_turn_button: Button = %EndTurnButton
@onready var move_button: Button = %MoveAction
@onready var main_action_button: Button = %MainAction

@onready var movement: Button = %Movement
@onready var health: Button = %Health

var battle:Battle

func _ready() -> void:
	end_turn_button.pressed.connect(_on_end_turn)
	move_button.pressed.connect(_on_move_button)
	main_action_button.pressed.connect(_on_main_button)

func _process(_delta: float) -> void:
	update_ui()

func update_ui() -> void:
	var unit : Unit = battle.get_current_unit()
	if not unit:
		$BL.visible = false
		return
	
	$BL.visible = true
	movement.text = "Movement: %.0f" % [unit.movement_points]
	health.text = "Health: %.0f" % [unit.health]
	
	

func _on_end_turn() -> void:
	battle.advance_turn()
	
func _on_move_button() -> void:
	var unit : Unit = battle.get_current_unit()
	unit.move_ability.prep_for_input()

func _on_main_button() -> void:
	var unit : Unit = battle.get_current_unit()
	unit.abilities[0].prep_for_input()

func _input(event):
	if event.is_action_pressed("end_turn"):
		battle.advance_turn()
