extends CanvasLayer
## Minijuego Mercado: comprar/vender recursos y mejorar hacha y picota.
## Recursos y dinero se pasan desde town (como en ruleta). Actualiza GameManager al comprar/vender/mejorar.

# Recursos actuales (pasados desde town)
var current_gold: int = 0
var current_wood: int = 0
var current_stone: int = 0
var initial_gold: int = 0
var initial_wood: int = 0
var initial_stone: int = 0

# Precios fijos
const WOOD_BUY_PRICE: int = 10
const WOOD_SELL_PRICE: int = 5
const ROCK_BUY_PRICE: int = 15
const ROCK_SELL_PRICE: int = 7

# Precios por tier: axe [tier1->2, tier2->3], mismo orden para gold/stone/wood
const AXE_GOLD: Array[int] = [50, 100]
const AXE_STONE: Array[int] = [10, 20]
const AXE_WOOD: Array[int] = [8, 15]
const PICKAXE_GOLD: Array[int] = [60, 120]
const PICKAXE_STONE: Array[int] = [15, 30]
const PICKAXE_WOOD: Array[int] = [10, 20]

const MAX_TOOL_TIER: int = 3

# Nodos UI (script en Market CanvasLayer, hijo PanelContainer)
@onready var money_label: Label = $PanelContainer/MarginContainer/Header/Money
@onready var wood_label: Label = $PanelContainer/MarginContainer/Header/Wood
@onready var stone_label: Label = $PanelContainer/MarginContainer/Header/Stone
@onready var wood_buy_price_label: Label = $PanelContainer/MarginContainer/MarketSections/ResourceContainer/ResourceSection/ResourceContainer/ResourceMargin/Resources/Wood/WoodBuyTag/WoodBuyPrice
@onready var wood_sell_price_label: Label = $PanelContainer/MarginContainer/MarketSections/ResourceContainer/ResourceSection/ResourceContainer/ResourceMargin/Resources/Wood/WoodSellTag/WoodSellPrice
@onready var wood_buy_btn: Button = $PanelContainer/MarginContainer/MarketSections/ResourceContainer/ResourceSection/ResourceContainer/ResourceMargin/Resources/Wood/WoodBuyBtn
@onready var wood_sell_btn: Button = $PanelContainer/MarginContainer/MarketSections/ResourceContainer/ResourceSection/ResourceContainer/ResourceMargin/Resources/Wood/WoodSellBtn
@onready var rock_buy_price_label: Label = $PanelContainer/MarginContainer/MarketSections/ResourceContainer/ResourceSection/ResourceContainer/ResourceMargin/Resources/Rock/RockBuyTag/RockBuyPrice
@onready var rock_sell_price_label: Label = $PanelContainer/MarginContainer/MarketSections/ResourceContainer/ResourceSection/ResourceContainer/ResourceMargin/Resources/Rock/RockSellTag/RockSellPrice
@onready var rock_buy_btn: Button = $PanelContainer/MarginContainer/MarketSections/ResourceContainer/ResourceSection/ResourceContainer/ResourceMargin/Resources/Rock/RockBuyBtn
@onready var rock_sell_btn: Button = $PanelContainer/MarginContainer/MarketSections/ResourceContainer/ResourceSection/ResourceContainer/ResourceMargin/Resources/Rock/RockSellBtn
@onready var axe_gold_label: Label = $PanelContainer/MarginContainer/MarketSections/ToolContainer/ToolSection/ToolContainer/ToolMargin/Tools/Axe/AxeGoldPrice/AxeGoldPriceLabel
@onready var axe_stone_label: Label = $PanelContainer/MarginContainer/MarketSections/ToolContainer/ToolSection/ToolContainer/ToolMargin/Tools/Axe/AxeStonePrice/AxeStonePriceLabel
@onready var axe_wood_label: Label = $PanelContainer/MarginContainer/MarketSections/ToolContainer/ToolSection/ToolContainer/ToolMargin/Tools/Axe/AxeWoodPrice/AxeWoodPriceLabel
@onready var axe_upgrade_btn: Button = $PanelContainer/MarginContainer/MarketSections/ToolContainer/ToolSection/ToolContainer/ToolMargin/Tools/Axe/AxeUpgradeButton
@onready var pickaxe_gold_label: Label = $PanelContainer/MarginContainer/MarketSections/ToolContainer/ToolSection/ToolContainer/ToolMargin/Tools/PickAxe/PickaxeGoldPrice/PickaxeGoldPriceLabel
@onready var pickaxe_stone_label: Label = $PanelContainer/MarginContainer/MarketSections/ToolContainer/ToolSection/ToolContainer/ToolMargin/Tools/PickAxe/PickaxeStonePrice/PickaxeStonePriceLabel
@onready var pickaxe_wood_label: Label = $PanelContainer/MarginContainer/MarketSections/ToolContainer/ToolSection/ToolContainer/ToolMargin/Tools/PickAxe/PickaxeWoodPrice/PickaxeWoodPriceLabel
@onready var pickaxe_upgrade_btn: Button = $PanelContainer/MarginContainer/MarketSections/ToolContainer/ToolSection/ToolContainer/ToolMargin/Tools/PickAxe/PickaxeUpgradeBtn
@onready var back_btn: Button = $PanelContainer/MarginContainer/BackBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_gold = initial_gold
	current_wood = initial_wood
	current_stone = initial_stone
	_refresh_display()
	_set_static_prices()
	_update_tool_labels()

	wood_buy_btn.pressed.connect(_on_wood_buy_pressed)
	wood_sell_btn.pressed.connect(_on_wood_sell_pressed)
	rock_buy_btn.pressed.connect(_on_rock_buy_pressed)
	rock_sell_btn.pressed.connect(_on_rock_sell_pressed)
	axe_upgrade_btn.pressed.connect(_on_axe_upgrade_pressed)
	pickaxe_upgrade_btn.pressed.connect(_on_pickaxe_upgrade_pressed)
	back_btn.pressed.connect(_on_back_pressed)

