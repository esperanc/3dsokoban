extends Spatial

const saveFileName = "user://savegame.save"
onready var levelMenu = $LevelMenu
onready var cratesLabel = $UI/labelContainer/Crates
onready var levelLabel = $UI/labelContainer/Level
onready var endGameDialog = $EndGameDialog
onready var endGameNextButton = $EndGameDialog/Next

var levelsVisited = { "0" : true }

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print ("Main ready")
	endGameNextButton.connect("button_down", self, "nextButtonPressed")
	if not load_game():
		print ("no saved game")
		$Level.load_map(0)
	display_stats()
	$SaveTimer.start(5)

func nextButtonPressed():
	print ("next")
	endGameDialog.hide()
	$Level.next_level()
	levelsVisited [str($Level.curLevel)] = true
	display_stats()
	
func _input(_event: InputEvent) -> void:
	display_stats()
	if $Level.cratesOutOfPlace == 0:
		levelsVisited[str($Level.curLevel)] = true
		save_game()
		endGameDialog.popup()

func display_stats() -> void:
	cratesLabel.text = str($Level.cratesOutOfPlace)+ " crates"
	levelLabel.text = "level "+str($Level.curLevel+1)
	
func restart()-> void:
	levelMenu.prepare_menu (len($Level.levels), levelsVisited, $".", "on_LevelMenuItem_button_down")
	
func on_LevelMenuItem_button_down(level):
	levelsVisited [str(level)] = true
	$LevelMenu.hide_dialog()
	print ("restart at ", level)
	$Level.load_map(level)
	display_stats()
	
func undo() -> void:
	$Level.undo()

func save_game() -> void:
	var save_dict = $Level.get_state()
	var save_game = File.new()
	save_game.open(saveFileName, File.WRITE)
	save_game.store_line(to_json(save_dict))
	save_game.store_line(to_json(levelsVisited))
	save_game.close()

func load_game() -> bool:
	var save_game = File.new()
	if not save_game.file_exists(saveFileName):
		return false # Error! We don't have a save to load.
	save_game.open("user://savegame.save", File.READ)
	var save_dict = parse_json(save_game.get_line())
	levelsVisited = parse_json(save_game.get_line())
	print(levelsVisited)
	save_game.close()
	$Level.restore_state(save_dict)
	display_stats()
	return true
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_game()
		print ("quitting")
		get_tree().quit() # default behavior


func _on_SaveTimer_timeout() -> void:
	display_stats()
	save_game()


func _on_Button_button_down() -> void:
	print ("xpto")
	pass # Replace with function body.
