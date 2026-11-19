extends Control

const ARENA_SCENE: String = "res://scenes/arena.tscn"
const GRID_STEP: int = 40
const GRID_WIDTH: int = 1280
const GRID_HEIGHT: int = 720
const GRID_COLOR: Color = Color(0.168627, 0.290196, 0.352941, 0.22)

@onready var blueprint_grid: Node2D = $BlueprintGrid
@onready var deploy_button: Button = $DeployButton
@onready var quit_button: Button = $QuitButton

func _ready() -> void:
	GameManager.change_state(GameManager.State.MENU)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.stop_engine()
	_build_blueprint_grid()
	deploy_button.pressed.connect(_on_deploy_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _build_blueprint_grid() -> void:
	for x: int in range(0, GRID_WIDTH + 1, GRID_STEP):
		_add_grid_line(Vector2(float(x), 0.0), Vector2(float(x), float(GRID_HEIGHT)))
	for y: int in range(0, GRID_HEIGHT + 1, GRID_STEP):
		_add_grid_line(Vector2(0.0, float(y)), Vector2(float(GRID_WIDTH), float(y)))

func _add_grid_line(from_point: Vector2, to_point: Vector2) -> void:
	var line: Line2D = Line2D.new()
	line.points = PackedVector2Array([from_point, to_point])
	line.width = 1.0
	line.default_color = GRID_COLOR
	blueprint_grid.add_child(line)

func _on_deploy_pressed() -> void:
	get_tree().change_scene_to_file(ARENA_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
