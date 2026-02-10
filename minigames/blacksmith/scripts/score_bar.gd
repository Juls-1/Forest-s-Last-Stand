extends PanelContainer

const COLOR_CHANGE_DURATION:float = 0.3

@onready var score_text: Label = $MarginContainer/ScoreText
@onready var color_panel: Panel = $ColorPanel
@onready var sfx_player: AudioStreamPlayer = $"../SFXPlayer"
@onready var score_label: Label = $"../GameOverScreen/ScoreLabel"
@onready var game_over_screen: Node2D = $"../GameOverScreen"

var neutral_bar_color = Color(0.29, 0.29, 0.29, 1.0)
var negative_bar_color = Color(0.52, 0.14, 0.14, 1.0)
var positive_bar_color = Color(0.159, 0.52, 0.14, 1.0)

var style_box:StyleBoxFlat

var score:int = 0
var max_score:int = 10
var min_score:int = -10

func _ready() -> void:
	style_box = color_panel.get_theme_stylebox("panel").duplicate()
	color_panel.add_theme_stylebox_override("panel", style_box)

func change_score(n:int):
	if score <= max_score and score >= min_score:
		score += n
		score = clamp(score, min_score, max_score)
		update_score_bar()

func update_score_bar():  
	var change_amount:float
	var nuevo:Color
	score_text.text = str(score)
	if score > 0:
		change_amount = score / (max_score * 1.0)
		nuevo = neutral_bar_color.lerp(positive_bar_color, change_amount)
	elif score < 0:
		change_amount = score / (min_score * 1.0)
		nuevo = neutral_bar_color.lerp(negative_bar_color, change_amount)
	else:
		nuevo = neutral_bar_color
	var t:Tween = create_tween()
	t.tween_property(style_box, "bg_color", nuevo, COLOR_CHANGE_DURATION)

func game_over() -> void:
	var score_template:String = "{0}/{1}"
	score_label.text = score_template.format([score, max_score])
	game_over_screen.visible = true
	if score <= max_score * 0.75:
		sfx_player.play_lose_sound()
	else:
		sfx_player.play_win_sound()
