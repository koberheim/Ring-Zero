extends SceneTree
## Reproducible platform notices and original vector-to-PNG store candidates.
func _initialize() -> void:
	var destination := "res://assets/licenses/godot"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	var notice := FileAccess.open(destination+"/LICENSE.txt",FileAccess.WRITE)
	if notice == null: push_error("Cannot write Godot license"); quit(1); return
	notice.store_string(Engine.get_license_text())
	notice.close()
	var third_party := FileAccess.open(destination+"/THIRD-PARTY.txt",FileAccess.WRITE)
	if third_party == null: push_error("Cannot write third-party notices"); quit(1); return
	third_party.store_string("Bundled Godot component notices\n\n")
	for component in Engine.get_copyright_info():
		third_party.store_string(JSON.stringify(component,"  ")+"\n\n")
	for name in Engine.get_license_info():
		third_party.store_string(String(name)+"\n"+String(Engine.get_license_info()[name])+"\n\n")
	third_party.close()
	var icons := "res://exports/steam-icons"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(icons))
	for id in AchievementHooks.IDS:
		var icon := Image.load_from_file("res://assets/ui/achievements/"+id.to_lower()+".svg")
		if icon == null or icon.is_empty(): push_error("Cannot rasterize "+id); quit(1); return
		icon.resize(64,64,Image.INTERPOLATE_LANCZOS)
		if icon.save_png(icons+"/"+id+".png") != OK: quit(1); return
		for y in icon.get_height():
			for x in icon.get_width():
				var color := icon.get_pixel(x,y)
				var gray := color.get_luminance()*0.55
				icon.set_pixel(x,y,Color(gray,gray,gray,color.a))
		if icon.save_png(icons+"/"+id+"_locked.png") != OK: quit(1); return
	print("Godot notices and 12 achievement PNG candidates prepared.")
	quit(0)
