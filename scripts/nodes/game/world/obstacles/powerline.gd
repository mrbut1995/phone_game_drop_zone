class_name PowerlineObstacle
extends Obstacle

@export var line_width: float = 380.0
@export var sag_amount: float = 22.0

var spark_points: Array[Vector2] = []
var spark_timer: float = 0.0

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.STRUCTURAL
	hitbox_type = HitboxType.CUSTOM
	auto_wrap_x = false
	speed = 0.0 # Vật thể tĩnh

func on_setup(params: Dictionary) -> void:
	if params.has("line_width"):
		line_width = params["line_width"]
	if params.has("sag_amount"):
		sag_amount = params["sag_amount"]

func _get_wire_points() -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	var steps = 16
	var half_w = line_width * 0.5
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var x = lerp(-half_w, half_w, t)
		# Đường võng parabol của dây điện
		var norm_x = (x / half_w) # -1 to 1
		var y = (1.0 - norm_x * norm_x) * sag_amount
		pts.append(Vector2(x, y))
	return pts

# Kiểm tra khoảng cách tới từng đoạn cong của dây điện
func custom_collision_check(troop_pos: Vector2) -> bool:
	var pts = _get_wire_points()
	for i in range(pts.size() - 1):
		var p1 = position + pts[i]
		var p2 = position + pts[i + 1]
		if _distance_to_segment(troop_pos, p1, p2) <= 9.0:
			return true
	return false

func _draw() -> void:
	var half_w = line_width * 0.5
	var wire_pts = _get_wire_points()
	
	# 1. Cột điện 2 đầu
	# Cột trái
	draw_line(Vector2(-half_w, -15.0), Vector2(-half_w, 25.0), Color(0.3, 0.25, 0.2), 4.5)
	draw_line(Vector2(-half_w - 6.0, -10.0), Vector2(-half_w + 6.0, -10.0), Color(0.4, 0.35, 0.3), 3.0)
	draw_circle(Vector2(-half_w, -10.0), 3.0, Color(0.8, 0.8, 0.8)) # Sứ cách điện
	
	# Cột phải
	draw_line(Vector2(half_w, -15.0), Vector2(half_w, 25.0), Color(0.3, 0.25, 0.2), 4.5)
	draw_line(Vector2(half_w - 6.0, -10.0), Vector2(half_w + 6.0, -10.0), Color(0.4, 0.35, 0.3), 3.0)
	draw_circle(Vector2(half_w, -10.0), 3.0, Color(0.8, 0.8, 0.8)) # Sứ cách điện
	
	# 2. Dây điện cao thế
	for i in range(wire_pts.size() - 1):
		draw_line(wire_pts[i], wire_pts[i + 1], Color(0.15, 0.15, 0.18), 2.2)
		
	# 3. Tia lửa điện cao thế nhấp nháy dọc theo dây (Electric sparks)
	if spark_points.size() > 1:
		for i in range(spark_points.size() - 1):
			draw_line(spark_points[i], spark_points[i + 1], Color(0.4, 0.95, 1.0), 2.0)
			draw_circle(spark_points[i], 2.0, Color.WHITE)

func acting(delta: float) -> void:
	anim_time += delta
	spark_timer += delta
	
	# Tạo tia điện hồ quang ngẫu nhiên
	if spark_timer > 0.4:
		spark_timer = 0.0
		spark_points.clear()
		if randf() < 0.65:
			var pts = _get_wire_points()
			var idx = randi_range(1, pts.size() - 3)
			var base_pt = pts[idx]
			spark_points.append(base_pt)
			spark_points.append(base_pt + Vector2(randf_range(-8, 8), randf_range(-10, 10)))
			spark_points.append(pts[idx + 1] + Vector2(randf_range(-4, 4), randf_range(-6, 6)))
			spark_points.append(pts[idx + 1])
	elif spark_timer > 0.12:
		spark_points.clear()
