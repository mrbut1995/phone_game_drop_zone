# Controller UI chuyên dụng cho Game Scene (kế thừa BaseUIController).
# Toàn bộ node UI (HUD + Popup) được khai báo SẴN trong scenes/game.tscn dưới UI/HUD và UI/Popup,
# script này chỉ tham chiếu tới chúng qua unique name (%) và cập nhật dữ liệu.
# Các signal pressed nút bấm được nối trực tiếp trong game.tscn.
class_name GameUIController
extends BaseUIController

signal retry_pressed
signal next_level_pressed
signal mode_button_pressed(mode_idx: int)
signal force_drop_pressed

# --- HUD: top bar ---
@onready var lbl_mode_level: Label = %ModeLevelLabel
@onready var btn_mode: Button = %ModeButton
@onready var lbl_score: Label = %ScoreLabel
@onready var lbl_combo: Label = %ComboLabel
@onready var progress_score: ProgressBar = %ScoreProgress
@onready var lbl_troops: Label = %TroopsLabel

# --- HUD: countdown + gust banner ---
@onready var lbl_countdown: Label = %CountdownLabel
@onready var banner_gust: PanelContainer = %GustBanner
@onready var lbl_gust_text: Label = %GustLabel

# --- HUD: tilt & wind indicators ---
@onready var needle_tilt: ColorRect = %TiltNeedle
@onready var lbl_tilt_deg: Label = %TiltDegLabel
@onready var arrow_wind: Label = %WindLabel
@onready var wind_clock: WindClock = %WindClock if has_node("%WindClock") else null
@onready var lbl_coins: Label = %CoinsLabel if has_node("%CoinsLabel") else null

# --- HUD: debug telemetry ---
@onready var debug_panel: PanelContainer = %DebugPanel
@onready var lbl_debug_text: Label = %DebugLabel
var debug_visible: bool = false

# --- Popup: kết quả màn chơi + menu chọn chế độ ---
@onready var panel_result: PanelContainer = %ResultPanel
@onready var lbl_result_title: Label = %ResultTitle
@onready var lbl_result_details: Label = %ResultDetails
@onready var btn_result_action: Button = %NextLevelButton
@onready var btn_result_retry: Button = %RetryButton
@onready var mode_menu: PopupMenu = %ModeMenu

# =============================================================
# Cập nhật HUD (được gọi từ GameLogicController)
# =============================================================

func update_mode_and_level(mode: GameState.GameMode, level: BaseLevel) -> void:
	match mode:
		GameState.GameMode.CAMPAIGN:
			lbl_mode_level.text = "%s" % (level.level_name if level else "CHIẾN DỊCH")
		GameState.GameMode.ENDLESS:
			lbl_mode_level.text = "CHẾ ĐỘ VÔ TẬN (ENDLESS)"
		GameState.GameMode.PRACTICE:
			lbl_mode_level.text = "CHẾ ĐỘ TẬP LUYỆN (PRACTICE)"

func update_score(score: int, target: int, combo: int) -> void:
	if target > 0:
		lbl_score.text = "Điểm: %d / %d" % [score, target]
		progress_score.max_value = target
		progress_score.value = score
		progress_score.visible = true
	else:
		lbl_score.text = "Điểm: %d" % score
		progress_score.visible = false

	if combo > 1:
		lbl_combo.text = "COMBO x%d!" % combo
	else:
		lbl_combo.text = ""

func update_troop_count(current_idx: int, total: int) -> void:
	if total > 0:
		lbl_troops.text = "Lượt lính: %d / %d" % [current_idx, total]
	else:
		lbl_troops.text = "Lượt lính: #%d" % current_idx

func show_countdown(number: int, text: String = "") -> void:
	lbl_countdown.visible = true
	if text != "":
		lbl_countdown.text = text
	else:
		lbl_countdown.text = str(number)

func hide_countdown() -> void:
	lbl_countdown.visible = false

