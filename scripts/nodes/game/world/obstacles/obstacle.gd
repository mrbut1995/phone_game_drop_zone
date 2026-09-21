# Chướng ngại vật cơ sở (Base Obstacle)
# Phục vụ toàn bộ các nhóm obstacle trong GDD Section 6 & Section 5:
# - Trên không (di chuyển): chim, máy bay, đàn chim, khinh khí cầu, UFO
# - Bắn từ dưới lên: rocket, pháo hoa (có warning indicator)
# - Tĩnh / cấu trúc: dây điện, cần cẩu
# - Vùng đặc biệt: cột khí nóng (updraft), túi khí loãng (thin air), gió xoáy (turbulence)
class_name Obstacle
extends WorldActor

enum ObstacleCategory {
	LETHAL,         # Chạm là hỏng lượt bay (máy bay, chim, rocket, ufo...)
	ZONE_MODIFIER,  # Vùng ảnh hưởng vật lý liên tục (updraft, thin air, turbulence)
	STRUCTURAL      # Chướng ngại vật tĩnh hoặc bán tĩnh (dây điện, cần cẩu)
}

enum ZoneEffect {
	NONE,
	UPDRAFT,        # Cột khí nóng: đẩy lên giảm tốc độ rơi
	THIN_AIR,       # Túi khí loãng: rơi nhanh hơn
	TURBULENCE,     # Gió xoáy: giảm độ nhạy tilt của người chơi
	WIND_PUSH       # Đẩy ngang cục bộ
}

enum HitboxType {
	CIRCLE,         # Hitbox hình tròn tâm tại node
	RECTANGLE,      # Hitbox hình chữ nhật (AABB)
	LINE_SEGMENT,   # Hitbox dạng đoạn thẳng (cho dây điện, dầm cẩu)
	CUSTOM          # Con tự tính toán qua check_collision()
}

signal warning_started(world_pos: Vector2, dir: Vector2, duration: float)
signal warning_ended()

@export var obstacle_category: ObstacleCategory = ObstacleCategory.LETHAL
@export var zone_effect: ZoneEffect = ZoneEffect.NONE
@export var hitbox_type: HitboxType = HitboxType.CIRCLE

# Thông số di chuyển cơ bản
@export var speed: float = 80.0
@export var direction: float = 1.0 # 1.0: sang phải, -1.0: sang trái
@export var hitbox_radius: float = 18.0 # COLLISION_HITBOX_SCALE 0.75 theo GDD

# Hitbox mở rộng
@export var hitbox_rect: Rect2 = Rect2(-24.0, -24.0, 48.0, 48.0)
@export var segment_start: Vector2 = Vector2.ZERO
@export var segment_end: Vector2 = Vector2(100.0, 0.0)
@export var segment_thickness: float = 8.0

# Thông số vùng ảnh hưởng (Zone Modifier)
@export var zone_force: float = 0.0 # Lực đẩy (ví dụ Updraft đẩy ngược trọng lực px/s²)
@export var zone_multiplier: float = 1.0 # Hệ số nhân (ví dụ turbulence 0.4 - 0.6)

# Hệ thống cảnh báo xuất hiện (Warning Indicator - GDD 6: "tránh thua vì random")
@export var has_warning: bool = false
@export var warning_lead_time: float = 0.8 # Thời gian cảnh báo trước khi xuất hiện
var warning_timer: float = 0.0
var is_warning_active: bool = false
var is_ready_to_act: bool = true

# Giới hạn màn hình biên mặc định (540x960 portrait)
var bounds_left: float = -60.0
var bounds_right: float = 600.0
var bounds_top: float = -80.0
var bounds_bottom: float = 960.0
var auto_wrap_x: bool = true
var auto_despawn_offscreen: bool = false

var anim_time: float = 0.0

func _ready() -> void:
	z_index = 8
	if has_warning and warning_lead_time > 0.0:
		start_warning()
	queue_redraw()

# Khởi tạo linh hoạt bằng Dictionary
func setup(params: Dictionary) -> void:
	if params.has("speed"):
		speed = params["speed"]
	if params.has("direction"):
		direction = params["direction"]
	if params.has("position"):
		position = params["position"]
	if params.has("y_alt"):
		position.y = params["y_alt"]
	if params.has("hitbox_radius"):
		hitbox_radius = params["hitbox_radius"]
	if params.has("zone_force"):
		zone_force = params["zone_force"]
	if params.has("zone_multiplier"):
		zone_multiplier = params["zone_multiplier"]
	if params.has("has_warning"):
		has_warning = params["has_warning"]
	if params.has("warning_lead_time"):
		warning_lead_time = params["warning_lead_time"]
		
	on_setup(params)

