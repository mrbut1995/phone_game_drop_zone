class_name SfxController
extends Node

# Bộ phát âm thanh tự tạo (Procedural Audio Synth) để game luôn có âm thanh sinh động không sợ thiếu file
var player_pool: Array[AudioStreamPlayer] = []
var max_players: int = 6

func _ready() -> void:
	for i in range(max_players):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		player_pool.append(p)

func _get_available_player() -> AudioStreamPlayer:
	for p in player_pool:
		if not p.playing:
			return p
	return player_pool[0]

# Tạo âm thanh sin đơn giản (Sine wave beep) theo tần số và thời lượng
func _create_tone_stream(freq: float, duration: float, decay: bool = true) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var total_samples: int = int(sample_rate * duration)
	var byte_data = PackedByteArray()
	byte_data.resize(total_samples)
	
	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var env: float = 1.0
		if decay:
			env = max(0.0, 1.0 - (float(i) / float(total_samples)))
		var val: float = sin(t * freq * TAU) * env * 0.4
		var byte_val: int = int(clamp((val + 1.0) * 0.5 * 255.0, 0, 255))
		byte_data[i] = byte_val
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.data = byte_data
	return stream

func play_countdown_tick(is_final: bool = false) -> void:
	var player = _get_available_player()
	var freq: float = 880.0 if is_final else 520.0
	var dur: float = 0.22 if is_final else 0.12
	player.stream = _create_tone_stream(freq, dur)
	player.play()

func play_drop_swoosh() -> void:
	var player = _get_available_player()
	player.stream = _create_tone_stream(280.0, 0.35)
	player.play()

func play_bullseye() -> void:
	# Hợp âm chiến thắng (Chime)
	var player = _get_available_player()
	player.stream = _create_tone_stream(1046.5, 0.45) # Note C6
	player.play()
	
	var tw = create_tween()
	tw.tween_interval(0.1)
	tw.tween_callback(func():
		var p2 = _get_available_player()
		p2.stream = _create_tone_stream(1318.5, 0.5) # Note E6
		p2.play()
	)

func play_good_landing() -> void:
	var player = _get_available_player()
	player.stream = _create_tone_stream(659.25, 0.3)
	player.play()

func play_miss() -> void:
	var player = _get_available_player()
	player.stream = _create_tone_stream(140.0, 0.4)
	player.play()

func play_gust_alert() -> void:
	var player = _get_available_player()
	player.stream = _create_tone_stream(330.0, 0.2)
	player.play()