func _refresh_display() -> void:
	if money_label:
		money_label.text = str(current_gold)
	if wood_label:
		wood_label.text = str(current_wood)
	if stone_label:
		stone_label.text = str(current_stone)

func _set_static_prices() -> void:
	if wood_buy_price_label:
		wood_buy_price_label.text = str(WOOD_BUY_PRICE)
	if wood_sell_price_label:
		wood_sell_price_label.text = str(WOOD_SELL_PRICE)
	if rock_buy_price_label:
		rock_buy_price_label.text = str(ROCK_BUY_PRICE)
	if rock_sell_price_label:
		rock_sell_price_label.text = str(ROCK_SELL_PRICE)

func _get_axe_tier() -> int:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and "axe_tier" in gm:
		return int(gm.axe_tier)
	return 1

func _get_pickaxe_tier() -> int:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and "pickaxe_tier" in gm:
		return int(gm.pickaxe_tier)
	return 1

func _update_tool_labels() -> void:
	var at: int = _get_axe_tier()
	var pt: int = _get_pickaxe_tier()

	if at >= MAX_TOOL_TIER:
		if axe_gold_label: axe_gold_label.text = "X"
		if axe_stone_label: axe_stone_label.text = "X"
		if axe_wood_label: axe_wood_label.text = "X"
		if axe_upgrade_btn: axe_upgrade_btn.disabled = true
	else:
		var i: int = at - 1
		if axe_gold_label: axe_gold_label.text = str(AXE_GOLD[i])
		if axe_stone_label: axe_stone_label.text = str(AXE_STONE[i])
		if axe_wood_label: axe_wood_label.text = str(AXE_WOOD[i])
		if axe_upgrade_btn: axe_upgrade_btn.disabled = false

	if pt >= MAX_TOOL_TIER:
		if pickaxe_gold_label: pickaxe_gold_label.text = "X"
		if pickaxe_stone_label: pickaxe_stone_label.text = "X"
		if pickaxe_wood_label: pickaxe_wood_label.text = "X"
		if pickaxe_upgrade_btn: pickaxe_upgrade_btn.disabled = true
	else:
		var j: int = pt - 1
		if pickaxe_gold_label: pickaxe_gold_label.text = str(PICKAXE_GOLD[j])
		if pickaxe_stone_label: pickaxe_stone_label.text = str(PICKAXE_STONE[j])
		if pickaxe_wood_label: pickaxe_wood_label.text = str(PICKAXE_WOOD[j])
		if pickaxe_upgrade_btn: pickaxe_upgrade_btn.disabled = false

func _apply_to_game(gold_d: int, wood_d: int, stone_d: int) -> void:
	current_gold += gold_d
	current_wood += wood_d
	current_stone += stone_d
	_refresh_display()
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("update_resources"):
		gm.update_resources(gold_d, wood_d, stone_d)

func _on_wood_buy_pressed() -> void:
	if current_gold < WOOD_BUY_PRICE:
		return
	_apply_to_game(-WOOD_BUY_PRICE, 1, 0)

func _on_wood_sell_pressed() -> void:
	if current_wood < 1:
		return
	_apply_to_game(WOOD_SELL_PRICE, -1, 0)

func _on_rock_buy_pressed() -> void:
	if current_gold < ROCK_BUY_PRICE:
		return
	_apply_to_game(-ROCK_BUY_PRICE, 0, 1)

func _on_rock_sell_pressed() -> void:
	if current_stone < 1:
		return
	_apply_to_game(ROCK_SELL_PRICE, 0, -1)

func _on_axe_upgrade_pressed() -> void:
	var at: int = _get_axe_tier()
	if at >= MAX_TOOL_TIER:
		return
	var i: int = at - 1
	if current_gold < AXE_GOLD[i] or current_stone < AXE_STONE[i] or current_wood < AXE_WOOD[i]:
		return
	_apply_to_game(-AXE_GOLD[i], -AXE_WOOD[i], -AXE_STONE[i])
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and "axe_tier" in gm:
		gm.axe_tier = at + 1
	_update_tool_labels()

func _on_pickaxe_upgrade_pressed() -> void:
	var pt: int = _get_pickaxe_tier()
	if pt >= MAX_TOOL_TIER:
		return
	var j: int = pt - 1
	if current_gold < PICKAXE_GOLD[j] or current_stone < PICKAXE_STONE[j] or current_wood < PICKAXE_WOOD[j]:
		return
	_apply_to_game(-PICKAXE_GOLD[j], -PICKAXE_WOOD[j], -PICKAXE_STONE[j])
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and "pickaxe_tier" in gm:
		gm.pickaxe_tier = pt + 1
	_update_tool_labels()

func _on_back_pressed() -> void:
	if SceneTransition:
		SceneTransition.fade_out(0.3)
		await SceneTransition.fade_out_finished
	get_tree().paused = false
	queue_free()
	if SceneTransition:
		SceneTransition.fade_in(0.3)
