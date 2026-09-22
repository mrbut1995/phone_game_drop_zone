# Nhân vật lính dù thả tự do (Drop Troop)
class_name Troop
extends WorldActor

signal landed(land_position: Vector2)
signal hit_obstacle(obstacle: Node2D)
signal shield_granted
signal shield_broken

# Các hằng số vật lý theo GDD Section 12 & Update_Feature.md Section 4
const GRAVITY: float = 480.0
const MAX_FALL_SPEED: float = 300.0
const MAX_HORIZONTAL_SPEED: float = 350.0
const BASE_DAMPING: float = 3.5
const MAX_DAMPING_MULTIPLIER: float = 1.8
# SVG gốc được vẽ ở tỉ lệ 2x -> scale 0.5 để khớp kích thước thiết kế (30x38 px)
const SPRITE_SCALE: Vector2 = Vector2(0.5, 0.5)

# Bảng màu dù/khăn phân biệt các nhân vật theo thứ tự thả (Update_Feature.md 6.2)
const TROOP_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0),       # 0: Mặc định (Cam/Trắng)
	Color(0.35, 0.9, 1.0),      # 1: Xanh ngọc Cyan
	Color(1.0, 0.88, 0.25),     # 2: Vàng ánh kim
	Color(0.95, 0.45, 0.95),    # 3: Tím hồng
	Color(0.4, 1.0, 0.5)        # 4: Xanh lá mạ
]

# Tham chiếu node hiển thị (khai báo sẵn trong troop.tscn, không tạo runtime)
@onready var body_sprite: AnimatedSprite2D = $Sprite
@onready var parachute_sprite: Sprite2D = $Parachute
@onready var scarf_line: Line2D = $Scarf
@onready var trail_line: Line2D = $Trail

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

# Khiên bảo vệ Shield Bubble / Aegis (Update_Feature.md 1.2)
var has_shield: bool = false
var invulnerable_timer: float = 0.0

# Đánh dấu nhân vật gần chạm đất nhất (Update_Feature.md 3.2)
var is_lead_troop: bool = false
var troop_color_index: int = 0
var anim_pulse_time: float = 0.0

# Visual & trail
var trail_points: Array[Vector2] = []
var max_trail_points: int = 18
var scarf_angle: float = 0.0
var squash_stretch: Vector2 = Vector2.ONE
var is_squashing: bool = false
var squash_timer: float = 0.0

# Va chạm chướng ngại vật (tính NGAY khi overlap, không có thời gian trễ)
var overlapping_obstacle: Node2D = null

# Trạng thái bị hạ gục sau va chạm: rơi tự do + xoay tròn (không nhận input nữa)
var is_knocked_out: bool = false
var knockout_spin: float = 0.0
const KNOCKOUT_GRAVITY_SCALE: float = 0.85

func _ready() -> void:
	z_index = 10
	_sync_visuals()

func init_troop(drop_pos: Vector2, target_ground_y: float, color_idx: int = 0) -> void:
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
	is_knocked_out = false
	knockout_spin = 0.0
	overlapping_obstacle = null
	has_shield = false
	invulnerable_timer = 0.0
	is_lead_troop = false
	set_troop_color(color_idx)
	if body_sprite != null:
		body_sprite.rotation = 0.0
		body_sprite.modulate = Color.WHITE
	_sync_visuals()
	queue_redraw()

func set_troop_color(color_idx: int) -> void:
	troop_color_index = posmod(color_idx, TROOP_COLORS.size())
	var col = TROOP_COLORS[troop_color_index]
	if parachute_sprite != null:
		parachute_sprite.modulate = col
	if scarf_line != null:
		scarf_line.default_color = Color(col.r, col.g, col.b, 0.9)

func grant_shield() -> void:
	has_shield = true
	shield_granted.emit()
	queue_redraw()

func break_shield() -> void:
	has_shield = false
	invulnerable_timer = 0.6 # Miễn nhiễm va chạm 0.6s sau khi vỡ khiên
	shield_broken.emit()
	_flash_shield_break()
	queue_redraw()

func _flash_shield_break() -> void:
	if body_sprite != null:
		var tw := create_tween()
		tw.tween_property(body_sprite, "modulate", Color(0.2, 0.9, 1.0), 0.08)
		tw.tween_property(body_sprite, "modulate", Color.WHITE, 0.3)

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
	# Bị hạ gục: rơi tự do + xoay tròn tới khi chạm đất
	if is_knocked_out:
		_process_knockout(delta)
		return

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

	anim_pulse_time += delta
	if invulnerable_timer > 0.0:
		invulnerable_timer -= delta
	queue_redraw()

	# Kiểm tra chạm đất
	if position.y >= ground_y:
		position.y = ground_y
		_trigger_landing()

	_sync_visuals()

func _trigger_landing() -> void:
	has_landed = true
	is_active = false
	velocity = Vector2.ZERO
	is_squashing = true
	squash_timer = 0.0
	landed.emit(position)
	queue_redraw()

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
	_sync_visuals()

func on_obstacle_entered(obstacle: Node2D) -> void:
	# Va chạm được tính NGAY lập tức.
	if has_landed or is_knocked_out or invulnerable_timer > 0.0:
		return
		
	# Nếu có Shield Bubble -> Miễn 1 lần va chạm (Update_Feature.md 1.2)
	if has_shield:
		break_shield()
		return
		
	overlapping_obstacle = obstacle
	hit_obstacle.emit(obstacle)
	overlapping_obstacle = null