func update_tilt(raw_deg: float, normalized: float) -> void:
	lbl_tilt_deg.text = "%.1f°" % raw_deg
	# Range -35 đến +35 map sang vị trí 0 đến 180 (center = 90)
	var t_pos: float = (normalized + 1.0) * 0.5 * 180.0
	needle_tilt.position.x = clamp(t_pos - 4.0, 0.0, 172.0)

func update_wind(total_wind: float) -> void:
	if abs(total_wind) < 5.0:
		arrow_wind.text = "Gió: Lặng gió (0 px/s)"
	elif total_wind > 0:
		arrow_wind.text = "Gió: >>> Thổi sang phải (+%.0f px/s)" % total_wind
	else:
		arrow_wind.text = "Gió: <<< Thổi sang trái (%.0f px/s)" % total_wind

func update_wind_clock(total_w: float, predicted_w: float) -> void:
	if wind_clock != null:
		wind_clock.set_wind_data(total_w, predicted_w)

func update_coins(coin_count: int) -> void:
	if lbl_coins != null:
		lbl_coins.text = "🪙 %d" % coin_count

func show_gust_warning(dir: float, dur: float) -> void:
	banner_gust.visible = true
	var dir_str: String = "SANG PHẢI >>>" if dir > 0 else "<<< SANG TRÁI"
	lbl_gust_text.text = "⚠️ CẢNH BÁO GIÓ GIẬT %s!" % dir_str

	var tw = create_tween()
	tw.tween_interval(dur)
	tw.tween_callback(func(): banner_gust.visible = false)

func toggle_debug_overlay() -> void:
	debug_visible = not debug_visible
	debug_panel.visible = debug_visible

func update_debug_telemetry(raw_tilt: float, curved_tilt: float, force_x: float, vx: float, vy: float, alt_y: float) -> void:
	if debug_visible:
		lbl_debug_text.text = "FPS: %d\nRaw Tilt: %.1f°\nCurved: %.2f\nTotal Fx: %.0f px/s²\nVx: %.1f\nVy: %.1f\nAlt: %.0f px" % [
			Engine.get_frames_per_second(),
			raw_tilt,
			curved_tilt,
			force_x,
			vx,
			vy,
			840.0 - alt_y
		]

func show_victory(final_score: int, target_score: int) -> void:
	lbl_result_title.text = "🎉 CHIẾN THẮNG!"
	lbl_result_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	lbl_result_details.text = "Tổng điểm: %d / %d\nChúc mừng bạn đã xuất sắc vượt qua màn!" % [final_score, target_score]
	btn_result_action.visible = true
	btn_result_action.text = "Màn Kế Tiếp"
	_open_result_popup()

func show_defeat(final_score: int, target_score: int) -> void:
	lbl_result_title.text = "💔 THẤT BẠI!"
	lbl_result_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	lbl_result_details.text = "Tổng điểm: %d / %d\nChưa đủ điểm qua màn, hãy thử lại nhé!" % [final_score, target_score]
	btn_result_action.visible = false
	_open_result_popup()

# =============================================================
# Handler cho các node UI (nối trực tiếp trong scenes/game.tscn)
# =============================================================

func _on_mode_button_pressed() -> void:
	mode_menu.popup_centered()

func _on_mode_menu_id_pressed(mode_idx: int) -> void:
	mode_button_pressed.emit(mode_idx)

func _on_retry_button_pressed() -> void:
	_close_result_popup()
	retry_pressed.emit()

func _on_next_level_button_pressed() -> void:
	_close_result_popup()
	next_level_pressed.emit()

func _open_result_popup() -> void:
	if popup_ctrl != null:
		popup_ctrl.open_popup(panel_result)
	else:
		panel_result.visible = true

func _close_result_popup() -> void:
	if popup_ctrl != null:
		popup_ctrl.close_popup(panel_result)
	else:
		panel_result.visible = false
