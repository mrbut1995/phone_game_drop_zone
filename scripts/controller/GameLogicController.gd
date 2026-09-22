class_name GameLogicController
extends Node

signal game_started(mode: GameState.GameMode, level: BaseLevel)
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
@export var ui_ctrl: BaseUIController
@export var sfx_ctrl: SfxController
@export var spawner_ctrl: SpawnerController

# Model
var game_state: GameState

# Timers
var countdown_timer: float = 3.0
var is_counting_down: bool = false
var last_reported_sec: int = -1

# ============================================================
# Continuous Drop (Update_Feature.md Section 2): thả lính liên tục theo nhịp,
# nhiều nhân vật cùng tồn tại trên màn hình và cùng chịu 1 lực tilt toàn cục.
# ============================================================
const SPAWN_INTERVAL: float = 1.2          # thời gian giữa 2 lần thả liên tiếp
const MAX_CONCURRENT_TROOPS: int = 4       # số nhân vật tối đa cùng lúc trên màn hình
const SPAWN_ZIGZAG_OFFSET: float = 60.0    # lệch trái/phải xen kẽ để không chồng cột

var _spawn_budget: int = 0                 # số lính còn được thả (-1 = vô hạn: Endless/Practice)
var _spawned_count: int = 0
var _resolved_count: int = 0               # số lính đã kết thúc lượt (hạ cánh hoặc trúng đòn)
var _spawn_timer: float = 0.0
var _is_dropping: bool = false

func _ready() -> void:
	game_state = GameState.new()

# Toàn bộ signal giữa các Controller được kết nối trực tiếp trong game.tscn
# (tab "Node" -> "Signals" của từng Controller), KHÔNG nối trong code nữa.

func start_game(mode: GameState.GameMode = GameState.GameMode.CAMPAIGN) -> void:
	# LevelController instantiate Level scene -> phát "level_loaded" ->
	# WorldController dựng màn + cấu hình bia, SpawnerController sinh obstacle theo marker trong scene.
	var level: BaseLevel = level_ctrl.load_current_level()
	if level == null:
		push_error("GameLogicController: không load được màn chơi")
		return

	game_state.reset_for_new_game(mode, level)

	# Cấu hình gió theo dữ liệu khai báo trong màn (kèm biên độ gió giật riêng)
	wind_ctrl.configure_wind(
		level.base_wind_min,
		level.base_wind_max,
		level.gust_interval,
		level.gust_strength_min,
		level.gust_strength_max
	)

	ui_ctrl.update_mode_and_level(mode, level)
	ui_ctrl.update_score(game_state.current_score, game_state.target_score, game_state.combo_multiplier)
	ui_ctrl.update_troop_count(game_state.current_troop_index, game_state.total_troops)
	
	game_started.emit(mode, level)
	start_troop_round()

func start_troop_round() -> void:
	# Chuẩn bị màn: dọn lính cũ, reset camera rồi đếm ngược trước khi thả liên tục
	game_state.round_state = GameState.RoundState.COUNTDOWN
	world_ctrl.prepare_troop_for_drop()

	_spawn_budget = game_state.total_troops
	_spawned_count = 0
	_resolved_count = 0
	_spawn_timer = 0.0
	_is_dropping = false

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

	# 2. Giai đoạn thả liên tục (Falling phase)
	if game_state.round_state == GameState.RoundState.FALLING and _is_dropping:
		_update_continuous_spawn(delta)

		# Unified Tilt: áp lực tilt + gió cho TOÀN BỘ nhân vật đang rơi (kèm kiểm tra va chạm/nhặt item)
		var wind_at_alt = wind_ctrl.get_wind_at_altitude(world_ctrl.get_lead_y(), world_ctrl.ground_y)
		world_ctrl.update_troop_forces(input_ctrl.tilt_force, wind_at_alt, delta)

		# Telemetry theo nhân vật dẫn đầu (gần chạm đất nhất)
		var troop = world_ctrl.active_troop
		if troop != null and is_instance_valid(troop) and troop.is_active:
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
	# Người chơi bấm thả sớm: bỏ qua đếm ngược, hoặc thả ngay nhân vật kế tiếp
	if is_counting_down and game_state.round_state == GameState.RoundState.COUNTDOWN:
		_execute_drop()
	elif _is_dropping:
		_spawn_timer = 0.0

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

	# Không còn "thả 1 nhân vật": bật chế độ thả liên tục, nhân vật đầu tiên ra ngay frame này
	_is_dropping = true
	_spawn_timer = 0.0
	drop_started.emit()

# Nhịp thả nhân vật liên tục (Update_Feature.md 2.1)
func _update_continuous_spawn(delta: float) -> void:
	if _spawn_budget == 0:
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	# Đã đạt giới hạn số nhân vật cùng lúc -> hoãn spawn cho tới khi có người chạm đất
	if world_ctrl.get_airborne_count() >= MAX_CONCURRENT_TROOPS:
		return
	_spawn_troop()
	_spawn_timer = SPAWN_INTERVAL