# Hook ảo cho các lớp con tùy biến thêm sau setup
func on_setup(_params: Dictionary) -> void:
	pass

# Tương thích ngược với interface configure cũ
func configure(move_speed: float, move_dir: float, y_alt: float) -> void:
	speed = move_speed
	direction = move_dir
	position.y = y_alt
	if direction > 0:
		position.x = bounds_left
	else:
		position.x = bounds_right

func start_warning() -> void:
	is_warning_active = true
	is_ready_to_act = false
	warning_timer = warning_lead_time
	warning_started.emit(position, Vector2(direction, 0.0), warning_lead_time)

func _process(delta: float) -> void:
	if is_warning_active:
		warning_timer -= delta
		if warning_timer <= 0.0:
			is_warning_active = false
			is_ready_to_act = true
			warning_ended.emit()
		queue_redraw()
		return
		
	if is_ready_to_act:
		acting(delta)
	queue_redraw()

# Logic di chuyển mặc định theo trục ngang (có thể override ở scene con)
func acting(delta: float) -> void:
	anim_time += delta * 4.0
	position.x += speed * direction * delta
	
	if auto_wrap_x:
		if direction > 0 and position.x > bounds_right:
			position.x = bounds_left
		elif direction < 0 and position.x < bounds_left:
			position.x = bounds_right
	elif auto_despawn_offscreen:
		if (direction > 0 and position.x > bounds_right) or (direction < 0 and position.x < bounds_left):
			queue_free()

# Interface kiểm tra va chạm bao trọn các kiểu hình học (Shape check)
func check_collision(troop_pos: Vector2) -> bool:
	if is_warning_active or not is_ready_to_act:
		return false
		
	match hitbox_type:
		HitboxType.CIRCLE:
			# Hitbox tròn tâm tại position (scale 0.75 đã tích hợp trong hitbox_radius)
			return position.distance_to(troop_pos) <= hitbox_radius
		HitboxType.RECTANGLE:
			var world_rect = Rect2(position + hitbox_rect.position, hitbox_rect.size)
			return world_rect.has_point(troop_pos)
		HitboxType.LINE_SEGMENT:
			return _distance_to_segment(troop_pos, position + segment_start, position + segment_end) <= segment_thickness
		HitboxType.CUSTOM:
			return custom_collision_check(troop_pos)
			
	return false

func custom_collision_check(_troop_pos: Vector2) -> bool:
	return false

# Tác động vùng đặc biệt lên Troop (được gọi từ SpawnerController mỗi frame nếu overlap)
func apply_zone_effect(troop: Node, delta: float) -> void:
	if obstacle_category != ObstacleCategory.ZONE_MODIFIER:
		return
		
	match zone_effect:
		ZoneEffect.UPDRAFT:
			# Đẩy nhân vật lên tạm thời (giảm tốc độ rơi)
			if troop.has_method("apply_updraft_lift"):
				troop.apply_updraft_lift(zone_force, delta)
		ZoneEffect.THIN_AIR:
			# Túi khí loãng (rơi nhanh hơn do giảm lực cản)
			if troop.has_method("apply_thin_air_fall"):
				troop.apply_thin_air_fall(zone_multiplier, delta)
		ZoneEffect.TURBULENCE:
			# Gió xoáy (giảm hiệu lực tilt của người chơi theo GDD Section 12.4)
			if troop.has_method("apply_turbulence_damp"):
				troop.apply_turbulence_damp(zone_multiplier, delta)
		ZoneEffect.WIND_PUSH:
			# Gió đẩy ngang cục bộ
			if troop.has_method("apply_horizontal_push"):
				troop.apply_horizontal_push(zone_force * direction, delta)

# Tính khoảng cách từ điểm tới đoạn thẳng (cho HitboxType.LINE_SEGMENT)
func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ab_len_sq = ab.length_squared()
	if ab_len_sq == 0.0:
		return p.distance_to(a)
	var t = clamp((p - a).dot(ab) / ab_len_sq, 0.0, 1.0)
	var projection = a + t * ab
	return p.distance_to(projection)

# Reset trạng thái
func reset_obstacle() -> void:
	anim_time = 0.0
	warning_timer = 0.0
	is_warning_active = false
	is_ready_to_act = true
