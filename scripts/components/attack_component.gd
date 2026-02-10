extends Node
class_name AttackComponent

@export var damage: int = 10
@export var attack_range: float = 100.0
@export var attack_cooldown: float = 1.0
@export var projectile_scene: PackedScene 

var attack_timer: float = 0.0 
var target: Node2D = null 

signal attacked(target: Node2D)

func _process(delta: float):
	if attack_timer > 0:
		attack_timer -= delta

func set_target(new_target: Node2D):
	target = new_target

func can_attack() -> bool:
	if attack_timer > 0 or not is_instance_valid(target):
		return false
	
	var distance = get_parent().global_position.distance_to(target.global_position)
	return distance <= attack_range

func perform_attack():
	if not can_attack():
		return
	
	attack_timer = attack_cooldown
	attacked.emit(target)
	
	if projectile_scene:
		_fire_projectile()
	else:
		_melee_attack()

func _fire_projectile():
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	var muzzle = get_parent().get_node_or_null("Muzzle")
	projectile.global_position = muzzle.global_position if muzzle else get_parent().global_position
	projectile.rotation = (target.global_position - get_parent().global_position).angle()

func _melee_attack():
	if target.has_method("take_damage"):
		target.take_damage(damage)
