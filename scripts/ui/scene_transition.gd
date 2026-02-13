extends Node

signal fade_out_finished
signal fade_in_finished

var _overlay: ColorRect
var _canvas: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = CanvasLayer.new()
	_canvas.layer = 200
	_canvas.name = "TransitionOverlay"
	add_child(_canvas)
	_overlay = ColorRect.new()
	_overlay.name = "FadeOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(0, 0, 0, 0)
	_canvas.add_child(_overlay)

func fade_out(duration: float = 0.35) -> void:
	var tween = create_tween()
	tween.tween_property(_overlay, "color", Color(0, 0, 0, 1), duration)
	tween.tween_callback(func(): fade_out_finished.emit())

func fade_in(duration: float = 0.35) -> void:
	_overlay.color = Color(0, 0, 0, 1)
	var tween = create_tween()
	tween.tween_property(_overlay, "color", Color(0, 0, 0, 0), duration)
	tween.tween_callback(func(): fade_in_finished.emit())

func transition_to_scene(fade_duration: float, change_callable: Callable) -> void:
	fade_out(fade_duration)
	await fade_out_finished
	change_callable.call()
	await get_tree().process_frame
	fade_in(fade_duration)
	await fade_in_finished
