extends Area2D

@export var roulette_scene_path: String = "res://minigames/roulette/scenes/roulette.tscn"

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
			_enter_roulette_minigame()

func _enter_roulette_minigame() -> void:
	_do_enter_with_fade()

func _do_enter_with_fade() -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	var coins: int = gm.gold if gm else 0
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	var scene = load(roulette_scene_path)
	var instance = scene.instantiate()
	if instance.get("initial_coins") != null:
		instance.initial_coins = coins
	elif "initial_coins" in instance:
		instance.set("initial_coins", coins)
	get_tree().root.add_child(instance)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if SceneTransition:
		SceneTransition.fade_in(0.3)
