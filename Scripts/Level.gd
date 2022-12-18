extends Spatial

onready var defaultFile = 'res://levelCollection/Classic.txt'
onready var player = $"../Player/PlayerBody"
onready var thisNode = $"."

var levels = []
var curLevel = 0
var boxScene = preload("res://Scenes/Box.tscn")
var plateScene = preload("res://Scenes/Plate.tscn")
var crateScene = preload("res://Scenes/CrateKaykit.tscn")
var mapData = preload("res://classical_levels.tres")
var map = []
var origin = Vector3.ZERO
var rows = 0
var cols = 0
var playerCell = [0,0]
var crateCells = []
var targetCells = []
var allInstances = []
var cratesOutOfPlace = 0
var undoHistory = []

func _ready():
	print("Level Ready")
	#load_file(defaultFile)
	load_map_data(mapData.levelData)
	print (levels.size(), " levels loaded")

func next_level():
	if curLevel + 1 < len(levels):
		load_map(curLevel+1)

func load_map_data(levelData: String) -> void:
	levels = []
	var lines = []
	var width = 0
	for line in levelData.split("\n"):
		if len(line) == 0:
			levels.append({"cols":width, "rows": len(lines), "map":lines})
			width = 0
			lines = []
		elif line[0] == ";":
			pass
		else:
			width = max(width,len(line))
			lines.append(line)
	if len(lines)>0:
		levels.append({"cols":width, "rows": len(lines), "map":lines})
	
#func load_file(file : String) -> void:
#	var f = File.new()
#	if not f.file_exists(file):
#		print ("Can't find "+file)
#	print ("loading "+file)
#	f.open(file, File.READ)
#	while not f.eof_reached(): 
#		var level = []
#		var width = 0
#		while not f.eof_reached(): 
#			var line = f.get_line()
#			if len(line) == 0:
#				break
#			elif line[0] == ";":
#				continue
#			else: 
#				width = max(width,len(line))
#				level.append(line)
#		if len(level) != 0:
#			levels.append({"cols":width, "rows": len(level), "map":level})
#	f.close()

func cell_to_pos (col, row) -> Vector3:
	return origin+Vector3(col*2,2,row*2)
	
func load_map (l) -> void:
	player.set_animation("Idle")
	curLevel = l
	var level = levels[l]
	map = []
	cols = level.cols
	rows = level.rows
	origin = Vector3(int(-cols), 0, int(-rows))
	crateCells = []
	targetCells = []
	playerCell = null
	cratesOutOfPlace = 0
	for instance in allInstances:
		thisNode.remove_child(instance)
	allInstances = []
	for row in rows:
		map.append(level.map[row]+"")
		for col in cols:
			if col < len(map[row]):
				var cell = map[row][col]
				if cell == "#":
					var instance = boxScene.instance()
					allInstances.append(instance)
					instance.transform = Transform.IDENTITY.translated(cell_to_pos (col,row))
					thisNode.add_child(instance)
				elif cell == "@":
					playerCell = [col,row]
					map [row][col] = " "
				elif cell == "$" or cell == "*":
					var instance = crateScene.instance()
					allInstances.append(instance)
					instance.transform = Transform.IDENTITY.translated(cell_to_pos (col,row))
					thisNode.add_child(instance)
					crateCells.append([col,row,instance])
					if cell == "*":
						instance = plateScene.instance()
						allInstances.append(instance)
						instance.transform = Transform.IDENTITY.translated(cell_to_pos (col,row))
						thisNode.add_child(instance)
					else: 
						cratesOutOfPlace += 1
				elif cell == "." or cell == "+":
					var instance = plateScene.instance()
					allInstances.append(instance)
					instance.transform = Transform.IDENTITY.translated(cell_to_pos (col,row))
					thisNode.add_child(instance)
					targetCells.append(([col,row,instance]))
					if cell == "+":
						map [row][col] = "."
						playerCell = [col,row]
	print ("player cell = ", playerCell)
	player.transform = Transform.IDENTITY.translated(cell_to_pos (playerCell[0], playerCell[1]))
	
func valid_player_move (dcol, drow) -> Dictionary:
	var col = playerCell[0]
	var row = playerCell[1]
	var cell = map[row+drow][col+dcol]
	var result = { "valid" : false }
	var state = get_state()
	if cell == "." or cell == " ": 
		result = {"valid":true, "obj":null, "greatMove" : false}
	if cell == "$" or cell == "*":
		var thisCol = col+dcol
		var thisRow = row+drow
		var nextCol = col+dcol*2
		var nextRow = row+drow*2
		var nextCell = map[nextRow][nextCol]
		if nextCell == " " or nextCell == ".":
			if cell == "*": cratesOutOfPlace += 1
			for iCrate in len(crateCells):
				var crate = crateCells [iCrate]
				if crate[0] == thisCol and crate[1]==thisRow:
					crate[0] = nextCol 
					crate[1] = nextRow
					map [thisRow][thisCol] = " " if cell == "$" else "."
					map [nextRow][nextCol] = "$" if nextCell == " " else "*"
					result = {"valid":true, "obj":crate[2], "greatMove": false}
					if nextCell == ".": 
						cratesOutOfPlace -= 1
						result["greatMove"] = true
					
					break
	if result["valid"]:
		undoHistory.append (state)
		playerCell = [col,row]
	return result

func restore_state (state : Dictionary) -> void:
	load_map (state["curLevel"])
	playerCell = state["playerCell"]
	player.transform = Transform.IDENTITY.translated(cell_to_pos (playerCell[0],playerCell[1]))
	var crateState = state["crateState"]
	assert (len(crateState) == len(crateCells))
	for crateCell in crateCells:
		var row = crateCell[1]
		var col = crateCell[0]
		var has_plate = false
		for cell in targetCells:
			if cell[0] == col and cell[1] == row:
				has_plate = true
		map [row][col] = "." if has_plate else " "
	cratesOutOfPlace = 0
	for i in len(crateState):
		var crateCell = crateCells[i]
		var crate = crateState[i]
		if map [crate[1]][crate[0]] != ".": 
			cratesOutOfPlace += 1
			map [crate[1]][crate[0]] = "$"
		else:
			map [crate[1]][crate[0]] = "*"
		crateCell[0] = crate[0]
		crateCell[1] = crate[1]
		crateCell[2].transform = Transform.IDENTITY.translated(cell_to_pos (crate[0],crate[1]))
	print ("crates out of place=", cratesOutOfPlace)

func get_state () -> Dictionary:
	var crateState = []
	for cell in crateCells:
		crateState.append(cell.slice(0,2))
	var state = {"playerCell" : playerCell.duplicate(), 
				 "curLevel" : curLevel,
				 "crateState" : crateState}
	return state
	
func undo () -> void:
	if len(undoHistory) > 0:
		var undoRecord = undoHistory.pop_back()
		restore_state (undoRecord)
	print ("undo")
