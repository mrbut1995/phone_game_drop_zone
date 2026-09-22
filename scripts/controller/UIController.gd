class_name UIController
extends Node

signal retry_pressed
signal next_level_pressed
signal mode_button_pressed(mode_idx: int)
signal force_drop_pressed

# Gán trực tiếp trong game.tscn (UI/HUD và UI/Popup)
@export var hud_root: Control
@export var popup_root: Control

# Các UI Node tham chiếu
var lbl_mode_level: Label
var lbl_score: Label
var progress_score: ProgressBar
var lbl_troops: Label
var lbl_combo: Label

var lbl_countdown: Label
var banner_gust: PanelContainer
var lbl_gust_text: Label

# Đồng hồ nghiêng và gió
var panel_indicators: PanelContainer
var needle_tilt: ColorRect
var lbl_tilt_deg: Label
var arrow_wind: Label

# Debug Telemetry
var debug_panel: PanelContainer
var lbl_debug_text: Label
var debug_visible: bool = false

# Popups
var panel_result: PanelContainer
var lbl_result_title: Label
var lbl_result_details: Label
var btn_result_action: Button
var btn_result_retry: Button

func _ready() -> void:
	_build_hud_elements()
	_build_popup_elements()

func _build_hud_elements() -> void:
	if hud_root == null:
		return
		
	# Xóa các con cũ nếu có
	for child in hud_root.get_children():
		child.queue_free()
		
	# 1. Top Bar Container
	var top_bar = VBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 16.0
	top_bar.offset_top = 16.0
	top_bar.offset_right = -16.0
	hud_root.add_child(top_bar)
	
	# Hàng 1: Mode + Level title & Nút đổi chế độ
	var row1 = HBoxContainer.new()
	top_bar.add_child(row1)
	
	lbl_mode_level = Label.new()
	lbl_mode_level.text = "CHIẾN DỊCH - MÀN 1"
	lbl_mode_level.add_theme_font_size_override("font_size", 16)
	lbl_mode_level.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	lbl_mode_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(lbl_mode_level)
	
	var btn_mode = Button.new()
	btn_mode.text = "Đổi Chế Độ [1-3]"
	btn_mode.focus_mode = Control.FOCUS_NONE
	btn_mode.pressed.connect(func(): _show_mode_selector_dialog())
	row1.add_child(btn_mode)
	
	# Hàng 2: Điểm số & Thanh tiến trình ngưỡng
	var row2 = HBoxContainer.new()
	top_bar.add_child(row2)
	
	lbl_score = Label.new()
	lbl_score.text = "Điểm: 0 / 300"
	lbl_score.add_theme_font_size_override("font_size", 18)
	lbl_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(lbl_score)
	
	lbl_combo = Label.new()
	lbl_combo.text = ""
	lbl_combo.add_theme_font_size_override("font_size", 16)
	lbl_combo.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	row2.add_child(lbl_combo)
	
	progress_score = ProgressBar.new()
	progress_score.min_value = 0.0
	progress_score.max_value = 300.0
	progress_score.value = 0.0
	progress_score.custom_minimum_size = Vector2(0, 8)
	progress_score.show_percentage = false
	top_bar.add_child(progress_score)
	
	# Hàng 3: Số quân còn lại
	lbl_troops = Label.new()
	lbl_troops.text = "Lính: 1 / 5"
	lbl_troops.add_theme_font_size_override("font_size", 14)
	lbl_troops.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	top_bar.add_child(lbl_troops)
	
	# 2. Đếm ngược trung tâm (Center Countdown)
	lbl_countdown = Label.new()
	lbl_countdown.text = "3"
	lbl_countdown.set_anchors_preset(Control.PRESET_CENTER)
	lbl_countdown.offset_left = -150.0
	lbl_countdown.offset_top = -60.0
	lbl_countdown.offset_right = 150.0
	lbl_countdown.offset_bottom = 60.0
	lbl_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_countdown.add_theme_font_size_override("font_size", 48)
	lbl_countdown.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	hud_root.add_child(lbl_countdown)
	
	# 3. Banner Cảnh báo Gió Giật (Gust Warning)
	banner_gust = PanelContainer.new()
	banner_gust.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_gust.offset_left = -160.0
	banner_gust.offset_top = 110.0
	banner_gust.offset_right = 160.0
	banner_gust.offset_bottom = 155.0
	banner_gust.visible = false
	hud_root.add_child(banner_gust)
	
	lbl_gust_text = Label.new()
	lbl_gust_text.text = "⚠️ GIÓ GIẬT BẤT NGỜ!"
	lbl_gust_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_gust_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_gust_text.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	lbl_gust_text.add_theme_font_size_override("font_size", 15)
	banner_gust.add_child(lbl_gust_text)
	
	# 4. Bottom Indicators (Tilt Gauge & Wind Compass)
	panel_indicators = PanelContainer.new()
	panel_indicators.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel_indicators.offset_left = 20.0
	panel_indicators.offset_top = -95.0
	panel_indicators.offset_right = -20.0
	panel_indicators.offset_bottom = -20.0
	hud_root.add_child(panel_indicators)
	
	var ind_vbox = VBoxContainer.new()
	panel_indicators.add_child(ind_vbox)
	
	# Thanh đo nghiêng (Tilt meter)
	var tilt_row = HBoxContainer.new()
	ind_vbox.add_child(tilt_row)
	
	var lbl_tilt_title = Label.new()
	lbl_tilt_title.text = "Tilt (A/D): "
	lbl_tilt_title.add_theme_font_size_override("font_size", 13)
	tilt_row.add_child(lbl_tilt_title)
	
	# Thanh rãnh đo nghiêng
	var tilt_bar_bg = ColorRect.new()
	tilt_bar_bg.custom_minimum_size = Vector2(180, 14)
	tilt_bar_bg.color = Color(0.15, 0.18, 0.25, 0.8)
	tilt_bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tilt_row.add_child(tilt_bar_bg)
	
	# Kim chỉ nghiêng
	needle_tilt = ColorRect.new()
	needle_tilt.custom_minimum_size = Vector2(8, 14)
	needle_tilt.color = Color(0.2, 0.85, 1.0)
	needle_tilt.position = Vector2(90, 0)
	tilt_bar_bg.add_child(needle_tilt)
	
	lbl_tilt_deg = Label.new()
	lbl_tilt_deg.text = "0.0°"
	lbl_tilt_deg.custom_minimum_size = Vector2(50, 0)
	lbl_tilt_deg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_tilt_deg.add_theme_font_size_override("font_size", 13)
	tilt_row.add_child(lbl_tilt_deg)
	
	# Hàng gió (Wind)
	var wind_row = HBoxContainer.new()
	ind_vbox.add_child(wind_row)
	
	arrow_wind = Label.new()
	arrow_wind.text = "Gió: Yên lặng (0 px/s)"
	arrow_wind.add_theme_font_size_override("font_size", 13)
	arrow_wind.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	wind_row.add_child(arrow_wind)
	
	# 5. Debug Overlay Panel (Tab key)
	debug_panel = PanelContainer.new()
	debug_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	debug_panel.offset_left = 16.0
	debug_panel.offset_top = 130.0
	debug_panel.offset_right = 260.0
	debug_panel.offset_bottom = 300.0
	debug_panel.visible = false
	hud_root.add_child(debug_panel)
	
	lbl_debug_text = Label.new()
	lbl_debug_text.add_theme_font_size_override("font_size", 11)
	lbl_debug_text.text = "DEBUG TELEMETRY [TAB]"
	debug_panel.add_child(lbl_debug_text)

