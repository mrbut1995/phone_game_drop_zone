class_name CoinItem
extends Item

func _ready() -> void:
	item_type = ItemType.COIN
	super._ready()

func _draw() -> void:
	# Hiệu ứng xoay tròn 3D góc nhìn của đồng xu
	var spin_scale: float = cos(anim_time * 4.5)
	var coin_w: float = 12.0 * abs(spin_scale)
	var coin_h: float = 12.0
	
	# Vòng hào quang phát sáng nhẹ phía sau
	var pulse_glow = 0.15 + sin(anim_time * 6.0) * 0.08
	draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.85, 0.2, pulse_glow))
	
	# Viền ngoài đồng xu vàng đậm
	var rim_col = Color(0.9, 0.65, 0.1) if spin_scale >= 0 else Color(0.8, 0.55, 0.08)
	draw_ellipse_shape(Vector2.ZERO, coin_w + 1.5, coin_h + 1.5, rim_col)
	
	# Mặt trong đồng xu màu vàng sáng
	var face_col = Color(1.0, 0.88, 0.25) if spin_scale >= 0 else Color(0.95, 0.78, 0.18)
	draw_ellipse_shape(Vector2.ZERO, coin_w, coin_h, face_col)
	
	# Dấu hoa sao / ký hiệu $ lấp lánh ở giữa nếu đồng xu đang hướng mặt ra ngoài
	if abs(spin_scale) > 0.4:
		var symbol_w = 4.0 * abs(spin_scale)
		draw_rect(Rect2(-symbol_w * 0.5, -5.0, symbol_w, 10.0), Color(1.0, 1.0, 0.9, 0.8), true)

func draw_ellipse_shape(center: Vector2, rx: float, ry: float, col: Color) -> void:
	if rx <= 0.5:
		return
	var pts: PackedVector2Array = PackedVector2Array()
	var steps = 18
	for i in range(steps):
		var a = (float(i) / float(steps)) * TAU
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)
