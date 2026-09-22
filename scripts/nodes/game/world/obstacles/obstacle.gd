# Chướng ngại vật cơ sở (Base Obstacle)
# Kế thừa WorldActor nên mọi lớp con đều dùng chung:
#   - Sprite (AnimatedSprite2D): animation khai báo trong file .tscn của từng loại
#   - Collision (CollisionShape2D) + các CollisionShape2D phụ: hitbox vật lý
# Va chạm KHÔNG còn tính bằng toán học trong code: SpawnerController lấy
# Troop.get_overlapping_areas() (physics overlap giữa các Area2D) để xử lý.
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

signal warning_started(world_pos: Vector2, dir: Vector2, duration: float)
signal warning_ended()

@export var obstacle_category: ObstacleCategory = ObstacleCategory.LETHAL
@export var zone_effect: ZoneEffect = ZoneEffect.NONE

# Thông số di chuyển cơ bản
@export var speed: float = 80.0
@export var direction: float = 1.0 # 1.0: sang phải, -1.0: sang trái

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
	_apply_facing()
	if has_warning and warning_lead_time > 0.0:
		start_warning()

# Khởi tạo linh hoạt bằng Dictionary (chỉ là dữ liệu level truyền vào, không tạo node)
func setup(params: Dictionary) -> void:
	if params.has("speed"):
		speed = params["speed"]
	if params.has("direction"):
		direction = params["direction"]
	if params.has("position"):
		position = params["position"]
	if params.has("y_alt"):
		position.y = params["y_alt"]
	if params.has("zone_force"):
		zone_force = params["zone_force"]
	if params.has("zone_multiplier"):
		zone_multiplier = params["zone_multiplier"]
	if params.has("has_warning"):
		has_warning = params["has_warning"]
	if params.has("warning_lead_time"):
		warning_lead_time = params["warning_lead_time"]

	_apply_facing()
	on_setup(params)

# Hook ảo cho các lớp con tùy biến thêm sau setup
func on_setup(_params: Dictionary) -> void:
	pass

# Hook khi hết giai đoạn cảnh báo (lớp con có thể đổi animation, ví dụ rocket -> "launch")
func on_warning_finished() -> void:
	pass

# Lật hướng hiển thị + va chạm theo hướng di chuyển (scale.x = -1 khi đi sang trái)
func _apply_facing() -> void:
	scale.x = 1.0 if direction >= 0.0 else -1.0

func start_warning() -> void:
	is_warning_active = true
	is_ready_to_act = false
	warning_timer = warning_lead_time
	set_collision_enabled(false)
	warning_started.emit(position, Vector2(direction, 0.0), warning_lead_time)

func _process(delta: float) -> void:
	if is_warning_active:
		warning_timer -= delta
		if warning_timer <= 0.0:
			is_warning_active = false
			is_ready_to_act = true
			set_collision_enabled(true)
			on_warning_finished()
			warning_ended.emit()
		return

	if is_ready_to_act:
		acting(delta)

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
