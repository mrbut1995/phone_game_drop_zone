# Nhân vật lính dù thả tự do (Drop Troop)
class_name Troop
extends WorldActor

signal landed(land_position: Vector2)
signal hit_obstacle(obstacle: Node2D)

# Các hằng số vật lý theo GDD Section 12
const GRAVITY: float = 800.0
const MAX_FALL_SPEED: float = 500.0
const MAX_HORIZONTAL_SPEED: float = 350.0
const BASE_DAMPING: float = 3.5
const MAX_DAMPING_MULTIPLIER: float = 1.8

# Biến trạng thái
var fall_time: float = 0.0
var total_fall_distance: float = 720.0
var start_y: float = 100.0
var ground_y: float = 820.0

var current_tilt_force: float = 0.0
var current_wind_force: float = 0.0
var has_landed: bool = false

# Biến tác động từ Vùng đặc biệt (Special Zones)
var zone_updraft_lift: float = 0.0
var zone_gravity_multiplier: float = 1.0
var zone_tilt_multiplier: float = 1.0
var zone_horizontal_push: float = 0.0

# Visual & trail
var trail_points: Array[Vector2] = []
var max_trail_points: int = 18
var scarf_angle: float = 0.0
var squash_stretch: Vector2 = Vector2.ONE
var is_squashing: bool = false
var squash_timer: float = 0.0

# Coyote time cho chướng ngại vật
var obstacle_overlap_timer: float = 0.0
var overlapping_obstacle: Node2D = null
const COYOTE_COLLISION_WINDOW: float = 0.08

func _ready() -> void:
	z_index = 10

func init_troop(drop_pos: Vector2, target_ground_y: float) -> void:
	position = drop_pos
	start_y = drop_pos.y
	ground_y = target_ground_y
	total_fall_distance = max(100.0, ground_y - start_y)
	velocity = Vector2.ZERO
	fall_time = 0.0
	has_landed = false
	is_active = false
	trail_points.clear()
	squash_stretch = Vector2.ONE
	is_squashing = false
	zone_updraft_lift = 0.0
	zone_gravity_multiplier = 1.0
	zone_tilt_multiplier = 1.0
	zone_horizontal_push = 0.0
	queue_redraw()

func start_drop() -> void:
	is_active = true
	has_landed = false
	fall_time = 0.0

func apply_forces(tilt_f: float, wind_f: float) -> void:
	current_tilt_force = tilt_f
	current_wind_force = wind_f

func apply_updraft_lift(lift_f: float, _delta: float) -> void:
	zone_updraft_lift = max(zone_updraft_lift, lift_f)

func apply_thin_air_fall(mult: float, _delta: float) -> void:
	zone_gravity_multiplier = max(zone_gravity_multiplier, mult)

func apply_turbulence_damp(mult: float, _delta: float) -> void:
	zone_tilt_multiplier = min(zone_tilt_multiplier, mult)

func apply_horizontal_push(push_f: float, _delta: float) -> void:
	zone_horizontal_push += push_f

func _physics_process(delta: float) -> void:
	if not is_active:
		if is_squashing:
			_process_squash(delta)
		return
		
	if has_landed:
		return

	fall_time += delta
	
	# 1. Rơi theo chiều dọc (Y-axis) có tính đến Easing 0.3s đầu và Zone effects (Updraft / Thin Air)
	var effective_gravity = GRAVITY * zone_gravity_multiplier - zone_updraft_lift
	if fall_time < 0.3:
		var t_ratio = fall_time / 0.3
		var ease_out = 1.0 - (1.0 - t_ratio) * (1.0 - t_ratio)
		velocity.y = max(0.0, effective_gravity * fall_time * ease_out)
	else:
		velocity.y += effective_gravity * delta
		
	var max_fall = MAX_FALL_SPEED * (1.3 if zone_gravity_multiplier > 1.0 else 1.0)
	velocity.y = clamp(velocity.y, 40.0, max_fall)
	
	# 2. Lực ngang tổng & Damping theo GDD 12.5 (kết hợp Turbulence & Wind Push)
	var effective_tilt = current_tilt_force * zone_tilt_multiplier
	var total_force_x: float = effective_tilt + current_wind_force + zone_horizontal_push
	
	# Damping tăng dần khi gần mặt đất (3.5 -> 6.3)
	var current_fall_progress: float = clamp((position.y - start_y) / total_fall_distance, 0.0, 1.0)
	var current_damping: float = lerp(BASE_DAMPING, BASE_DAMPING * MAX_DAMPING_MULTIPLIER, current_fall_progress)
	
	var target_vx: float = total_force_x
	var exp_factor: float = 1.0 - exp(-current_damping * delta)
	velocity.x += (target_vx - velocity.x) * exp_factor
	velocity.x = clamp(velocity.x, -MAX_HORIZONTAL_SPEED, MAX_HORIZONTAL_SPEED)
	
	# Cập nhật vị trí
	position += velocity * delta
	
	# Reset hiệu ứng zone cho frame kế tiếp (sẽ được cập nhật lại nếu vẫn ở trong zone)
	zone_updraft_lift = 0.0
	zone_gravity_multiplier = 1.0
	zone_tilt_multiplier = 1.0
	zone_horizontal_push = 0.0
	
	# Giới hạn biên màn hình trái/phải (540px)
	position.x = clamp(position.x, 25.0, 515.0)
	
	# Cập nhật vệt quỹ đạo (Trail)
	trail_points.push_front(position)
	if trail_points.size() > max_trail_points:
		trail_points.pop_back()
		
	# Góc bay của khăn quàng / dù phụ thuộc vào vận tốc ngang và gió
	var target_scarf: float = clamp((-velocity.x - current_wind_force * 0.3) * 0.15, -45.0, 45.0)
	scarf_angle = lerp_angle(scarf_angle, deg_to_rad(target_scarf), delta * 8.0)
	
	# Kiểm tra Coyote Collision với obstacle nếu có
	if overlapping_obstacle != null:
		obstacle_overlap_timer += delta
		if obstacle_overlap_timer >= COYOTE_COLLISION_WINDOW:
			hit_obstacle.emit(overlapping_obstacle)
			overlapping_obstacle = null
			
	# Kiểm tra chạm đất
	if position.y >= ground_y:
		position.y = ground_y
		_trigger_landing()
		
	queue_redraw()

