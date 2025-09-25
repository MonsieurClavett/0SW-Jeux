extends Area2D

var speed = 750
@onready var vis: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready():
	add_to_group("bullet")
	vis.screen_exited.connect(queue_free)      # auto-détruit en sortant de l’écran


func _physics_process(delta):
	position += transform.x * speed * delta

func _on_Bullet_body_entered(body: Node2D):
	if body.is_in_group("mobs"):
		body.queue_free()
	queue_free()
	
