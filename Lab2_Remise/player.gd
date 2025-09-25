extends CharacterBody2D

var bullet_scene : PackedScene = preload("res://bullet.tscn")
@export var shoot_cooldown: float = 0.2  # délai en secondes
var last_shot_time: float = -999.0       # temps du dernier tir

@export var accel: float = 1400.0     # accélération (px/s²)
@export var max_speed: float = 400.0  # vitesse max (px/s)
@export var decel: float = 1000.0     # décélération/friction (px/s²)
@export var edge_margin: float = 40.0 # marge pour ne pas sortir visuellement

@export var max_bullets: int = 10

@export var speed := 300.0  # vitesse horizontale en pixels/sec

func _ready():
	add_to_group("player")

func _physics_process(delta):
	var dir := Input.get_axis("move_left", "move_right")  

	if Input.is_action_pressed("shoot"):
		if (Time.get_ticks_msec() / 1000.0) - last_shot_time >= shoot_cooldown:
			shoot()
			last_shot_time = Time.get_ticks_msec() / 1000.0
		
	

	# accélération / décélération
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * max_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	velocity.y = 0.0
	move_and_slide()

	# stop aux limites de l'écran
	var w := get_viewport_rect().size.x
	global_position.x = clampf(global_position.x, edge_margin, w - edge_margin)

	# si on est collé au bord, annule la vitesse sortante
	if (global_position.x <= edge_margin and velocity.x < 0.0) \
	or (global_position.x >= w - edge_margin and velocity.x > 0.0):
		velocity.x = 0.0
	
func shoot():
	if get_tree().get_nodes_in_group("bullet").size() >= max_bullets:
		return
	
	var b = bullet_scene.instantiate()
	get_parent().add_child(b)
	b.global_transform = $Muzzle.global_transform
	b.get_node("Sprite2D").rotation_degrees = 90   
	#b.position = $Muzzle.position

func clamp_position():
	var screen_width = get_viewport_rect().size.x
	global_position.x = clamp(global_position.x, 0, screen_width)
