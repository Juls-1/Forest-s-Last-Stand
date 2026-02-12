extends Rock
class_name ExplodingRock

const APPEAR_ANIM_TIME:float = 3
const WAITING_TIME:float = 2.5
const START_POS:Vector2 = Vector2(116, 300)
const END_POS:Vector2 = Vector2(116, 155)
const MAX_HP:int = 1

@onready var hb_bottom: CollisionShape2D = $Hitbox/Area2D/HBBottom
@onready var hb_top: CollisionShape2D = $Hitbox/Area2D/HBTop
@onready var light: PointLight2D = $Visuals/PointLight2D

signal rock_exploded(rock)

func _ready() -> void:
	hp = MAX_HP
	var tw = create_tween().set_parallel()
	tw.tween_property(
		visuals,
		"position:y",
		END_POS.y,
		APPEAR_ANIM_TIME
	).set_ease(Tween.EASE_OUT)
	tw.tween_property(
		light,
		"energy",
		2,
		2.5
	)
	tw.chain().tween_interval(WAITING_TIME)
	tw.chain().tween_property(
		visuals,
		"position:y",
		START_POS.y,
		APPEAR_ANIM_TIME
	).set_ease(Tween.EASE_IN)
	tw.tween_property(
		light,
		"energy",
		0,
		2.5
	)
	
	var rand_wait:float = randf_range(2, 7)
	await get_tree().create_timer(rand_wait).timeout
	_free_hole()
	queue_free()

func _die() -> void:
	rock_exploded.emit(self)
	var e = explosion.instantiate()
	hole.front.add_child(e)
	var animator: AnimationPlayer = e.get_node("AnimationPlayer")
	animator.play("explosion")
	_play_explosion_sound()
	super._die()

func _play_explosion_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/lose.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)
