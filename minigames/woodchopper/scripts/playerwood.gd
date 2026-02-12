extends Node2D

const Branch = WChData.BranchDirection
const LEFT_POS:Vector2 = Vector2(-220, 230)
const RIGHT_POS:Vector2 = Vector2(220, 230)

@onready var game: CanvasLayer = $".."
@onready var animation_player: AnimationPlayer = $Visuals/AnimationPlayer
@onready var visuals: Node2D = $Visuals
@export var tree:Node2D
var hp:int
var dmg:int
var on_left_side:bool
var can_cut:bool
signal axe_swung

func _ready() -> void:
	initialize_state()

func initialize_state() -> void:
	hp = 1
	var gm = get_tree().get_first_node_in_group("game_manager")
	dmg = int(gm.axe_tier) if gm and "axe_tier" in gm else 1
	on_left_side = true
	can_cut = true
	animation_player.play("RESET")

func cut():
	if can_cut:
		animation_player.play("hit_tree")
		play_hit_tree_sound()

func move_left():
	if on_left_side:
		animation_player.play("move_limit")
	else:
		scale.x = 1
		on_left_side = true

func move_right():
	if !on_left_side:
		animation_player.play("move_limit")
	else:
		scale.x = -1
		on_left_side = false

func reduce_hp():
	hp -= 1
	if hp == 0:
		_play_lose_sound()
		game.set_game_over()

func _play_lose_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/lose.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)

func _input(event: InputEvent):
	if !game.game_over:
		if event.is_action_pressed("ui_accept"):
			cut()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
			move_left()
		elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
			move_right()

func _on_tree_tree_anim_finished(br_dir:Branch) -> void:
	if (br_dir == Branch.LEFT && on_left_side) or (br_dir == Branch.RIGHT && !on_left_side):
		reduce_hp()
	can_cut = true

func _send_hit_signal() -> void:
	emit_signal("axe_swung", dmg)
	animation_player.play("return_to_idle")

func play_hit_tree_sound():
	var sound_path = "res://minigames/woodchopper/music/hit_tree.wav"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)

func play_player_death_sound():
	var sound_path = "res://minigames/woodchopper/music/player_dies.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)