func on_obstacle_exited(obstacle: Node2D) -> void:
	if overlapping_obstacle == obstacle:
		overlapping_obstacle = null

# Bị chướng ngại vật hạ gục: ngừng nhận input, rơi tiếp và xoay tròn cho tới khi chạm đất
func apply_knockout() -> void:
	if is_knocked_out or has_landed:
		return
	is_knocked_out = true
	is_active = false
	current_tilt_force = 0.0
	current_wind_force = 0.0
	velocity.x *= 0.35
	knockout_spin = (1.0 if velocity.x >= 0.0 else -1.0) * randf_range(7.0, 11.0)
	_flash_hit()
	_sync_visuals()

func _process_knockout(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * KNOCKOUT_GRAVITY_SCALE * delta, MAX_FALL_SPEED * 1.1)
	velocity.x = move_toward(velocity.x, 0.0, 140.0 * delta)
	position += velocity * delta
	position.x = clampf(position.x, 25.0, 515.0)

	# Vệt quỹ đạo vẫn được vẽ để thấy đường rơi
	trail_points.push_front(position)
	if trail_points.size() > max_trail_points:
		trail_points.pop_back()

	if body_sprite != null:
		body_sprite.rotation += knockout_spin * delta

	if position.y >= ground_y:
		position.y = ground_y
		has_landed = true
		is_knocked_out = false

	_sync_visuals()

# Chớp đỏ khi trúng đòn (phản hồi trực quan rõ ràng)
func _flash_hit() -> void:
	if body_sprite != null:
		var tw := create_tween()
		tw.tween_property(body_sprite, "modulate", Color(1.0, 0.35, 0.3), 0.06)
		tw.tween_property(body_sprite, "modulate", Color.WHITE, 0.4)
	if parachute_sprite != null and parachute_sprite.visible:
		var tw2 := create_tween()
		tw2.tween_property(parachute_sprite, "modulate", Color(1.0, 0.4, 0.3), 0.06)
		tw2.tween_property(parachute_sprite, "modulate", Color.WHITE, 0.4)

func _sync_visuals() -> void:
	# 1. Vệt quỹ đạo (Trail) - Line2D với gradient mờ dần về đuôi
	if trail_line != null:
		var pts: PackedVector2Array = PackedVector2Array()
		for p in trail_points:
			pts.append(trail_line.to_local(p))
		trail_line.points = pts

	# 2. Khăn quàng bay theo gió (Wind Scarf)
	if scarf_line != null:
		var scarf_tip: Vector2 = Vector2(sin(scarf_angle) * 16.0, 8.0 + cos(scarf_angle) * 4.0)
		scarf_line.points = PackedVector2Array([Vector2.ZERO, scarf_tip])
		scarf_line.scale = squash_stretch

	# 3. Dù lượn: chỉ hiện khi đang thả dù (chưa tiếp đất và chưa bị hạ gục)
	if parachute_sprite != null:
		parachute_sprite.visible = not has_landed and not is_knocked_out
		parachute_sprite.scale = SPRITE_SCALE * squash_stretch

	# 4. Thân nhân vật: áp dụng hiệu ứng nén / giãn khi tiếp đất
	if body_sprite != null:
		body_sprite.scale = SPRITE_SCALE * squash_stretch

func _draw() -> void:
	# 1. Vẽ Vòng hào quang Lead Troop (Update_Feature.md 3.2: highlight nhân vật gần đất nhất)
	if is_lead_troop and not has_landed and not is_knocked_out:
		var pulse_scale = 1.0 + sin(anim_pulse_time * 6.0) * 0.12
		var ring_alpha = 0.55 + sin(anim_pulse_time * 6.0) * 0.25
		draw_arc(Vector2(0, 10.0), 16.0 * pulse_scale, 0.0, TAU, 24, Color(1.0, 0.85, 0.2, ring_alpha), 2.0)
		# Mũi tên chỉ thị nhỏ
		var arrow_y = -35.0 + sin(anim_pulse_time * 6.0) * 3.0
		var arrow_pts: PackedVector2Array = PackedVector2Array([
			Vector2(-4, arrow_y - 6),
			Vector2(4, arrow_y - 6),
			Vector2(0, arrow_y)
		])
		draw_colored_polygon(arrow_pts, Color(1.0, 0.85, 0.2, ring_alpha))

	# 2. Vẽ Bong bóng khiên Shield Bubble (Update_Feature.md 1.2)
	if has_shield and not has_landed and not is_knocked_out:
		var bubble_pulse = 1.0 + sin(anim_pulse_time * 4.0) * 0.06
		var bubble_radius = 24.0 * bubble_pulse
		var bubble_col = Color(0.25, 0.85, 1.0, 0.35 + sin(anim_pulse_time * 5.0) * 0.1)
		draw_circle(Vector2(0, -6.0), bubble_radius, bubble_col)
		draw_arc(Vector2(0, -6.0), bubble_radius, 0.0, TAU, 28, Color(0.6, 0.95, 1.0, 0.8), 2.0)
		# Điểm phản quang trên quả cầu khiên
		draw_circle(Vector2(-7.0, -14.0), 3.5, Color(1.0, 1.0, 1.0, 0.65))
