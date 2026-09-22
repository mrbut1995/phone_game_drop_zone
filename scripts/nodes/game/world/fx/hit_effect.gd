# Hiệu ứng nổ/va chạm khi Troop đụng chướng ngại vật.
# Scene hit_effect.tscn đã khai báo sẵn AnimatedSprite2D "Sprite"
# (hit_burst_frames.tres, animation "burst", loop = false) và tự huỷ khi animation xong
# (connection "animation_finished" khai báo trong hit_effect.tscn).
class_name HitEffect
extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite

# Đặt hiệu ứng vào vị trí va chạm, thêm chút ngẫu nhiên cho đỡ đơn điệu
func play_at(world_pos: Vector2) -> void:
	global_position = world_pos
	rotation = randf_range(-PI, PI)
	scale = Vector2.ONE * randf_range(0.85, 1.15)
	if sprite != null:
		sprite.play(&"burst")

func _on_sprite_animation_finished() -> void:
	queue_free()
