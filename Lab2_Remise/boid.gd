extends Node2D

class_name Boid
@onready var hitbox: Area2D = $Hitbox

var max_neighbor : int = 7
@export_range(0.0, 1.0, 0.05) var bounce_restitution: float = 0.9  # 1.0 = rebond parfait, 0.0 = inélastique

# Paramètres de base du boid
var top_speed : float = 150.0   # Vitesse maximale du boid
var top_steer : float = 2       # Force de rotation maximale (limite de la direction)
var mass : float = 1.0          # Masse du boid
var r : float = 10.0            # Rayon du boid (utilisé pour le calcul des distances)

# Distances d'influence pour les comportements
var radius_separation : float = 5 * r   # Rayon d'évitement pour la séparation
var radius_alignment : float = 10 * r   # Rayon pour l'alignement
var radius_cohesion : float = 15 * r    # Rayon pour la cohésion

# Poids des forces appliquées, contrôlés par des glissières dans l'inspecteur
@export_range(1, 3, 0.25) var weight_separation : float = 2  # Importance de la séparation
@export_range(1, 3, 0.25) var weight_alignment : float = 1.0  # Importance de l'alignement
@export_range(1, 3, 0.25) var weight_cohesion : float = 1.0   # Importance de la cohésion

# Vecteurs principaux du boid (position, vitesse et accélération)
var location : Vector2 = Vector2()
var velocity : Vector2 = Vector2()
var acceleration : Vector2 = Vector2()

var has_cohesion : bool = true
var has_separation : bool = true
var has_alignment : bool = true

# Référence à l'élément Sprite (image) du boid
@onready var sprite = $Image

var debug : bool = false
var is_chosen : bool = false

# Fonction appelée au démarrage du boid
func _ready():
	randomize()
	# Initialiser la vitesse aléatoire du boid
	velocity = Vector2(randf_range(-top_speed, top_speed), randf_range(-top_speed, top_speed))
	velocity.limit_length(top_speed)  # Limiter la vitesse à top_speed
	
	var screen_size = get_viewport_rect().size
	location.x = randi_range(0, screen_size.x as int)
	location.y = randi_range(0, 50) # <-- Spawn dans une bande de 0 à 50 px de haut
	position = location
	# Connexion pour détecter les bullets
	hitbox.connect("area_entered", Callable(self, "_on_Hitbox_area_entered"))
	hitbox.connect("body_entered", Callable(self, "_on_Hitbox_body_entered"))


# Fonction appelée à chaque frame
func _process(delta):
	var boids = get_boid_siblings()  # Récupérer les autres boids dans la scène
	
	# Calculer et appliquer les forces de séparation, d'alignement et de cohésion
	
	# Appliquer les forces calculées
	if has_separation :
		var separation_force = separation(boids) * weight_separation
		apply_force(separation_force)
		
	if has_alignment :
		var alignment_force = alignment(boids) * weight_alignment
		apply_force(alignment_force)
		
	if has_cohesion :
		var cohesion_force = cohesion(boids) * weight_cohesion
		apply_force(cohesion_force)	

	# Mettre à jour la position du boid et gérer la limite de l'écran
	update_position(delta)
	wrap_around_screen()
	
	# Faire pivoter le sprite en fonction de la direction de la vitesse
	if velocity.length() > 0:
		rotation = velocity.angle()  # Faire tourner le boid en fonction de sa direction de mouvement
	
	queue_redraw()

func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet"):
		die()
	elif area.is_in_group("player"):
		area.queue_free()  # supprime le joueur
		die()              # supprime le boid aussi (facultatif)

func _on_Hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("bullet"):
		die()
	elif body.is_in_group("player"):
		body.queue_free()
		die()

func die() -> void:
	# Effets optionnels avant destruction (particules, son, etc.)
	queue_free()
  

func bounce_top_bottom():
	var screen_h = get_viewport_rect().size.y
	var top = r
	var bottom = screen_h - r

	# Collision haut
	if location.y < top:
		location.y = top
		velocity.y = abs(velocity.y) * bounce_restitution  # renvoie vers le bas

	# Collision bas
	elif location.y > bottom:
		location.y = bottom
		velocity.y = -abs(velocity.y) * bounce_restitution  # renvoie vers le haut