func _build_popup_elements() -> void:
	if popup_root == null:
		return
		
	for child in popup_root.get_children():
		child.queue_free()
		
	# Kết quả Popup (Win/Lose)
	panel_result = PanelContainer.new()
	panel_result.set_anchors_preset(Control.PRESET_CENTER)
	panel_result.offset_left = -180.0
	panel_result.offset_top = -140.0
	panel_result.offset_right = 180.0
	panel_result.offset_bottom = 140.0
	panel_result.visible = false
	popup_root.add_child(panel_result)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel_result.add_child(vbox)
	
	lbl_result_title = Label.new()
	lbl_result_title.text = "HOÀN THÀNH!"
	lbl_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_result_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(lbl_result_title)
	
	lbl_result_details = Label.new()
	lbl_result_details.text = "Tổng điểm: 350 / 300\nĐạt mục tiêu!"
	lbl_result_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_result_details.add_theme_font_size_override("font_size", 15)
	vbox.add_child(lbl_result_details)
	
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)
	
	btn_result_retry = Button.new()
	btn_result_retry.text = "Chơi Lại [R]"
	btn_result_retry.focus_mode = Control.FOCUS_NONE
	btn_result_retry.pressed.connect(func():
		panel_result.visible = false
		retry_pressed.emit()
	)
	btn_row.add_child(btn_result_retry)
	
	btn_result_action = Button.new()
	btn_result_action.text = "Màn Tiếp Theo"
	btn_result_action.focus_mode = Control.FOCUS_NONE
	btn_result_action.pressed.connect(func():
		panel_result.visible = false
		next_level_pressed.emit()
	)
	btn_row.add_child(btn_result_action)

