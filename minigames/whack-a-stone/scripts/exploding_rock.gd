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
	#hb_bottom.disabled = true
	#hb_top.disabled = true
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
	#await get_tree().create_timer(1).timeout
	#hb_bottom.disabled = false
	#await get_tree().create_timer(0.8).timeout
	#hb_top.disabled = false
	#await get_tree().create_timer(4.5).timeout
	#hb_top.disabled = true
	#await get_tree().create_timer(1.2).timeout
	#hb_bottom.disabled = true
	
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
	super._die()
