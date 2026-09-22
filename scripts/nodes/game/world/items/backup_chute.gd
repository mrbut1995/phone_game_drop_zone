class_name BackupChuteItem
extends Item

func _ready() -> void:
	item_type = ItemType.REINFORCEMENT
	super._ready()

func _draw() -> void:
	var pulse = 1.0 + sin(anim_time * 4.0) * 0.06
	
	# 1. Hào quang xanh lá cứu viện
	draw_circle(Vector2(0, 0), 20.0 * pulse, Color(0.2, 0.9, 0.4, 0.22))
	
	# 2. Vòm dù nhỏ (Mini parachute canopy)
	var chute_pts: PackedVector2Array = PackedVector2Array([
		Vector2(-14.0, -2.0),
		Vector2(-9.0, -14.0),
		Vector2(0.0, -18.0),
		Vector2(9.0, -14.0),
		Vector2(14.0, -2.0),
		Vector2(0.0, -1.0)
	])
	draw_colored_polygon(chute_pts, Color(0.95, 0.95, 1.0))
	draw_polyline(chute_pts, Color(0.2, 0.5, 0.9), 1.5)
	
	# Dây dù nối xuống
	draw_line(Vector2(-12.0, -2.0), Vector2(0.0, 7.0), Color(0.5, 0.6, 0.7), 1.2)
	draw_line(Vector2(12.0, -2.0), Vector2(0.0, 7.0), Color(0.5, 0.6, 0.7), 1.2)
	
	# 3. Biểu tượng dấu cộng "+" xanh neon (Thêm quân cứu viện)
	var plus_size: float = 6.0
	var plus_thick: float = 3.0
	draw_line(Vector2(0, 7.0 - plus_size), Vector2(0, 7.0 + plus_size), Color(0.2, 1.0, 0.4), plus_thick)
	draw_line(Vector2(-plus_size, 7.0), Vector2(plus_size, 7.0), Color(0.2, 1.0, 0.4), plus_thick)
	draw_circle(Vector2(0, 7.0), 1.5, Color.WHITE)
