class_name GameState
extends Resource

enum GameMode {
	CAMPAIGN,
	ENDLESS,
	PRACTICE
}

enum RoundState {
	IDLE,
	COUNTDOWN,
	FALLING,
	LANDED,
	ROUND_END,
	GAME_OVER,
	VICTORY
}

signal state_changed(new_state: RoundState)
signal score_changed(current_score: int, target_score: int, combo: int)
signal troop_count_changed(current_index: int, total_troops: int)
signal mode_changed(new_mode: GameMode)

var game_mode: GameMode = GameMode.CAMPAIGN:
	set(value):
		game_mode = value
		mode_changed.emit(game_mode)

var round_state: RoundState = RoundState.IDLE:
	set(value):
		round_state = value
		state_changed.emit(round_state)

var current_score: int = 0
var target_score: int = 300
var combo_count: int = 0
var combo_multiplier: int = 1
var current_troop_index: int = 0
var total_troops: int = 5
var landing_history: Array[Dictionary] = []
var high_score: int = 0
var countdown_time_left: float = 3.0

func reset_for_new_game(mode: GameMode, level: BaseLevel = null) -> void:
	game_mode = mode
	current_score = 0
	combo_count = 0
	combo_multiplier = 1
	current_troop_index = 1
	landing_history.clear()
	
	if level != null:
		target_score = level.target_score
		total_troops = level.total_troops
	else:
		target_score = 300
		total_troops = 5
		
	if game_mode == GameMode.ENDLESS:
		total_troops = -1 # Không giới hạn
	elif game_mode == GameMode.PRACTICE:
		total_troops = -1
		target_score = 0
		
	score_changed.emit(current_score, target_score, combo_multiplier)
	troop_count_changed.emit(current_troop_index, total_troops)
	round_state = RoundState.IDLE

func add_landing_score(points: int, distance: float, ring_name: String) -> int:
	var final_points: int = points
	
	if points >= 70: # Điểm cao liên tiếp -> tăng combo
		combo_count += 1
		combo_multiplier = min(combo_count, 4)
		final_points = points * combo_multiplier
	elif points > 0:
		combo_count = 0
		combo_multiplier = 1
	else:
		combo_count = 0
		combo_multiplier = 1
		
	current_score += final_points
	if current_score > high_score:
		high_score = current_score
		
	landing_history.append({
		"troop_index": current_troop_index,
		"base_points": points,
		"multiplier": combo_multiplier,
		"final_points": final_points,
		"distance": distance,
		"ring_name": ring_name
	})
	
	score_changed.emit(current_score, target_score, combo_multiplier)
	return final_points

func next_troop() -> bool:
	current_troop_index += 1
	troop_count_changed.emit(current_troop_index, total_troops)
	if game_mode == GameMode.ENDLESS or game_mode == GameMode.PRACTICE:
		return true
	return current_troop_index <= total_troops
