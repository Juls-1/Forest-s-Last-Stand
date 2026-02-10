extends Node2D

const Branch = WChData.BranchDirection
const MAX_SEGMENTS:int = 4

@onready var game: CanvasLayer = $".."
@onready var player: Node2D = $"../Player"
@export var tree_segment:PackedScene
@export var first_segment:Node2D
var segment_positions:Array
var tree:Array
var can_take_dmg:bool
signal tree_anim_finished

func _ready() -> void:
	first_segment.segment_died.connect(_on_tree_segment_segment_died)
	segment_positions = []
	for i in range(0, MAX_SEGMENTS):
		segment_positions.append(WChData.TREE_START_OFFSET + WChData.LOG_SIZE * -i)
	tree = []
	tree.append(first_segment)
	for i in range(1, MAX_SEGMENTS -1):
		add_segment()
	can_take_dmg = true

func add_segment() -> void:
	var segment = _generate_segment()
	if segment != null:
		tree.append(segment)
		tree.back().position.y = segment_positions[tree.size()-1]
		add_child(segment)

func _generate_segment() -> Node2D:
	var previous:Branch = tree.back().branch
	var new:Branch = _choose_branch(previous)
	var segment = tree_segment.instantiate()
	segment.segment_died.connect(_on_tree_segment_segment_died)
	segment.set_branch(new)
	return segment

func _choose_branch(previous:Branch) -> Branch:
	var options
	if previous == Branch.LEFT:
		options = [Branch.LEFT, Branch.NONE]
	elif previous == Branch.RIGHT:
		options = [Branch.NONE, Branch.RIGHT]
	else:
		options = [Branch.LEFT, Branch.NONE, Branch.RIGHT]
	return options.pick_random()

func _poll() -> void:
	if not tree.is_empty():
		tree[0].queue_free()
		tree.pop_front()

func _on_tree_segment_segment_died() -> void:
	can_take_dmg = false
	player.can_cut = false
	tree[0].queue_free()
	add_segment()
	tree.pop_front()
	for i in range(0, tree.size()):
		tree[i].move_to_target_y(segment_positions[i])
	await get_tree().create_timer(WChData.SEGM_FALL_DURATION).timeout
	emit_signal("tree_anim_finished", tree[0].branch)
	game.increase_wood_counter()
	can_take_dmg = true

func _on_player_axe_swung(dmg) -> void:
	if can_take_dmg:
		tree[0].throw_particles()  
		tree[0].decrease_hp(dmg)
