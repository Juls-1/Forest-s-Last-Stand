extends Node2D

const SMALL_SCALE = Vector2(2, 2)
const BIG_SCALE = Vector2(7, 7)

@onready var spark_anim: AnimatedSprite2D = $AnimatedSprite2D

func throw_small_spark() -> void:
	spark_anim.stop()
	spark_anim.scale = SMALL_SCALE
	spark_anim.play()
	
func throw_big_spark() -> void:
	spark_anim.stop()
	spark_anim.scale = BIG_SCALE
	spark_anim.play()
