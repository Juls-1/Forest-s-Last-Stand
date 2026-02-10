extends CanvasLayer
## Minijuego ruleta: apuesta a rojo, negro o verde. Pares = negro, impares = rojo, 0 = verde.

# Monedas actuales (pasadas desde town)
var current_coins: int = 0
var initial_coins: int = 0

# Orden de valores en el Strip (nombres de nodos: 9,10,5,6,11,2,13,12,0,7,8,15,14,3,4,1,16)
const STRIP_VALUES: Array[int] = [9, 10, 5, 6, 11, 2, 13, 12, 0, 7, 8, 15, 14, 3, 4, 1, 16]

enum BetColor { NONE, RED, BLACK, GREEN }

var current_bet: int = 0
var selected_color: BetColor = BetColor.NONE
var is_spinning: bool = false

# Nodos (rutas desde el root: el script va en CanvasLayer, hijo "Roulette" PanelContainer)
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
	# Usar siempre el oro que viene del juego (HUD); 0 es válido si el jugador está sin dinero
	current_coins = initial_coins
	_refresh_money_display()
	bet_slider.min_value = 1
	bet_slider.max_value = max(1, current_coins)
	bet_slider.value = min(100, max(1, current_coins))
	bet_slider.value_changed.connect(_on_bet_slider_changed)
	_on_bet_slider_changed(bet_slider.value)

	red_btn.pressed.connect(_on_red_pressed)
	black_btn.pressed.connect(_on_black_pressed)
	green_btn.pressed.connect(_on_green_pressed)
	accept_btn.pressed.connect(_on_accept_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

	# Mensaje de resultado: oculto hasta que se gire la ruleta
	if message_label:
		message_label.visible = false
	# Duplicar la tira 3 veces más para poder hacer varias vueltas (4 conjuntos de 0-16)
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
	# Girar la tira; el dinero solo se actualiza al terminar (en _finish_spin)
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

## Gira la tira a una posición aleatoria; al parar, el número bajo el pointer es el ganador.
func _spin_then_read_winner() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(strip) or strip.get_child_count() == 0:
		_finish_spin(0, 0)
		return
	var strip_width: float = strip.size.x
	var view_width: float = viewport_scroll.size.x
	var max_scroll: float = maxf(0.0, strip_width - view_width)
	# Posición final aleatoria: el jugador ve parar la tira y el número bajo el pointer es el resultado
	var target_scroll: float = randf() * max_scroll if max_scroll > 0 else 0.0
	var duration: float = 2.0 + randf() * 1.0
	viewport_scroll.scroll_horizontal = 0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(viewport_scroll, "scroll_horizontal", int(roundf(target_scroll)), duration)
	await tween.finished
	viewport_scroll.scroll_horizontal = int(roundf(target_scroll))
	var winning_value: int = _get_value_under_pointer()
	_finish_spin(winning_value, current_bet)

## Devuelve el número de la celda que está bajo el pointer usando posiciones reales (global + layout).
func _get_value_under_pointer() -> int:
	if not is_instance_valid(strip) or strip.get_child_count() == 0:
		return 0
	if not is_instance_valid(pointer) or not is_instance_valid(viewport_scroll):
		return 0
	# Centro del pointer en coordenadas globales
	var pointer_center_global: float = pointer.global_position.x + pointer.size.x * 0.5
	# En ScrollContainer, el Strip está en (-scroll_horizontal, 0) respecto al viewport
	# => strip.global_position.x = viewport.global_position.x - scroll_horizontal
	# La X en espacio del Strip bajo el pointer:
	var center_x_in_strip: float = pointer_center_global - viewport_scroll.global_position.x + float(viewport_scroll.scroll_horizontal)
	# Usar el layout real del Strip: posición y ancho del primer hijo (HBoxContainer con alignment center)
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
	# Actualizar dinero solo al terminar: ganancia neta = payout - bet (positivo si ganó, negativo si perdió)
	current_coins += (payout - bet)
	current_coins = max(0, current_coins)
	_refresh_money_display()
	# Mostrar mensaje solo si hubo tirada real (bet > 0)
	if message_label and bet > 0:
		message_label.visible = true
		message_label.text = "Ganaste!" if won else "Perdiste."
	selected_color = BetColor.NONE
	is_spinning = false
	accept_btn.disabled = false
	# Actualizar oro en el juego: ganancia neta = payout - bet (positivo si ganó, negativo si perdió)
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("update_resources"):
		gm.update_resources(payout - bet, 0, 0)

# Pares = negro, impares = rojo, 0 = verde
func _is_red(value: int) -> bool:
	return value != 0 and value % 2 == 1

func _is_black(value: int) -> bool:
	return value != 0 and value % 2 == 0

func _on_cancel_pressed() -> void:
	if is_spinning:
		return
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	# El oro ya se actualizó en cada tirada vía update_resources en _finish_spin
	get_tree().paused = false
	queue_free()
	if SceneTransition:
		SceneTransition.fade_in(0.3)
