extends Rock

const APPEAR_ANIM_TIME:float = 0.6
const WAITING_TIME:float = 1.5
const START_POS:Vector2 = Vector2(125, 342)
const END_POS:Vector2 = Vector2(125, 121)
const MAX_HP:int = 5

@onready var hitbox: CollisionPolygon2D = $Hitbox/Area2D/CollisionPolygon2D

func _ready() -> void:
	hp = MAX_HP
	#hitbox.disabled = true
	var tw = create_tween()
	tw.tween_property(
		visuals,
		"position:y",
		END_POS.y,
		APPEAR_ANIM_TIME
	).set_trans(Tween.TRANS_SPRING)
	tw.tween_interval(WAITING_TIME)
	tw.tween_property(
		visuals,
		"position:y",
		START_POS.y,
		APPEAR_ANIM_TIME
	)
	#await get_tree().create_timer(0.9).timeout
	#hitbox.disabled = false
	#await get_tree().create_timer(1.2).timeout
	#hitbox.disabled = true
	
	var rand_wait:float = randf_range(2, 7)
	await get_tree().create_timer(rand_wait).timeout
	_free_hole()
	queue_free()
