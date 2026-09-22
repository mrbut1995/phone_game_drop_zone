# Controller UI cơ sở cho MỌI scene kế thừa BaseScene.
# BaseScene (scenes/base.tscn) khai báo sẵn:
#   - UI/HUD   (Control) - vùng chứa HUD
#   - UI/Popup (Control) - vùng chứa popup
#   - Controllers/UIController (node mang script này)
# Scene cụ thể (ví dụ Game) override script của node này bằng lớp con (GameUIController)
# và tự thêm các node UI vào UI/HUD, UI/Popup của mình.
class_name BaseUIController
extends Node

@export var hud_root: Control
@export var popup_root: Control
@export var popup_ctrl: PopupController

func set_hud_visible(is_visible: bool) -> void:
	if hud_root != null:
		hud_root.visible = is_visible

func clear_popups() -> void:
	if popup_ctrl != null:
		popup_ctrl.close_all()
