extends Node2D

class_name BoidOptimized

var top_speed : float = 150.0
var top_steer : float = 1
var mass : float = 1.0
var r : float = 10.0 # Rayon du boid

var radius_separation : float = 5 * r
var radius_alignment : float = 10 * r
var radius_cohesion : float = 15 * r

var weight_separation : float = 1.5
var weight_alignment : float = 1.0
var weight_cohesion : float = 1.0

var location : Vector2 = Vector2()
var velocity : Vector2 = Vector2()
var acceleration : Vector2 = Vector2()

func _ready():
	randomize()
	# Initialisation aléatoire de la position et de la vitesse des boids
	velocity = Vector2(randf_range(-top_speed, top_speed), randf_range(-top_speed, top_speed))
	velocity.limit_length(top_speed)
	
	location.x = randi_range(0, get_viewport_rect().size.x)
	location.y = randi_range(0, get_viewport_rect().size.y)

func _PhysicsProcess(delta):
	var boids = get_parent().get_children()
	
	# Regroupement des forces de séparation, alignement et cohésion dans une seule boucle
	var separation_force = Vector2()
	var alignment_force = Vector2()
	var cohesion_force = Vector2()
	var total_count = 0

	for other in boids:
		if other != self:
			var distance = location.distance_to(other.position)

			if distance < radius_cohesion:
				# Calcul de la force de séparation
				if distance < radius_separation:
					var diff = (location - other.position).normalized() / distance
					separation_force += diff

				# Calcul de la force d'alignement
				if distance < radius_alignment:
					alignment_force += other.velocity

				# Calcul de la cohésion
				cohesion_force += other.position
				total_count += 1

	if total_count > 0:
		# Calcul final des forces moyennées
		separation_force = (separation_force / total_count).normalized() * top_speed - velocity
		separation_force = separation_force.limit_length(top_steer)
		
		alignment_force = (alignment_force / total_count).normalized() * top_speed - velocity
		alignment_force = alignment_force.limit_length(top_steer)
		
		cohesion_force = seek(cohesion_force / total_count)

		apply_force(separation_force * weight_separation)
		apply_force(alignment_force * weight_alignment)
		apply_force(cohesion_force * weight_cohesion)

	update_position(delta)
	wrap_around_screen()
	queue_redraw()

# Appliquer une force au boid
func apply_force(force: Vector2):
	acceleration += force / mass

# Mise à jour de la position du boid
func update_position(delta):
	velocity += acceleration
	velocity = velocity.limit_length(top_speed)
	location += velocity * delta
	acceleration = Vector2()  # Réinitialiser l'accélération après application
	position = location

# Garder les boids à l'intérieur de l'écran
func wrap_around_screen():
	if location.x > get_viewport_rect().size.x:
		location.x = 0
	elif location.x < 0:
		location.x = get_viewport_rect().size.x

	if location.y > get_viewport_rect().size.y:
		location.y = 0
	elif location.y < 0:
		location.y = get_viewport_rect().size.y

# Chercher une cible
func seek(target: Vector2) -> Vector2:
	var desired = (target - location).normalized() * top_speed
	var steer = desired - velocity
	steer = steer.limit_length(top_steer)
	return steer

# Dessine un boid sous forme de triangle pour indiquer sa direction
func _draw():
	var p1 = Vector2(r, 0).rotated(velocity.angle())
	var p2 = Vector2(-r, r / 2).rotated(velocity.angle())
	var p3 = Vector2(-r, -r / 2).rotated(velocity.angle())
	draw_polygon([p1, p2, p3], [Color(1, 1, 1)])
