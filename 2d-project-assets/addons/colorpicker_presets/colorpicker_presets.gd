@tool
extends EditorPlugin


const PRESETS_FILENAME := 'presets.gpl'


func _enter_tree() -> void:
	var presets_path: String = get_script().resource_path.get_base_dir().path_join(PRESETS_FILENAME)
	var presets_file := FileAccess.open(presets_path, FileAccess.READ)

	if FileAccess.get_open_error() == OK:
		var presets_raw := presets_file.get_as_text().split("\n")
		presets_file.close()
		var presets: Array[Color] = []
		var is_palette_data := false

		for preset_raw in presets_raw:
			var line := String(preset_raw).strip_edges()
			if line.is_empty():
				continue
			if not is_palette_data:
				if line.begins_with("#"):
					is_palette_data = true
				continue
			if line.begins_with("#"):
				continue

			var rgb := Array(line.replace("\t", " ").split(" ", false)).slice(0, 3)
			if rgb.size() < 3:
				continue
			presets.append(Color8(rgb[0].to_int(), rgb[1].to_int(), rgb[2].to_int()))

		get_editor_interface().get_editor_settings().set_project_metadata(
			"color_picker", "presets", presets
		)
