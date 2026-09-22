class_name ShieldBubbleItem
extends Item

func _ready() -> void:
	item_type = ItemType.SHIELD
	super._ready()

func on_collected(troop: Troop) -> void:
	if troop != null:
		troop.grant_shield()

func _draw() -> void:
	var pulse = 1.0 + sin(anim_time * 5.0) * 0.08
	var r = 16.0 * pulse
	
	# 1. Hào quang xanh ngọc phát sáng
	var glow_col = Color(0.2, 0.85, 1.0, 0.25 + sin(anim_time * 4.0) * 0.1)
	draw_circle(Vector2.ZERO, r + 6.0, glow_col)
	
	# 2. Quả cầu bong bóng năng lượng
	var bubble_col = Color(0.3, 0.9, 1.0, 0.45)
	draw_circle(Vector2.ZERO, r, bubble_col)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(0.7, 0.98, 1.0, 0.9), 2.0)
	
	# Điểm phản quang bong bóng
	draw_circle(Vector2(-5, -6), 3.0, Color(1.0, 1.0, 1.0, 0.75))
	
	# 3. Biểu tượng khiên nhỏ ở giữa
	var shield_pts: PackedVector2Array = PackedVector2Array([
		Vector2(-6.0, -7.0),
		Vector2(6.0, -7.0),
		Vector2(6.0, 0.0),
		Vector2(0.0, 8.0),
		Vector2(-6.0, 0.0)
	])
	draw_colored_polygon(shield_pts, Color(1.0, 1.0, 1.0, 0.9))
	draw_polyline(shield_pts, Color(0.2, 0.7, 0.9, 1.0), 1.5)
