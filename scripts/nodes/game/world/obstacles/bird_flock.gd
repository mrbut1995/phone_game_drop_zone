class_name BirdFlockObstacle
extends Obstacle

# Tọa độ tương đối của các chú chim trong đàn theo hình chữ V
var flock_offsets: Array[Vector2] = [
	Vector2(0.0, 0.0),       # Chim đầu đàn
	Vector2(-24.0, -14.0),   # Cánh trái 1
	Vector2(-48.0, -26.0),   # Cánh trái 2
	Vector2(-24.0, 14.0),    # Cánh phải 1
	Vector2(-48.0, 26.0)     # Cánh phải 2
]

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.LETHAL
	hitbox_type = HitboxType.CUSTOM
	speed = 95.0

# Kiểm tra va chạm với từng con chim trong đàn
func custom_collision_check(troop_pos: Vector2) -> bool:
	var facing: float = 1.0 if direction > 0 else -1.0
	for offset in flock_offsets:
		var bird_pos = position + Vector2(offset.x * facing, offset.y)
		if bird_pos.distance_to(troop_pos) <= 12.0:
			return true
	return false

func _draw() -> void:
	var facing: float = 1.0 if direction > 0 else -1.0
	
	for i in range(flock_offsets.size()):
		var offset = flock_offsets[i]
		var bird_center = Vector2(offset.x * facing, offset.y)
		
		# Nhịp đập cánh hơi lệch pha nhau một chút cho tự nhiên
		var flap_phase = anim_time * 7.0 + float(i) * 0.8
		var wing_y = sin(flap_phase) * 8.0
		
		# Thân chim nhỏ
		draw_circle(bird_center, 4.0, Color(0.25, 0.28, 0.35))
		
		# Mỏ chim
		var beak_pt = bird_center + Vector2(facing * 8.0, 0.0)
		draw_line(bird_center, beak_pt, Color(1.0, 0.75, 0.2), 2.0)
		
		# Đôi cánh
		draw_line(bird_center, bird_center + Vector2(-6.0 * facing, wing_y), Color(0.35, 0.4, 0.5), 2.0)
		draw_line(bird_center, bird_center + Vector2(6.0 * facing, wing_y), Color(0.35, 0.4, 0.5), 2.0)

func acting(delta: float) -> void:
	super.acting(delta)
	# Đàn chim hơi lượn sóng nhẹ nhàng
	position.y += sin(anim_time * 2.5) * 12.0 * delta
