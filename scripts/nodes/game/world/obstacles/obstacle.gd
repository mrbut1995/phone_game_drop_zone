# Chướng ngại vật trên không (Moving Obstacle)
class_name Obstacle
extends Node2D

@export var speed: float = 80.0
@export var direction: float = 1.0 # 1.0: sang phải, -1.0: sang trái
@export var hitbox_radius: float = 18.0 # COLLISION_HITBOX_SCALE 0.75

var anim_time: float = 0.0

func _ready() -> void:
	z_index = 8
	queue_redraw()

func configure(move_speed: float, move_dir: float, y_alt: float) -> void:
	speed = move_speed
	direction = move_dir
	position.y = y_alt
	if direction > 0:
		position.x = -40.0
	else:
		position.x = 580.0

func _process(delta: float) -> void:
	anim_time += delta * 6.0
	position.x += speed * direction * delta
	
	# Xoay vòng màn hình
	if direction > 0 and position.x > 580.0:
		position.x = -40.0
	elif direction < 0 and position.x < -40.0:
		position.x = 580.0
		
	queue_redraw()

func check_collision(troop_pos: Vector2) -> bool:
	# Hitbox thật nhỏ hơn visual (Scale 0.75 theo GDD Section 12.6.1)
	var dist: float = position.distance_to(troop_pos)
	return dist <= hitbox_radius

func _draw() -> void:
	# Vẽ chim bay hoặc máy bay nhỏ
	var wing_flap: float = sin(anim_time) * 12.0
	
	# Thân chim
	draw_circle(Vector2.ZERO, 6.0, Color(0.2, 0.25, 0.35))
	
	# Mỏ vàng
	var beak_dir: float = 1.0 if direction > 0 else -1.0
	var beak_pts: PackedVector2Array = PackedVector2Array([
		Vector2(beak_dir * 5, -2),
		Vector2(beak_dir * 12, 0),
		Vector2(beak_dir * 5, 2)
	])
	draw_colored_polygon(beak_pts, Color(1.0, 0.7, 0.1))
	
	# Cánh chim đập theo nhịp
	draw_line(Vector2(-2, 0), Vector2(-12, wing_flap), Color(0.3, 0.4, 0.55), 2.5)
	draw_line(Vector2(2, 0), Vector2(12, wing_flap), Color(0.3, 0.4, 0.55), 2.5)
