extends CanvasLayer
var current_coins: int = 0
var initial_coins: int = 0
const STRIP_VALUES: Array[int] = [9, 10, 5, 6, 11, 2, 13, 12, 0, 7, 8, 15, 14, 3, 4, 1, 16]

enum BetColor { NONE, RED, BLACK, GREEN }

var current_bet: int = 0
var selected_color: BetColor = BetColor.NONE
var is_spinning: bool = false
@onready var money_label: Label = $Roulette/MarginContainer/Header/Money
@onready var bet_amount_label: Label = $Roulette/MarginContainer/UI_Container/Bet/BetText/BetAmountLabel
@onready var bet_slider: HSlider = $Roulette/MarginContainer/UI_Container/Bet/BetSlider
@onready var roulette_area: Control = $Roulette/MarginContainer/UI_Container/RouletteArea
@onready var viewport_scroll: ScrollContainer = $Roulette/MarginContainer/UI_Container/RouletteArea/RouletteViewport
@onready var strip: HBoxContainer = $Roulette/MarginContainer/UI_Container/RouletteArea/RouletteViewport/Strip
@onready var pointer: Control = $Roulette/MarginContainer/UI_Container/RouletteArea/Pointer
@onready var red_btn: Button = $Roulette/MarginContainer/UI_Container/BetButtons/RedBtn
@onready var black_btn: Button = $Roulette/MarginContainer/UI_Container/BetButtons/BlackBtn
@onready var green_btn: Button = $Roulette/MarginContainer/UI_Container/BetButtons/GreenBtn
@onready var accept_btn: Button = $Roulette/MarginContainer/UI_Container/ActionButtons/AcceptBtn
@onready var cancel_btn: Button = $Roulette/MarginContainer/UI_Container/ActionButtons/CancelBtn
@onready var message_label: Label = $Message

func _ready() -> void:
	current_coins = initial_coins
	_refresh_money_display()
	bet_slider.min_value = 1
	bet_slider.max_value = max(1, current_coins)
	bet_slider.value = min(100, max(1, current_coins))
	bet_slider.value_changed.connect(_on_bet_slider_changed)
	_on_bet_slider_changed(bet_slider.value)

	red_btn.pressed.connect(_on_red_pressed)
	red_btn.pressed.connect(_play_click_sound)
	black_btn.pressed.connect(_on_black_pressed)
	black_btn.pressed.connect(_play_click_sound)
	green_btn.pressed.connect(_on_green_pressed)
	green_btn.pressed.connect(_play_click_sound)
	accept_btn.pressed.connect(_on_accept_pressed)
	accept_btn.pressed.connect(_play_click_sound)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	cancel_btn.pressed.connect(_play_click_sound)
	if message_label:
		message_label.visible = false
	await get_tree().process_frame
	_build_long_strip()

func _refresh_money_display() -> void:
	if money_label:
		money_label.text = str(current_coins)
	if bet_slider:
		bet_slider.max_value = max(1, current_coins)
		bet_slider.value = clampi(int(bet_slider.value), 1, max(1, current_coins))

func _on_bet_slider_changed(value: float) -> void:
	current_bet = int(value)
	if bet_amount_label:
		bet_amount_label.text = "Apuesta: %d" % current_bet

func _on_red_pressed() -> void:
	selected_color = BetColor.RED

func _on_black_pressed() -> void:
	selected_color = BetColor.BLACK

func _on_green_pressed() -> void:
	selected_color = BetColor.GREEN

func _on_accept_pressed() -> void:
	if is_spinning:
		return
	if selected_color == BetColor.NONE:
		return
	if current_bet <= 0 or current_bet > current_coins:
		return
	is_spinning = true
	accept_btn.disabled = true
	_spin_then_read_winner()

func _build_long_strip() -> void:
	if strip.get_child_count() == 0:
		return
	var original_children: Array = []
	for c in strip.get_children():
		original_children.append(c)
	for _i in range(3):
		for c in original_children:
			var dup: Control = c.duplicate()
			strip.add_child(dup)
func _spin_then_read_winner() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(strip) or strip.get_child_count() == 0:
		_finish_spin(0, 0)
		return
	var strip_width: float = strip.size.x
	var view_width: float = viewport_scroll.size.x
	var max_scroll: float = maxf(0.0, strip_width - view_width)
	var target_scroll: float = randf() * max_scroll if max_scroll > 0 else 0.0
	var duration: float = 2.0 + randf() * 1.0
	viewport_scroll.scroll_horizontal = 0
	_play_roulette_sound()
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(viewport_scroll, "scroll_horizontal", int(roundf(target_scroll)), duration)
	await tween.finished
	viewport_scroll.scroll_horizontal = int(roundf(target_scroll))
	var winning_value: int = _get_value_under_pointer()
	_finish_spin(winning_value, current_bet)
func _get_value_under_pointer() -> int:
	if not is_instance_valid(strip) or strip.get_child_count() == 0:
		return 0
	if not is_instance_valid(pointer) or not is_instance_valid(viewport_scroll):
		return 0
	var pointer_center_global: float = pointer.global_position.x + pointer.size.x * 0.5
	var center_x_in_strip: float = pointer_center_global - viewport_scroll.global_position.x + float(viewport_scroll.scroll_horizontal)
	var first: Control = strip.get_child(0) as Control
	if not first:
		return 0
	var strip_offset: float = first.position.x
	var cell_width: float = first.size.x
	if cell_width <= 0.0:
		cell_width = 32.0
	var num_cells: int = strip.get_child_count()
	var cell_index: int = int((center_x_in_strip - strip_offset) / cell_width)
	cell_index = clampi(cell_index, 0, num_cells - 1)
	return STRIP_VALUES[cell_index % 17]

func _finish_spin(winning_value: int, bet: int) -> void:
	var won: bool = false
	var payout: int = 0
	match selected_color:
		BetColor.RED:
			won = _is_red(winning_value)
			payout = bet * 2 if won else 0
		BetColor.BLACK:
			won = _is_black(winning_value)
			payout = bet * 2 if won else 0
		BetColor.GREEN:
			won = (winning_value == 0)
			payout = bet * 17 if won else 0
	current_coins += (payout - bet)
	current_coins = max(0, current_coins)
	_refresh_money_display()
	if message_label and bet > 0:
		message_label.visible = true
		message_label.text = "Ganaste!" if won else "Perdiste."
		if won:
			_play_win_sound()
		else:
			_play_lose_sound()
	selected_color = BetColor.NONE
	is_spinning = false
	accept_btn.disabled = false
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("update_resources"):
		gm.update_resources(payout - bet, 0, 0)
func _is_red(value: int) -> bool:
	return value != 0 and value % 2 == 1

func _is_black(value: int) -> bool:
	return value != 0 and value % 2 == 0

func _play_click_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/click.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)

func _play_roulette_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/roulette.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)

func _play_win_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/win.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)

func _play_lose_sound():
	var sound_path = "res://assets/sound/attacks_and_mosnters/lose.mp3"
	if ResourceLoader.exists(sound_path):
		var sound = load(sound_path)
		if SoundManager and sound:
			SoundManager.play_global_sfx(sound)

func _on_cancel_pressed() -> void:
	if is_spinning:
		return
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	get_tree().paused = false
	queue_free()
	if SceneTransition:
		SceneTransition.fade_in(0.3)
