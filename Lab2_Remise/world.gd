extends Node2D
const Boid = preload("res://boid.gd")
var _is_reloading := false

@onready var sprite: Sprite2D = $Image

@onready var player_scene = preload("res://player.tscn")

@export var floor_y := 450          # hauteur du sol

@export_range(3, 500, 2) var num_boids : int = 500  # Nombre cible de boids
@export var debugging : bool = false :
	set(value):
		debugging = value
		set_debug()

@export var enable_separation : bool = false :
	set(value) :
		enable_separation = value
		update_forces()
		
@export var enable_alignment : bool = true  :
	set(value) :
		enable_alignment = value
		update_forces()		
		
@export var enable_cohesion : bool = true  :
	set(value) :
		enable_cohesion = value
		update_forces()

@onready var boid_scene = preload("res://boid.tscn")

func _ready():
	var p = player_scene.instantiate()
	add_child(p)
	
	p.tree_exited.connect(_on_player_died)
	
	var screen := get_viewport_rect().size
	p.global_position = Vector2(screen.x * 0.5, screen.y - 50)
	randomize()  # Initialisation aléatoire
	num_boids = randi_range(10, 20)
	adjust_boids()  # Ajuste le nombre de boids initialement
	set_debug()
	update_forces()
	
	var t := Timer.new()
	t.wait_time = 5.0
	t.autostart = true
	t.one_shot = false
	add_child(t)
	t.timeout.connect(_on_spawn_timer_timeout)
	
func _on_player_died() -> void:
	if _is_reloading:
		return
	_is_reloading = true
	get_tree().call_deferred("reload_current_scene")
	
	
func _on_spawn_timer_timeout():
	var b = boid_scene.instantiate()
	b.global_position = Vector2(
		randf_range(0.0, get_viewport_rect().size.x),
		randf_range(0.0, 400)
	)

	# changer la texture
	var img = b.get_node("Image")
	img.texture = preload("res://assets/playerShip2_red.png")
	
	# 🔄 rotation de 90 degrés
	img.rotation_degrees = 90
	
	b.has_cohesion   = enable_cohesion
	b.has_alignment  = enable_alignment
	b.has_separation = enable_separation

	add_child(b)
	
	
# Ajuste dynamiquement le nombre de boids pour correspondre à "num_boids"
func adjust_boids():
	var current_boids = get_children().filter(func(n): return n is Boid)
	var current_count = current_boids.size()

	if current_count < num_boids:
		# Ajouter des boids manquants
		add_boids(num_boids - current_count)
	elif current_count > num_boids:
		# Retirer des boids en excès
		remove_boids(current_count - num_boids)

# Ajouter les boids manquants
func add_boids(count: int):
	for i in range(count):
		var boid_instance = boid_scene.instantiate()
		boid_instance.position = Vector2(randf_range(0.0, get_viewport_rect().size.x),randf_range(0.0, 100))
		add_child(boid_instance)

# Retirer aléatoirement les boids en excès
func remove_boids(count: int):
	var current_boids = get_children().filter(func(n): return n is Boid)
	for i in range(count):
		var random_boid = current_boids[randi_range(0, current_boids.size() - 1)]
		current_boids.erase(random_boid)
		random_boid.queue_free()

func set_debug():
	if not is_node_ready() : return
	
	var current_boids = get_children().filter(func(n): return n is Boid)
	
	if current_boids.is_empty():
		return

	# Parcourt la taille réelle, pas num_boids
	for i in range(current_boids.size()):
		if i == 0:
			current_boids[0].is_chosen = debugging
		else:
			current_boids[i].set_debug(debugging)
			current_boids[i].is_chosen = false
	

# Cette fonction peut être appelée à tout moment pour ajuster le nombre de boids
func _process(delta):
	manage_inputs()
	
	# Appel d'ajustement pour synchroniser le nombre de boids si le champ change
	
	#if num_boids != get_children().filter(func(n): return n is Boid).size():
	#	adjust_boids()

func manage_inputs() -> void :
	if (Input.is_action_just_pressed("quit")):
		get_tree().quit()
	# ALT + D pour basculer le mode débogage
	if (Input.is_action_just_pressed("toggle_debug")):
		debugging = !debugging
		
	if Input.is_action_just_pressed("reload"):
		if _is_reloading:
			return
		_is_reloading = true
		get_tree().call_deferred("reload_current_scene")

func update_forces() -> void :
	var current_boids = get_children().filter(func(n): return n is Boid)
	
	for boid in current_boids:
		boid.has_cohesion = enable_cohesion
		boid.has_alignment = enable_alignment
		boid.has_separation = enable_separation
		

		
