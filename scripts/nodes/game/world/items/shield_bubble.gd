# Shield Bubble / Aegis - miễn 1 lần va chạm chướng ngại vật (Update_Feature.md 1.2).
# Hình ảnh: shield_bubble_spritesheet.svg -> shield_frames.tres (animation "pulse") trong shield_bubble.tscn.
class_name ShieldBubbleItem
extends Item

# Khi nhặt: cấp khiên cho nhân vật vừa chạm item
func on_collected(troop: Troop) -> void:
	if troop != null:
		troop.grant_shield()
