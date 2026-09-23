# Actor cơ sở (Base World Actor)
# Cung cấp sẵn 3 node cho mọi lớp con:
#   - Sprite    (AnimatedSprite2D): hiển thị hoạt ảnh, frame lấy từ resources/animations
#   - Collision (CollisionShape2D): hitbox vật lý, SpawnerController phát hiện va chạm
#     thông qua Area2D (WorldActor kế thừa Area2D) + Troop.get_overlapping_areas()
#   - Vfx       (nodes/vfx/vfx.tscn): hiệu ứng dùng chung, mỗi actor scene tự khai báo
#     SpriteFrames/animation cho Vfx này (xem troop.tscn) - actor chỉ gọi play_vfx()
class_name WorldActor
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var is_active: bool = false

func reset_actor() -> void:
	velocity = Vector2.ZERO
	is_active = false

func acting(_delta: float) -> void:
	pass

# Node hiển thị chính (null nếu scene con chưa khai báo)
func get_sprite() -> AnimatedSprite2D:
	return get_node_or_null("Sprite") as AnimatedSprite2D

# Node va chạm chính (null nếu scene con chưa khai báo)
func get_collision() -> CollisionShape2D:
	return get_node_or_null("Collision") as CollisionShape2D

# Bật/tắt khả năng được phát hiện va chạm (Area2D khác chỉ thấy actor khi monitorable = true)
func set_collision_enabled(enabled: bool) -> void:
	monitorable = enabled

# Phát animation có sẵn trên Sprite (bỏ qua an toàn nếu thiếu Sprite/anim)
func play_animation(anim: StringName) -> void:
	var sprite := get_sprite()
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)

# ============================================================
# VFX dùng chung (khai báo sẵn trong world_actor.tscn, thông số đặt trong scene)
# ============================================================

# Node VFX của actor (null nếu scene con chưa khai báo)
func get_vfx() -> Vfx:
	return get_node_or_null("Vfx") as Vfx

# Phát VFX của actor tại chính vị trí actor (animation/frame do scene khai báo)
func play_vfx() -> void:
	var vfx := get_vfx()
	if vfx != null:
		vfx.play()

# Phát VFX của actor lệch một khoảng local (ví dụ trên đầu nhân vật)
func play_vfx_at_offset(local_offset: Vector2) -> void:
	var vfx := get_vfx()
	if vfx != null:
		vfx.position = local_offset
		vfx.play()

func stop_vfx() -> void:
	var vfx := get_vfx()
	if vfx != null:
		vfx.stop()
