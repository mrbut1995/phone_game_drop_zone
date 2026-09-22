# Quản lý popup dùng chung cho mọi scene (nền tảng là UI/Popup trong base.tscn).
# Popup nào mở ra cũng được đưa lên trên cùng và giữ trong stack để đóng hàng loạt khi cần.
class_name PopupController
extends Node

signal popup_opened(popup: Control)
signal popup_closed(popup: Control)

@export var popup_root: Control

var _open_stack: Array[Control] = []

# Hiển thị popup: đảm bảo nằm trong UI/Popup, show và đưa lên tầng trên cùng
func open_popup(popup: Control) -> void:
	if popup == null:
		return
	if popup_root != null and popup.get_parent() != popup_root:
		popup.reparent(popup_root)
	popup.show()
	if popup_root != null:
		popup_root.move_child(popup, popup_root.get_child_count() - 1)
	if not _open_stack.has(popup):
		_open_stack.append(popup)
	popup_opened.emit(popup)

func close_popup(popup: Control) -> void:
	if popup == null:
		return
	popup.hide()
	_open_stack.erase(popup)
	popup_closed.emit(popup)

func is_popup_open(popup: Control) -> bool:
	return popup != null and popup.visible

func close_all() -> void:
	for popup in _open_stack:
		if is_instance_valid(popup):
			popup.hide()
	_open_stack.clear()