func _trigger_landing() -> void:
	has_landed = true
	is_active = false
	velocity = Vector2.ZERO
	is_squashing = true
	squash_timer = 0.0
	landed.emit(position)

func _process_squash(delta: float) -> void:
	squash_timer += delta
	if squash_timer < 0.15:
		# Nén người xuống khi chạm đất
		var p: float = squash_timer / 0.15
		squash_stretch.x = lerp(1.0, 1.4, p)
		squash_stretch.y = lerp(1.0, 0.6, p)
	elif squash_timer < 0.4:
		# Nảy nhẹ lại hình dạng ban đầu
		var p: float = (squash_timer - 0.15) / 0.25
		squash_stretch.x = lerp(1.4, 1.0, p)
		squash_stretch.y = lerp(0.6, 1.0, p)
	else:
		squash_stretch = Vector2.ONE
		is_squashing = false
	queue_redraw()

func on_obstacle_entered(obstacle: Node2D) -> void:
	overlapping_obstacle = obstacle
	obstacle_overlap_timer = 0.0

func on_obstacle_exited(obstacle: Node2D) -> void:
	if overlapping_obstacle == obstacle:
		overlapping_obstacle = null
		obstacle_overlap_timer = 0.0

func _draw() -> void:
	# 1. Vẽ vệt quỹ đạo (Trail)
	if trail_points.size() > 1:
		for i in range(1, trail_points.size()):
			var local_p1: Vector2 = trail_points[i - 1] - position
			var local_p2: Vector2 = trail_points[i] - position
			var alpha: float = 1.0 - (float(i) / float(trail_points.size()))
			var col: Color = Color(0.3, 0.8, 1.0, alpha * 0.45)
			draw_line(local_p1, local_p2, col, max(1.0, 4.0 * (1.0 - float(i)/trail_points.size())))

	# Áp dụng squash stretch
	draw_set_transform(Vector2.ZERO, 0.0, squash_stretch)
	
	# 2. Vẽ Dù lượn nhỏ (Mini Parachute/Glider)
	if not has_landed:
		var chute_offset: Vector2 = Vector2(0, -28)
		# Dây dù
		draw_line(Vector2(-16, -26), Vector2(0, -10), Color(0.8, 0.8, 0.8, 0.8), 1.5)
		draw_line(Vector2(16, -26), Vector2(0, -10), Color(0.8, 0.8, 0.8, 0.8), 1.5)
		draw_line(Vector2(-6, -28), Vector2(0, -10), Color(0.8, 0.8, 0.8, 0.6), 1.2)
		draw_line(Vector2(6, -28), Vector2(0, -10), Color(0.8, 0.8, 0.8, 0.6), 1.2)
		
		# Vòm dù sọc màu nổi bật (Cam - Trắng - Xanh neon)
		var chute_curve_pts: PackedVector2Array = PackedVector2Array([
			Vector2(-22, -26),
			Vector2(-14, -40),
			Vector2(0, -44),
			Vector2(14, -40),
			Vector2(22, -26),
			Vector2(0, -24)
		])
		draw_colored_polygon(chute_curve_pts, Color(1.0, 0.45, 0.15, 0.95))
		
		# Sọc giữa màu trắng
		var mid_stripe: PackedVector2Array = PackedVector2Array([
			Vector2(-7, -26),
			Vector2(-5, -42),
			Vector2(5, -42),
			Vector2(7, -26),
			Vector2(0, -24)
		])
		draw_colored_polygon(mid_stripe, Color(1.0, 1.0, 1.0, 0.95))
		
	# 3. Khăn quàng bay theo gió (Wind Scarf)
	var scarf_tip: Vector2 = Vector2(sin(scarf_angle) * 16.0, 8.0 + cos(scarf_angle) * 4.0)
	draw_line(Vector2(0, -6), scarf_tip, Color(1.0, 0.85, 0.2, 0.9), 3.0)
	
	# 4. Thân nhân vật (Jumper Body)
	# Ba lô dù
	draw_rect(Rect2(-8, -12, 16, 14), Color(0.2, 0.35, 0.55), true)
	
	# Thân áo
	draw_circle(Vector2(0, 0), 10.0, Color(0.25, 0.65, 1.0))
	
	# Đầu & Mũ bảo hiểm (Helmet)
	draw_circle(Vector2(0, -12), 7.5, Color(1.0, 0.8, 0.2))
	# Kính bảo hộ (Goggles)
	draw_rect(Rect2(-5, -14, 10, 4), Color(0.1, 0.1, 0.1), true)
	draw_rect(Rect2(-4, -13, 3, 2), Color(0.4, 0.9, 1.0), true)
	draw_rect(Rect2(1, -13, 3, 2), Color(0.4, 0.9, 1.0), true)
	
	# Chân nhân vật
	draw_circle(Vector2(-4, 10), 3.5, Color(0.15, 0.2, 0.3))
	draw_circle(Vector2(4, 10), 3.5, Color(0.15, 0.2, 0.3))
	
	# Reset transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
