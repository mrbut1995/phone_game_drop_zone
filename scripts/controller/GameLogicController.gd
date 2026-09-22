class_name GameLogicController
extends Node

signal game_started(mode: GameState.GameMode, level_data: LevelData)
signal countdown_ticked(remaining_sec: int)
signal drop_started
signal troop_landed_evaluated(result: Dictionary)
signal game_victory(final_score: int, target_score: int)
signal game_defeat(final_score: int, target_score: int)

# ============================================================
# Tham chiếu các Controller (gán trực tiếp trong game.tscn)
# ============================================================
@export var input_ctrl: InputController
@export var wind_ctrl: WindController
@export var level_ctrl: LevelController
@export var world_ctrl: WorldController
@export var ui_ctrl: UIController
@export var sfx_ctrl: SfxController
@export var spawner_ctrl: SpawnerController

# Model
var game_state: GameState

# Timers
var countdown_timer: float = 3.0
var is_counting_down: bool = false
var last_reported_sec: int = -1

func _ready() -> void:
	game_state = GameState.new()

# Toàn bộ signal giữa các Controller được kết nối trực tiếp trong game.tscn
# (tab "Node" -> "Signals" của từng Controller), KHÔNG nối trong code nữa.

func start_game(mode: GameState.GameMode = GameState.GameMode.CAMPAIGN) -> void:
	var level_data: LevelData = level_ctrl.get_current_level_data()
	game_state.reset_for_new_game(mode, level_data)
	
	# Cấu hình môi trường thế giới và gió
	world_ctrl.apply_level_config(level_data)
	wind_ctrl.configure_wind(level_data.base_wind_min, level_data.base_wind_max, level_data.gust_interval)
	
	ui_ctrl.update_mode_and_level(mode, level_data)
	ui_ctrl.update_score(game_state.current_score, game_state.target_score, game_state.combo_multiplier)
	ui_ctrl.update_troop_count(game_state.current_troop_index, game_state.total_troops)
	
	game_started.emit(mode, level_data)
	start_troop_round()

func start_troop_round() -> void:
	game_state.round_state = GameState.RoundState.COUNTDOWN
	world_ctrl.prepare_troop_for_drop()
	
	countdown_timer = 3.0
	is_counting_down = true
	last_reported_sec = -1
	ui_ctrl.show_countdown(3)
	if sfx_ctrl:
		sfx_ctrl.play_countdown_tick(false)

func _process(delta: float) -> void:
	# 1. Đếm ngược tự động thả (Auto-drop countdown theo GDD Section 2)
	if is_counting_down and game_state.round_state == GameState.RoundState.COUNTDOWN:
		countdown_timer -= delta
		var sec = int(ceil(countdown_timer))
		if sec != last_reported_sec and sec > 0:
			last_reported_sec = sec
			ui_ctrl.show_countdown(sec)
			countdown_ticked.emit(sec)
			if sfx_ctrl:
				sfx_ctrl.play_countdown_tick(false)
				
		if countdown_timer <= 0.0:
			_execute_drop()

	# 2. Đang trong giai đoạn rơi tự do (Falling phase)
	if game_state.round_state == GameState.RoundState.FALLING:
		var troop = world_ctrl.active_troop
		if troop and troop.is_active:
			# Áp dụng lực tilt và gió (kèm delta để kiểm tra tương tác obstacle & special zones)
			var wind_at_alt = wind_ctrl.get_wind_at_altitude(troop.position.y, world_ctrl.GROUND_Y)
			world_ctrl.update_troop_forces(input_ctrl.tilt_force, wind_at_alt, delta)
			
			# Cập nhật Telemetry
			ui_ctrl.update_debug_telemetry(
				input_ctrl.current_raw_angle,
				input_ctrl.normalized_tilt,
				input_ctrl.tilt_force + wind_at_alt,
				troop.velocity.x,
				troop.velocity.y,
				troop.position.y
			)

func force_drop_now() -> void:
	if is_counting_down and game_state.round_state == GameState.RoundState.COUNTDOWN:
		_execute_drop()

func _execute_drop() -> void:
	is_counting_down = false
	game_state.round_state = GameState.RoundState.FALLING
	ui_ctrl.show_countdown(0, "THẢ RƠI!")
	if sfx_ctrl:
		sfx_ctrl.play_countdown_tick(true)
		sfx_ctrl.play_drop_swoosh()
		
	var tw = create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func(): ui_ctrl.hide_countdown())
	
	world_ctrl.release_troop()
	drop_started.emit()

func _on_tilt_updated(raw_deg: float, normalized: float, force: float) -> void:
	ui_ctrl.update_tilt(raw_deg, normalized)

func _on_wind_updated(total_wind: float, _base: float, _gust: float) -> void:
	ui_ctrl.update_wind(total_wind)

