extends Node

@onready var animation_player = $AnimationPlayer

func _ready():
	# Configurar input para poder saltar la cutscene
	set_process_input(true)
	
	# Esperar un frame para asegurar que todo está cargado
	await get_tree().process_frame
	
	# Verificar si el AnimationPlayer existe
	if not animation_player:
		print("ERROR: AnimationPlayer no encontrado en la cutscene")
		_go_to_next_scene()
		return
	
	print("Cutscene iniciada, AnimationPlayer encontrado")
	
	# Verificar si la animación "default" existe
	if not animation_player.has_animation("default"):
		print("ERROR: Animación 'default' no encontrada")
		# Intentar reproducir la primera animación disponible
		var anim_list = animation_player.get_animation_list()
		if anim_list.size() > 0:
			print("Reproduciendo primera animación disponible: ", anim_list[0])
			animation_player.play(anim_list[0])
		else:
			print("ERROR: No hay animaciones disponibles")
			_go_to_next_scene()
			return
	else:
		print("Reproduciendo animación 'default'")
		animation_player.play("default")
	
	# Conectar la señal de finished de la animación
	animation_player.animation_finished.connect(_on_animation_finished)

func _input(event):
	# Permitir saltar la cutscene con la barra espaciadora
	if event.is_action_pressed("ui_accept"):  # ui_accept es la barra espaciadora por defecto
		print("Cutscene saltada por el usuario")
		_skip_cutscene()

func _skip_cutscene():
	# Detener la animación y pasar a la siguiente escena
	if animation_player:
		animation_player.stop()
	_go_to_next_scene()

func _on_animation_finished(anim_name):
	# Cuando la animación termina, pasar a la siguiente escena
	print("Animación terminada: ", anim_name)
	_go_to_next_scene()

func _go_to_next_scene():
	# Transición a la escena del pueblo
	print("Transicionando a town.tscn")
	await SceneTransition.transition_to_scene(
		0.35,
		func():
			get_tree().change_scene_to_file("res://scenes/levels/town.tscn")
	)
