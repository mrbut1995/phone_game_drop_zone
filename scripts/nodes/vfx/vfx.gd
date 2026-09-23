# VFX cơ sở (base visual effect) - dùng chung cho mọi WorldActor và cả VFX spawn rời.
# NGUYÊN TẮC: toàn bộ thông số hiển thị (SpriteFrames, animation, hành vi, z_index,
# modulate...) được khai báo TRONG SCENE. Script chỉ đảm nhiệm chạy / dừng hiệu ứng,
# KHÔNG set thông số node bằng code.
#   - Gắn vào actor: node "Vfx" khai báo sẵn trong world_actor.tscn; actor gọi play_vfx()
#   - Dùng rời (spawn tại vị trí): đặt auto_free = true rồi gọi play_at(pos)
class_name Vfx
extends Node2D

signal played
signal finished(vfx: Vfx)

@export var sprite_frames: SpriteFrames = null
@export var animation: StringName = &""
# Tự phát ngay khi scene vào tree (dùng cho VFX spawn rời)
@export var play_on_ready: bool = false
# Ẩn sau khi chạy xong (VFX gắn vào actor thì ẩn; VFX spawn rời thường để auto_free lo)
@export var hide_when_done: bool = true
# Tự huỷ node sau khi chạy xong (dùng cho VFX spawn rời)
@export var auto_free: bool = false
# Làm hiệu ứng đa dạng hơn mỗi lần phát
@export var randomize_rotation: bool = false
@export var randomize_scale: bool = false
@export var scale_range: Vector2 = Vector2(0.85, 1.15)

@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	_apply_config()
	if hide_when_done:
		hide()
	if play_on_ready:
		play()

# Đẩy cấu hình khai báo trên node Vfx xuống Sprite con (chỉ chạy 1 lần lúc ready)
func _apply_config() -> void:
	if sprite == null:
		return
	if sprite_frames != null:
		sprite.sprite_frames = sprite_frames
	if animation != &"":
		sprite.animation = animation

# Phát hiệu ứng tại chỗ (dùng khi VFX gắn trong actor)
func play() -> void:
	if sprite == null or sprite.sprite_frames == null or animation == &"":
		return
	if randomize_rotation:
		rotation = randf_range(-PI, PI)
	if randomize_scale:
		var s: float = randf_range(scale_range.x, scale_range.y)
		scale = Vector2(s, s)
	show()
	sprite.play(animation)
	played.emit()

# Phát hiệu ứng tại một vị trí trong world (dùng khi VFX spawn rời)
func play_at(world_pos: Vector2) -> void:
	global_position = world_pos
	play()

func stop() -> void:
	if sprite != null:
		sprite.stop()
	if hide_when_done:
		hide()

# Nối trực tiếp trong vfx.tscn: Sprite.animation_finished -> Vfx
func _on_sprite_animation_finished() -> void:
	finished.emit(self)
	if hide_when_done:
		hide()
	if auto_free:
		queue_free()
