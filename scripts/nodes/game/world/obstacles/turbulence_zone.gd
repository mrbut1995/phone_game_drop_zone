class_name TurbulenceZoneObstacle
extends Obstacle

var zone_size: Vector2 = Vector2(180.0, 130.0)
var vortex_centers: Array[Vector2] = [
	Vector2(-45.0, 0.0),
	Vector2(45.0, 0.0)
]

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.ZONE_MODIFIER
	zone_effect = ZoneEffect.TURBULENCE
	hitbox_type = HitboxType.RECTANGLE
	hitbox_rect = Rect2(-zone_size.x * 0.5, -zone_size.y * 0.5, zone_size.x, zone_size.y)
	zone_multiplier = 0.45 # Giảm hiệu lực tilt còn 45% theo GDD Section 12.4
	speed = 25.0
	auto_wrap_x = true

func on_setup(params: Dictionary) -> void:
	if params.has("size"):
		zone_size = params["size"]
		hitbox_rect = Rect2(-zone_size.x * 0.5, -zone_size.y * 0.5, zone_size.x, zone_size.y)
	if params.has("multiplier"):
		zone_multiplier = params["multiplier"]

func _draw() -> void:
	var half_w = zone_size.x * 0.5
	var half_h = zone_size.y * 0.5
	
	# 1. Nền vùng nhiễu động gió xoáy
	var bg_col = Color(0.3, 0.6, 0.7, 0.14 + sin(anim_time * 4.0) * 0.04)
	draw_rect(Rect2(-half_w, -half_h, zone_size.x, zone_size.y), bg_col, true)
	draw_rect(Rect2(-half_w, -half_h, zone_size.x, zone_size.y), Color(0.4, 0.7, 0.85, 0.35), false, 1.5)
	
	# 2. Hai vòng xoáy lốc chuyển động quay tròn (Vortices)
	for vc in vortex_centers:
		var spin_angle = anim_time * 6.0
		var spiral_pts: PackedVector2Array = PackedVector2Array()
		var rings = 18
		for i in range(rings):
			var r = (float(i) / float(rings)) * 32.0
			var a = spin_angle + float(i) * 0.4
			spiral_pts.append(vc + Vector2(cos(a) * r, sin(a) * (r * 0.6)))
			
		for i in range(spiral_pts.size() - 1):
			var alpha = (float(i) / float(rings)) * 0.8
			draw_line(spiral_pts[i], spiral_pts[i + 1], Color(0.85, 0.95, 1.0, alpha), 1.8)

func acting(delta: float) -> void:
	super.acting(delta)
