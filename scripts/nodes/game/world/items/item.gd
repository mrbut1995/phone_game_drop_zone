class_name Item
extends WorldActor

enum ItemType {
	COIN,           # Tiền vàng (tiền tệ shop/progression)
	SHIELD,         # Khiên bảo vệ Shield Bubble / Aegis (miễn 1 lần va chạm)
	REINFORCEMENT   # Thêm 1 lính Backup Chute vào hàng chờ
}

signal collected(item: Item, item_type: ItemType, troop: Troop)

# item_type được khai báo riêng trong từng scene (coin.tscn / shield_bubble.tscn / backup_chute.tscn)
@export var item_type: ItemType = ItemType.COIN
@export var pickup_radius: float = 22.0 # Hitbox nhặt rộng hơn để dễ thu thập
# Nhấp nhô nhẹ cho item sống động (mỗi item lệch pha để không cùng nhịp)
@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 3.5
@export var bob_phase: float = 0.0

var base_y: float = 0.0
var bob_time: float = 0.0
var is_collected: bool = false

func _ready() -> void:
	z_index = 9
	base_y = position.y
	bob_time = bob_phase

func _process(delta: float) -> void:
	if is_collected:
		return
	bob_time += delta
	# Hiệu ứng nổi bồng bềnh lên xuống nhẹ (hình ảnh do Sprite/SpriteFrames đảm nhiệm)
	position.y = base_y + sin(bob_time * bob_speed) * bob_amplitude

func check_collection(troop_pos: Vector2) -> bool:
	if is_collected:
		return false
	return position.distance_to(troop_pos) <= pickup_radius

func collect(troop: Troop) -> void:
	if is_collected:
		return
	is_collected = true
	collected.emit(self, item_type, troop)
	on_collected(troop)
	
	# Hiệu ứng phóng to và mờ dần khi nhặt
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", scale * 1.5, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)

# Hook cho lớp con (ví dụ Shield Bubble cấp khiên cho lính)
func on_collected(_troop: Troop) -> void:
	pass
