class_name ThinAirZoneObstacle
extends Obstacle

var zone_size: Vector2 = Vector2(170.0, 130.0)
var streak_offsets: Array[Vector2] = []
var num_streaks: int = 12

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.ZONE_MODIFIER
	zone_effect = ZoneEffect.THIN_AIR
	hitbox_type = HitboxType.RECTANGLE
	hitbox_rect = Rect2(-zone_size.x * 0.5, -zone_size.y * 0.5, zone_size.x, zone_size.y)
	zone_multiplier = 1.5 # Gia tốc rơi tăng 50%
	speed = 15.0
	auto_wrap_x = true
	
	for i in range(num_streaks):
		streak_offsets.append(Vector2(
			randf_range(-zone_size.x * 0.45, zone_size.x * 0.45),
			randf_range(-zone_size.y * 0.45, zone_size.y * 0.45)
		))

func on_setup(params: Dictionary) -> void:
	if params.has("size"):
		zone_size = params["size"]
		hitbox_rect = Rect2(-zone_size.x * 0.5, -zone_size.y * 0.5, zone_size.x, zone_size.y)
	if params.has("multiplier"):
		zone_multiplier = params["multiplier"]

func _draw() -> void:
	var half_w = zone_size.x * 0.5
	var half_h = zone_size.y * 0.5
	
	# 1. Nền vùng khí loãng màu tím xanh
	var bg_col = Color(0.4, 0.2, 0.8, 0.12 + sin(anim_time * 2.5) * 0.03)
	draw_rect(Rect2(-half_w, -half_h, zone_size.x, zone_size.y), bg_col, true)
	draw_rect(Rect2(-half_w, -half_h, zone_size.x, zone_size.y), Color(0.5, 0.3, 0.9, 0.3), false, 1.5)
	
	# 2. Vệt gió rơi nhanh hướng xuống
	for offset in streak_offsets:
		var norm_y = (offset.y + half_h) / zone_size.y
		var alpha = sin(norm_y * PI) * 0.75
		var col = Color(0.7, 0.5, 1.0, alpha)
		# Vệt kẻ rơi thẳng xuống
		draw_line(offset, offset + Vector2(0, 10.0), col, 1.8)

func acting(delta: float) -> void:
	super.acting(delta)
	var half_h = zone_size.y * 0.5
	for i in range(streak_offsets.size()):
		streak_offsets[i].y += 85.0 * delta
		if streak_offsets[i].y > half_h:
			streak_offsets[i].y = -half_h
			streak_offsets[i].x = randf_range(-zone_size.x * 0.45, zone_size.x * 0.45)