func update_mode_and_level(mode: GameState.GameMode, level_data: LevelData) -> void:
	if lbl_mode_level == null:
		return
	match mode:
		GameState.GameMode.CAMPAIGN:
			lbl_mode_level.text = "%s" % (level_data.level_name if level_data else "CHIẾN DỊCH")
		GameState.GameMode.ENDLESS:
			lbl_mode_level.text = "CHẾ ĐỘ VÔ TẬN (ENDLESS)"
		GameState.GameMode.PRACTICE:
			lbl_mode_level.text = "CHẾ ĐỘ TẬP LUYỆN (PRACTICE)"

func update_score(score: int, target: int, combo: int) -> void:
	if lbl_score:
		if target > 0:
			lbl_score.text = "Điểm: %d / %d" % [score, target]
			progress_score.max_value = target
			progress_score.value = score
			progress_score.visible = true
		else:
			lbl_score.text = "Điểm: %d" % score
			progress_score.visible = false
			
	if lbl_combo:
		if combo > 1:
			lbl_combo.text = "COMBO x%d!" % combo
		else:
			lbl_combo.text = ""

func update_troop_count(current_idx: int, total: int) -> void:
	if lbl_troops:
		if total > 0:
			lbl_troops.text = "Lượt lính: %d / %d" % [current_idx, total]
		else:
			lbl_troops.text = "Lượt lính: #%d" % current_idx

func show_countdown(number: int, text: String = "") -> void:
	if lbl_countdown:
		lbl_countdown.visible = true
		if text != "":
			lbl_countdown.text = text
		else:
			lbl_countdown.text = str(number)

func hide_countdown() -> void:
	if lbl_countdown:
		lbl_countdown.visible = false

func update_tilt(raw_deg: float, normalized: float) -> void:
	if lbl_tilt_deg:
		lbl_tilt_deg.text = "%.1f°" % raw_deg
	if needle_tilt:
		# Range -35 đến +35 map sang vị trí 0 đến 180 (center = 90)
		var t_pos: float = (normalized + 1.0) * 0.5 * 180.0
		needle_tilt.position.x = clamp(t_pos - 4.0, 0.0, 172.0)

func update_wind(total_wind: float) -> void:
	if arrow_wind:
		if abs(total_wind) < 5.0:
			arrow_wind.text = "Gió: Lặng gió (0 px/s)"
		elif total_wind > 0:
			arrow_wind.text = "Gió: >>> Thổi sang phải (+%.0f px/s)" % total_wind
		else:
			arrow_wind.text = "Gió: <<< Thổi sang trái (%.0f px/s)" % total_wind

func show_gust_warning(dir: float, dur: float) -> void:
	if banner_gust:
		banner_gust.visible = true
		var dir_str: String = "SANG PHẢI >>>" if dir > 0 else "<<< SANG TRÁI"
		lbl_gust_text.text = "⚠️ CẢNH BÁO GIÓ GIẬT %s!" % dir_str
		
		var tw = create_tween()
		tw.tween_interval(dur)
		tw.tween_callback(func(): banner_gust.visible = false)

func toggle_debug_overlay() -> void:
	debug_visible = not debug_visible
	if debug_panel:
		debug_panel.visible = debug_visible

func update_debug_telemetry(raw_tilt: float, curved_tilt: float, force_x: float, vx: float, vy: float, alt_y: float) -> void:
	if debug_visible and lbl_debug_text:
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
	if panel_result:
		panel_result.visible = true
		lbl_result_title.text = "🎉 CHIẾN THẮNG!"
		lbl_result_title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		lbl_result_details.text = "Tổng điểm: %d / %d\nChúc mừng bạn đã xuất sắc vượt qua màn!" % [final_score, target_score]
		btn_result_action.visible = true
		btn_result_action.text = "Màn Kế Tiếp"

func show_defeat(final_score: int, target_score: int) -> void:
	if panel_result:
		panel_result.visible = true
		lbl_result_title.text = "💔 THẤT BẠI!"
		lbl_result_title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		lbl_result_details.text = "Tổng điểm: %d / %d\nChưa đủ điểm qua màn, hãy thử lại nhé!" % [final_score, target_score]
		btn_result_action.visible = false

func _show_mode_selector_dialog() -> void:
	# Bật menu chọn mode
	var popup_menu = PopupMenu.new()
	popup_menu.add_item("1. Chiến Dịch (Campaign)", 0)
	popup_menu.add_item("2. Vô Tận (Endless)", 1)
	popup_menu.add_item("3. Tập Luyện (Practice)", 2)
	hud_root.add_child(popup_menu)
	popup_menu.id_pressed.connect(func(id: int):
		mode_button_pressed.emit(id)
		popup_menu.queue_free()
	)
	popup_menu.popup_centered()
