# Actor cơ sở (Base World Actor)
# Cung cấp sẵn 2 node cho mọi lớp con:
#   - Sprite    (AnimatedSprite2D): hiển thị hoạt ảnh, frame lấy từ resources/animations
#   - Collision (CollisionShape2D): hitbox vật lý, SpawnerController phát hiện va chạm
#     thông qua Area2D (WorldActor kế thừa Area2D) + Troop.get_overlapping_areas()
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