func _on_gust_warning(dir: float, dur: float) -> void:
	ui_ctrl.show_gust_warning(dir, dur)
	if sfx_ctrl:
		sfx_ctrl.play_gust_alert()

func _on_debug_gust_requested() -> void:
	if wind_ctrl:
		wind_ctrl.trigger_manual_gust()

func _on_toggle_debug_requested() -> void:
	if ui_ctrl:
		ui_ctrl.toggle_debug_overlay()

func _on_world_troop_landed(land_pos: Vector2) -> void:
	if game_state.round_state != GameState.RoundState.FALLING:
		return
		
	game_state.round_state = GameState.RoundState.LANDED
	
	# Đánh giá điểm đáp từ TargetZone
	var landing_eval: Dictionary = world_ctrl.target_zone.evaluate_landing(land_pos.x)
	var points: int = landing_eval["points"]
	var ring_name: String = landing_eval["ring_name"]
	var dist: float = landing_eval["distance"]
	
	# Tính điểm và combo vào GameState
	var final_points = game_state.add_landing_score(points, dist, ring_name)
	landing_eval["final_points"] = final_points
	landing_eval["multiplier"] = game_state.combo_multiplier
	
	# Hiệu ứng nổi chữ điểm số tại vị trí chạm đất
	world_ctrl.spawn_floating_score(landing_eval, land_pos)
	
	# Âm thanh phản hồi
	if sfx_ctrl:
		if points >= 100:
			sfx_ctrl.play_bullseye()
		elif points >= 40:
			sfx_ctrl.play_good_landing()
		else:
			sfx_ctrl.play_miss()
			
	# Cập nhật UI
	ui_ctrl.update_score(game_state.current_score, game_state.target_score, game_state.combo_multiplier)
	troop_landed_evaluated.emit(landing_eval)
	
	# Chờ 1.4s để người chơi tận hưởng cú đáp, sau đó chuyển lượt hoặc kết thúc màn
	var tw = create_tween()
	tw.tween_interval(1.4)
	tw.tween_callback(_handle_round_transition)

func _on_world_troop_hit_obstacle(obs: Node2D) -> void:
	if game_state.round_state != GameState.RoundState.FALLING:
		return
		
	# GDD Section 6: Va chạm vật cản nguy hiểm -> Thất bại lượt / mất điểm
	game_state.round_state = GameState.RoundState.LANDED
	
	var troop = world_ctrl.active_troop
	var hit_pos = troop.position if troop else Vector2(270, 500)
	if troop:
		troop.is_active = false
		
	# Tính 0 điểm lượt này và reset combo
	var final_points = game_state.add_landing_score(0, 999.0, "VA CHẠM VẬT CẢN!")
	var fail_eval: Dictionary = {
		"points": 0,
		"ring_name": "VA CHẠM!",
		"distance": 999.0,
		"color": Color(1.0, 0.25, 0.25),
		"final_points": final_points,
		"multiplier": 1
	}
	
	world_ctrl.spawn_floating_score(fail_eval, hit_pos)
	
	if sfx_ctrl:
		sfx_ctrl.play_miss()
		
	ui_ctrl.update_score(game_state.current_score, game_state.target_score, game_state.combo_multiplier)
	troop_landed_evaluated.emit(fail_eval)
	
	var tw = create_tween()
	tw.tween_interval(1.3)
	tw.tween_callback(_handle_round_transition)

func _handle_round_transition() -> void:
	var has_next: bool = game_state.next_troop()
	ui_ctrl.update_troop_count(game_state.current_troop_index, game_state.total_troops)
	
	if has_next:
		start_troop_round()
	else:
		# Hết số lượt lính quy định trong màn
		_evaluate_game_completion()

func _evaluate_game_completion() -> void:
	if game_state.game_mode == GameState.GameMode.CAMPAIGN:
		if game_state.current_score >= game_state.target_score:
			game_state.round_state = GameState.RoundState.VICTORY
			ui_ctrl.show_victory(game_state.current_score, game_state.target_score)
			game_victory.emit(game_state.current_score, game_state.target_score)
		else:
			game_state.round_state = GameState.RoundState.GAME_OVER
			ui_ctrl.show_defeat(game_state.current_score, game_state.target_score)
			game_defeat.emit(game_state.current_score, game_state.target_score)
	else:
		# Chế độ Endless / Practice: tiếp tục chơi
		start_troop_round()

func restart_current_level() -> void:
	start_game(game_state.game_mode)

func advance_to_next_level() -> void:
	level_ctrl.next_level()
	start_game(GameState.GameMode.CAMPAIGN)

func switch_game_mode(mode_idx: int) -> void:
	var mode = GameState.GameMode.CAMPAIGN
	match mode_idx:
		0: mode = GameState.GameMode.CAMPAIGN
		1: mode = GameState.GameMode.ENDLESS
		2: mode = GameState.GameMode.PRACTICE
	start_game(mode)