# Thả 1 nhân vật với vị trí lệch xen kẽ (zigzag) để tránh chồng thẳng cột
func _spawn_troop() -> void:
	var offset_x: float = (SPAWN_ZIGZAG_OFFSET if _spawned_count % 2 == 0 else -SPAWN_ZIGZAG_OFFSET)
	var spawn_x: float = clampf(270.0 + offset_x + randf_range(-20.0, 20.0), 60.0, 480.0)

	var troop: Troop = world_ctrl.spawn_continuous_troop(spawn_x, _spawned_count)
	if troop == null:
		return

	_spawned_count += 1
	if _spawn_budget > 0:
		_spawn_budget -= 1
	game_state.next_troop()
	ui_ctrl.update_troop_count(game_state.current_troop_index, game_state.total_troops)

# Một nhân vật kết thúc lượt (hạ cánh / trúng đòn) -> kiểm tra kết thúc màn
func _on_troop_resolved() -> void:
	_resolved_count += 1
	if _spawn_budget == 0 and _resolved_count >= _spawned_count:
		_evaluate_game_completion()

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

# Một nhân vật tiếp đất (Continuous Drop: mỗi nhân vật tự được chấm điểm riêng)
func _on_world_troop_landed(troop: Troop, land_pos: Vector2) -> void:
	if troop == null:
		return
	if game_state.round_state in [GameState.RoundState.VICTORY, GameState.RoundState.GAME_OVER]:
		return

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
	_on_troop_resolved()

func _on_world_troop_hit_obstacle(troop: Troop, obs: Node2D) -> void:
	if troop == null:
		return

	# GDD Section 6: Va chạm vật cản nguy hiểm -> thất bại RIÊNG nhân vật này (các nhân vật khác vẫn rơi tiếp)
	var hit_pos: Vector2 = troop.position

	# Lính bị hạ gục: chớp đỏ, xoay tròn và rơi tiếp xuống đất (không đứng im giữa không trung)
	troop.apply_knockout()

	# Phản hồi va chạm: hiệu ứng nổ tại điểm chạm + rung camera
	world_ctrl.play_hit_feedback(hit_pos)
		
	# Tính 0 điểm cho lượt này và reset combo
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
		sfx_ctrl.play_hit_impact()
		
	ui_ctrl.update_score(game_state.current_score, game_state.target_score, game_state.combo_multiplier)
	troop_landed_evaluated.emit(fail_eval)
	_on_troop_resolved()

# Khiên bảo vệ đỡ 1 va chạm rồi vỡ (Update_Feature.md 1.2)
func _on_world_troop_shield_broken(troop: Troop) -> void:
	if troop == null:
		return
	world_ctrl.spawn_floating_score({
		"text": "🛡 KHIÊN ĐỠ ĐƠN!",
		"points": 0,
		"color": Color(0.45, 0.9, 1.0)
	}, troop.position)
	if sfx_ctrl:
		sfx_ctrl.play_shield_break()

# Nhặt vật phẩm: Coin / Shield Bubble / Backup Chute (Update_Feature.md Section 1)
func _on_item_collected(item_type: Item.ItemType, troop: Troop, world_pos: Vector2) -> void:
	match item_type:
		Item.ItemType.COIN:
			game_state.add_coins(1)
			ui_ctrl.update_coins(game_state.coins)
			world_ctrl.spawn_floating_score({"text": "+1 🪙", "points": 0, "color": Color(1.0, 0.85, 0.25)}, world_pos)
			if sfx_ctrl:
				sfx_ctrl.play_coin_pickup()
		Item.ItemType.SHIELD:
			world_ctrl.spawn_floating_score({"text": "🛡 KHIÊN BẢO VỆ!", "points": 0, "color": Color(0.45, 0.9, 1.0)}, world_pos)
			if sfx_ctrl:
				sfx_ctrl.play_powerup()
		Item.ItemType.REINFORCEMENT:
			game_state.add_reinforcement(1)
			if _spawn_budget > 0:
				_spawn_budget += 1
			ui_ctrl.update_troop_count(game_state.current_troop_index, game_state.total_troops)
			world_ctrl.spawn_floating_score({"text": "+1 LÍNH CỨU VIỆN!", "points": 0, "color": Color(0.45, 1.0, 0.5)}, world_pos)
			if sfx_ctrl:
				sfx_ctrl.play_powerup()

# Đồng hồ gió (Update_Feature.md Section 5): kim chính + kim dự báo
func _on_wind_clock_updated(current_wind: float, predicted_wind: float) -> void:
	ui_ctrl.update_wind_clock(current_wind, predicted_wind)

func _evaluate_game_completion() -> void:
	_is_dropping = false
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
		# Chế độ Endless / Practice: không giới hạn lượt lính nên không bao giờ "hết lượt"
		pass

func restart_current_level() -> void:
	start_game(game_state.game_mode)

func advance_to_next_level() -> void:
	# next_level() chỉ đổi chỉ số màn; start_game() sẽ load Level scene tương ứng của màn mới
	level_ctrl.next_level()
	start_game(GameState.GameMode.CAMPAIGN)

func switch_game_mode(mode_idx: int) -> void:
	var mode = GameState.GameMode.CAMPAIGN
	match mode_idx:
		0: mode = GameState.GameMode.CAMPAIGN
		1: mode = GameState.GameMode.ENDLESS
		2: mode = GameState.GameMode.PRACTICE
	start_game(mode)
