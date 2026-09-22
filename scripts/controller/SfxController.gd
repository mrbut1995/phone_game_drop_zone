class_name SfxController
extends Node

# ============================================================
# SFX placeholder: các file .wav trong "assets/sfx/" (đã sinh sẵn, nghe được ngay).
# Muốn đổi sang âm thanh thật: kéo file mới vào từng ô export dưới đây trong
# Inspector của node SfxController, hoặc thay trực tiếp file .wav cùng tên.
# KHÔNG còn sinh tone bằng code lúc chạy.
# ============================================================
@export var sfx_countdown_tick: AudioStream = preload("res://assets/sfx/countdown_tick.wav")
@export var sfx_countdown_go: AudioStream = preload("res://assets/sfx/countdown_go.wav")
@export var sfx_drop_swoosh: AudioStream = preload("res://assets/sfx/drop_swoosh.wav")
@export var sfx_bullseye: AudioStream = preload("res://assets/sfx/bullseye.wav")
@export var sfx_good_landing: AudioStream = preload("res://assets/sfx/good_landing.wav")
@export var sfx_miss: AudioStream = preload("res://assets/sfx/miss.wav")
@export var sfx_gust_alert: AudioStream = preload("res://assets/sfx/gust_alert.wav")
@export var sfx_hit_impact: AudioStream = preload("res://assets/sfx/hit_impact.wav")

# Biến thiên pitch nhẹ để tiếng lặp lại (countdown, miss) không bị khô
@export var pitch_variation: float = 0.04

# Bộ phát âm thanh: 6 AudioStreamPlayer (Player1..Player6) được khai báo sẵn trong scene base.tscn
var player_pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for child in get_children():
		var p := child as AudioStreamPlayer
		if p != null:
			player_pool.append(p)
	if player_pool.is_empty():
		push_warning("SfxController: chưa có AudioStreamPlayer nào trong scene")

func _get_available_player() -> AudioStreamPlayer:
	for p in player_pool:
		if not p.playing:
			return p
	return player_pool[0]

# Phát một AudioStream qua pool, kèm biến thiên pitch nhẹ nếu cần
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_jitter: bool = false) -> void:
	if stream == null or player_pool.is_empty():
		return
	var p := _get_available_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + (randf_range(-pitch_variation, pitch_variation) if pitch_jitter else 0.0)
	p.play()

# ============================================================
# API tiện dụng cho GameLogicController
# ============================================================

func play_countdown_tick(is_final: bool = false) -> void:
	play_sfx(sfx_countdown_go if is_final else sfx_countdown_tick, 0.0, true)

func play_drop_swoosh() -> void:
	play_sfx(sfx_drop_swoosh)

func play_bullseye() -> void:
	play_sfx(sfx_bullseye)

func play_good_landing() -> void:
	play_sfx(sfx_good_landing)

func play_miss() -> void:
	play_sfx(sfx_miss, 0.0, true)

func play_gust_alert() -> void:
	play_sfx(sfx_gust_alert, 1.0)

func play_hit_impact() -> void:
	play_sfx(sfx_hit_impact, 1.0, true)
