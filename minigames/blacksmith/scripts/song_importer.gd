extends Node

const EXPORT_PATH:String = "res://song_data/exports/"
const CSV_HEADER:String = "key,beat"

var song:Song

func import_song(path:String):
	if(FileAccess.file_exists(path)):
		var file = FileAccess.open(path, FileAccess.READ)
		_extract_meta(path)
		_extract_content(file)
		file.close()
		print("[ ✔️ ] Cancion importada:" + song._to_string())

func export_song(s:Song):
	if s == null:
		printerr("[ ✘ ] Cancion no importada: la cancion no existe")
		return null
	var output_path:String = EXPORT_PATH + _generate_export_name(s)
	var file = FileAccess.open(output_path, FileAccess.WRITE)
	file.store_line(CSV_HEADER)
	for t in song.targets:
		var line:PackedStringArray = PackedStringArray([t.expected_input, t.beat])
		file.store_csv_line(line)
	file.close()
	print("[ ✔️ ] Cancion exportada en: " + output_path)

func _extract_meta(path:String):
	var filename = path.get_file().trim_suffix(".csv")
	var meta:PackedStringArray = filename.split("-")
	song = Song.new()
	song.name = meta[0]
	song.bpm = int(meta[1].substr(0,3))

func _extract_content(file:FileAccess):
	while file.get_position() < file.get_length():
		var line = file.get_csv_line()
		if line[0].is_valid_int() and line[1].is_valid_float():
			song.add_target(int(line[0]), float(line[1]))

func _generate_export_name(s:Song):
	return "%s-bpm%d.csv" % [s.name, s.bpm]
