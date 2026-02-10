extends Resource
class_name Target

var expected_input:int
var beat:float

func _init(_expected_input:int, _beat:float ) -> void:
	expected_input = _expected_input
	beat = _beat

func _to_string() -> String:
	return str(expected_input) + ", " + str(beat)
