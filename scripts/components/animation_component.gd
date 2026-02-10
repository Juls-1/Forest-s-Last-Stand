extends Node
class_name AnimationComponent

@export var animated_sprite_path: NodePath = NodePath("AnimatedSprite2D")
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null(animated_sprite_path) if has_node(animated_sprite_path) else get_parent().get_node_or_null("AnimatedSprite2D")

var last_direction: Vector2 = Vector2(0, 1)
var is_casting: bool = false
var is_dying: bool = false

func update_animation(direction: Vector2, is_attacking: bool = false, attack_target: Node2D = null):
	if not animated_sprite or is_casting or is_dying:
		return
	
	if direction.length() > 0:
		last_direction = direction

	var suffix = get_direction_suffix(direction if direction.length() > 0 else last_direction)
	var animation_name = "idle_" + suffix

	# Fallback to generic idle if directional idle missing
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.sprite_frames.has_animation("idle"):
			animation_name = "idle"

	# Movimiento
	if direction.length() > 0:
		animation_name = "walk_" + suffix
	
	# Ataque
	if is_attacking:
		var attack_dir = direction
		if attack_target and is_instance_valid(attack_target):
			attack_dir = (attack_target.global_position - get_parent().global_position).normalized()
		elif direction.length() == 0:
			attack_dir = last_direction
		
		var attack_suffix = get_direction_suffix(attack_dir)
		animation_name = "attack_" + attack_suffix

	if animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.animation != animation_name:
			animated_sprite.play(animation_name)
	elif is_attacking:
		if animated_sprite.sprite_frames.has_animation("attack_s"):
			animated_sprite.play("attack_s")

func play_death():
	if not animated_sprite: return
	is_dying = true
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.stop()
		animated_sprite.play("death")
		await animated_sprite.animation_finished

func play_cast(direction: Vector2):
	if not animated_sprite: return
	is_casting = true
	
	var suffix = get_direction_suffix(direction)
	var anim_name = "cast_" + suffix
	
	# Fallback to attack if cast not found
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		anim_name = "attack_" + suffix
	
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		# Calculate duration for manual timeout (safer for looping/non-looping consistency)
		var duration = _get_animation_duration(anim_name)
		await get_tree().create_timer(duration).timeout
	else:
		await get_tree().create_timer(0.5).timeout
		
	is_casting = false
	# Force update to return to idle/walk
	update_animation(direction if direction.length() > 0 else last_direction)

func get_direction_suffix(angle_or_vector) -> String:
	var angle = 0.0
	if angle_or_vector is Vector2:
		angle = angle_or_vector.angle()
	elif angle_or_vector is float or angle_or_vector is int:
		angle = angle_or_vector
	else:
		return "s"
		
	var suffixes = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]
	
	var normalized_angle = angle + PI / 8
	if normalized_angle < 0:
		normalized_angle += 2 * PI
	normalized_angle = fmod(normalized_angle, 2 * PI)
	
	var index = int(normalized_angle / (PI / 4))
	index = index % 8
	
	return suffixes[index]

func _get_animation_duration(anim_name: String) -> float:
	if not animated_sprite or not animated_sprite.sprite_frames:
		return 0.6
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		return 0.6
	
	var frame_count = animated_sprite.sprite_frames.get_frame_count(anim_name)
	var fps = animated_sprite.sprite_frames.get_animation_speed(anim_name)
	if fps <= 0: fps = 5.0
	
	var total_duration: float = 0.0
	for i in range(frame_count):
		total_duration += animated_sprite.sprite_frames.get_frame_duration(anim_name, i) / fps
	return total_duration

# Compatibility
func get_direction_animation(angle):
	return "walk_" + get_direction_suffix(angle)
