extends Resource
class_name Song

var name:String
var bpm:int
var targets:Array = []

func add_target(exp_key:int, beat:float):
	var nuevo:Target = Target.new(exp_key, beat)
	targets.append(nuevo)

func _to_string() -> String:
	var temp:String = "\n----------\nSONG: %s\nBPM: %d\n" % [name, bpm]
	temp += "TARGETS:"
	for x in targets:
		temp += "\n" + x._to_string()
	temp += "\n----------\n"
	return temp
