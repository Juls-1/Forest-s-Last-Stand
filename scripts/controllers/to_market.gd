extends Area2D

@export var market_scene_path: String = "res://minigames/market/scenes/market.tscn"

var player_in_area: bool = false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E and player_in_area:
			get_viewport().set_input_as_handled()
			_enter_market()

func _enter_market() -> void:
	_do_enter_with_fade()

func _do_enter_with_fade() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	var gold_val: int = gm.gold if gm else 0
	var wood_val: int = gm.wood if gm else 0
	var stone_val: int = gm.stone if gm else 0
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	var scene = load(market_scene_path)
	var instance = scene.instantiate()
	if instance.get("initial_gold") != null:
		instance.initial_gold = gold_val
	if instance.get("initial_wood") != null:
		instance.initial_wood = wood_val
	if instance.get("initial_stone") != null:
		instance.initial_stone = stone_val
	get_tree().root.add_child(instance)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if SceneTransition:
		SceneTransition.fade_in(0.3)
