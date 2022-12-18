extends Control

var menuItemScene = preload("res://Scenes/LevelMenuItem.tscn")
onready var levelList = $LevelList

func _ready() -> void:
	visible = false
	
func prepare_menu (levelCount : int, levelsVisited : Dictionary, obj : Object, callbackName = "_on_LevelMenuItem_button_down") -> void:
	visible = true
	print ("preparing", levelsVisited, levelsVisited.keys(), levelsVisited.has("0"))
	for child in levelList.get_children():
		levelList.remove_child(child)
		child.queue_free()
	for i in levelCount:
		var menuItem = menuItemScene.instance()
		menuItem.text = str(i+1)
		menuItem.connect ("button_down", obj, callbackName, [i])
		if not str(i) in levelsVisited:
			menuItem.disabled = true
		levelList.add_child(menuItem)

func hide_dialog () -> void:
	visible = false