# Appliquer une force sur le boid
func apply_force(force: Vector2):
	acceleration += force / mass   # Appliquer la force en tenant compte de la masse

# Mettre à jour la position du boid
func update_position(delta):
	velocity += acceleration   # Mettre à jour la vitesse en fonction de l'accélération
	velocity = velocity.limit_length(top_speed)  # Limiter la vitesse à la valeur maximale
	location += velocity * delta  # Calculer la nouvelle position
	acceleration = Vector2()  # Réinitialiser l'accélération après application
	position = location  # Mettre à jour la position dans l'espace de la scène
	bounce_top_bottom()

# Empêcher le boid de sortir de l'écran (effet de wrap-around)
func wrap_around_screen():
	if location.x > get_viewport_rect().size.x:
		location.x = 0
	elif location.x < 0:
		location.x = get_viewport_rect().size.x

	if location.y > get_viewport_rect().size.y:
		location.y = 0
	elif location.y < 0:
		location.y = get_viewport_rect().size.y

# Calcul de la force de séparation (éviter les collisions avec d'autres boids)
func separation(boids: Array) -> Vector2:
	var steer : Vector2 = Vector2()
	var total : int = 0
	
	for other in boids:
		var distance = location.distance_to(other.position)
		if distance < radius_separation and other != self:
			var diff = location - other.position
			diff = diff.normalized() / distance  # Inverser la direction de la force d'évitement
			steer += diff
			total += 1 # Compter le nombre de boids voisins
			
		if total > max_neighbor - 1 :
			# Limiter le nombre de voisins pris en compte pour la séparation
			break

	if total > 0:
		steer /= total  # Moyenne de toutes les forces
		steer = steer.normalized() * top_speed - velocity  # Calcul du vecteur de direction
		steer = steer.limit_length(top_steer)  # Limiter la force de rotation
	return steer

# Calcul de la force d'alignement (se déplacer dans la même direction que les boids voisins)
func alignment(boids: Array) -> Vector2:
	var average_velocity = Vector2()
	var total = 0
	
	for other in boids:
		var distance = location.distance_to(other.position)
		if distance < radius_alignment and other != self:
			average_velocity += other.velocity  # Ajouter la vitesse des autres boids voisins
			total += 1
		if total > max_neighbor - 1 :
			break
	if total > 0:
		average_velocity /= total  # Moyenne des vitesses des boids voisins
		average_velocity = average_velocity.normalized() * top_speed
		var steer = average_velocity - velocity  # Calculer la force de direction pour s'aligner
		steer = steer.limit_length(top_steer)
		return steer
	return Vector2()

# Calcul de la force de cohésion (se rapprocher des autres boids)
func cohesion(boids: Array) -> Vector2:
	var average_position = Vector2()
	var total = 0

	for other in boids:
		var distance = location.distance_to(other.position)
		if distance < radius_cohesion and other != self:
			average_position += other.position  # Ajouter les positions des boids voisins
			total += 1
		if total > max_neighbor - 1 :
			break
	if total > 0:
		average_position /= total  # Moyenne des positions des boids voisins
		return seek(average_position)  # Chercher à se rapprocher du centre de la masse
	return Vector2()

# Chercher une position cible donnée
func seek(target: Vector2) -> Vector2:
	var desired = (target - location).normalized() * top_speed
	var steer = desired - velocity  # Calculer la force de direction vers la cible
	steer = steer.limit_length(top_steer)
	return steer

# Récupérer uniquement les boids dans la scène
func get_boid_siblings() -> Array:
	var boids = []
	for sibling in get_parent().get_children():
		if sibling is Boid:  # Vérifier que l'enfant est bien un boid
			boids.append(sibling)
	return boids	

func set_debug(val) -> void:
	debug = val
	if (debug) :
		sprite.modulate = Color(0.25, 0.25, 0.25)
	else :
		sprite.modulate = Color.WHITE
	
func _draw() -> void:
	if (is_chosen):
		if (has_separation):
			draw_circle(position - global_position, radius_separation, Color.RED, false)
			
		if (has_cohesion):
			draw_circle(position - global_position, radius_cohesion, Color.GREEN, false)
			
		if (has_alignment):
			draw_circle(position - global_position, radius_alignment, Color.YELLOW, false)
		
