# Chữ điểm nổi (floating score) - Update: KHÔNG còn tạo Label + set style bằng code.
# Scene floating_score.tscn khai báo sẵn: node "Label" (kích thước, canh giữa, LabelSettings
# thường/to), z_index, và 2 LabelSettings (size + outline) trong scene.
# Script chỉ nhận DỮ LIỆU gameplay (nội dung, màu, có nhấn mạnh hay không) rồi chạy hiệu ứng.
# Các thông số hiệu ứng đều là @export -> đặt được trong Inspector/scene, không hard-code.
class_name FloatingScore
extends Node2D

signal finished(score: FloatingScore)

# Style khai báo trong scene (LabelSettings) - script chỉ chọn cái phù hợp
@export var label_settings_normal: LabelSettings
@export var label_settings_big: LabelSettings
# Thông số hiệu ứng bay lên + mờ dần
@export var rise_distance: float = 70.0
@export var rise_duration: float = 1.2
@export var fade_delay: float = 0.4

@onready var label: Label = $Label

var _tween: Tween = null

func _ready() -> void:
	_apply_style(false)

# Hiện chữ tại vị trí trong world rồi tự chạy hiệu ứng và tự huỷ khi xong
func show_score(text: String, color: Color, big: bool, world_pos: Vector2) -> void:
	global_position = world_pos
	modulate = color # tô màu theo dữ liệu gameplay (style vẫn lấy từ scene)
	_apply_style(big)
	if label != null:
		label.text = text
	_play()

func _apply_style(big: bool) -> void:
	if label == null:
		return
	if big and label_settings_big != null:
		label.label_settings = label_settings_big
	elif label_settings_normal != null:
		label.label_settings = label_settings_normal

func _play() -> void:
	if label == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()

	# Reset về trạng thái đầu (giữ nguyên vị trí khai báo trong scene)
	label.modulate.a = 1.0
	var start_y: float = label.position.y

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(label, "position:y", start_y - rise_distance, rise_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(label, "modulate:a", 0.0, rise_duration).set_delay(fade_delay)
	_tween.chain().tween_callback(_on_finished)

func _on_finished() -> void:
	finished.emit(self)
	queue_free()
