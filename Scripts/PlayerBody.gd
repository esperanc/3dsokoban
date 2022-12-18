extends KinematicBody

var steps = 0
var crate = null
var fps = 30
export var ms_per_cell = 300  # How many milliseconds to move between one cell and the next
var ITERATIONS = 20

onready var level = $"../../Level"
onready var nextPosition = get_world_position()
onready var animPlayer = $Barbarian/AnimCharacter/AnimationPlayer
onready var playerObject = $Barbarian
const scaleFactor = Vector3(1.5, 2, 1.5)
const translateFactor = Vector3(0,-0.5,0)

var move = Vector3.ZERO
var moveCheck = {}
var lastAnimation = null

func guess_iterations ():
	fps = Engine.get_frames_per_second()
	ITERATIONS = max(1, int(fps * ms_per_cell / 1000))
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_animation("Idle")
	guess_iterations()
	set_player_stance()
	pass # Replace with function body.

# Returns the world position of this object
func get_world_position() -> Vector3:
	return transform.xform_inv(Vector3.ZERO)

# Set the player mesh stance 
func set_player_stance (dir = Vector3(0,1,0)):
	playerObject.transform = Transform.IDENTITY.looking_at(-dir.normalized(), Vector3.UP)\
	   .translated(translateFactor).scaled(scaleFactor)

func set_animation (animName : String, loop = true) -> void:
	if lastAnimation == animName: return
	animPlayer.get_animation(animName).set_loop(loop)
	animPlayer.play(animName)
	lastAnimation = animName

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var col = level.playerCell[0]
	var row = level.playerCell[1]
	var drow = 0
	var dcol = 0
	if Input.is_action_pressed("ui_up"):
		drow= -1
	elif Input.is_action_pressed("ui_down"):
		drow = 1 
	elif Input.is_action_pressed("ui_left"):
		dcol = -1
	elif Input.is_action_pressed("ui_right"):
		dcol = 1
	if (dcol != 0 or drow != 0) and steps == 0:
		moveCheck = level.valid_player_move (dcol, drow)
		if moveCheck["valid"]:
			set_animation("Run")
			guess_iterations()
			steps = ITERATIONS
			crate = moveCheck["obj"]
			level.playerCell = [col+dcol, row+drow]
			var curPos = level.cell_to_pos (col, row)
			var newPos = level.cell_to_pos(col+dcol, row+drow)
			move =  newPos - curPos
			set_player_stance(move)
		else:
			set_animation("Idle")
	if steps > 0:
		var amt = move * (1.0/ITERATIONS)
		steps -= 1
		transform = transform.translated(amt)
		if crate!=null:
			crate.transform = crate.transform.translated(amt)
		if steps == 0 and dcol == 0 and drow ==0: 
			if moveCheck["greatMove"]:
				set_animation("Dance")
			else:
				set_animation ("Idle")
