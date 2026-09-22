# Dây điện cao thế.
# Scene powerline.tscn khai báo sẵn: LeftPole (Sprite2D), RightPole (Sprite2D), Cable (Sprite2D),
# Sprite (AnimatedSprite2D - SparkVFX, animation "zap"), kèm CableCollision chứa các
# CollisionShape2D nhỏ xếp theo độ võng của dây.
class_name PowerlineObstacle
extends Obstacle

@export var line_width: float = 380.0
@export var sag_amount: float = 22.0 # Độ võng của dây (px) - khớp thiết kế powerline_cable.svg

@onready var left_pole: Sprite2D = $LeftPole
@onready var right_pole: Sprite2D = $RightPole
@onready var cable: Sprite2D = $Cable
@onready var cable_collision: Node2D = $CableCollision
@onready var spark_vfx: AnimatedSprite2D = $Sprite

var spark_timer: float = 0.0

func _ready() -> void:
	super._ready()
	obstacle_category = ObstacleCategory.STRUCTURAL
	auto_wrap_x = false
	speed = 0.0 # Vật thể tĩnh
	_apply_layout()

func on_setup(params: Dictionary) -> void:
	if params.has("line_width"):
		line_width = params["line_width"]
	if params.has("sag_amount"):
		sag_amount = params["sag_amount"]
	_apply_layout()

# Cột 2 đầu + dây cáp co giãn theo line_width; hitbox dây cáp co giãn theo Cable
func _apply_layout() -> void:
	var half := line_width * 0.5
	left_pole.position.x = -half
	right_pole.position.x = half
	cable.scale = Vector2(line_width / 380.0, sag_amount / 22.0)
	cable_collision.scale = cable.scale

func acting(delta: float) -> void:
	anim_time += delta
	spark_timer += delta

	# Tạo tia điện hồ quang ngẫu nhiên dọc theo dây (VFX là AnimatedSprite2D "Sprite")
	if spark_timer > 0.4:
		spark_timer = 0.0
		if randf() < 0.65:
			var half := line_width * 0.5
			var x: float = randf_range(-0.75, 0.75) * half
			var y: float = sag_amount * (1.0 - (x / half) * (x / half))
			spark_vfx.position = Vector2(x, y)
			spark_vfx.show()
			spark_vfx.play(&"zap")

func _on_spark_animation_finished() -> void:
	spark_vfx.hide()
