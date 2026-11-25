class_name SaveTransfer
extends RefCounted
## Exports and imports a SaveGame slot as a JSON file on both Web (browser
## download / file picker via JavaScriptBridge) and Desktop (native FileDialog).
## All JavaScriptBridge calls are gated behind `OS.has_feature("web")`.

static var _web_callback: JavaScriptObject


## Exports `save` to a JSON file. Calls `done.call(ok)` when finished.
static func export_save(owner: Node, save: SaveGame, done: Callable) -> void:
	var filename := "lucian_slot_%d.json" % save.slot
	var text := save.export_json()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), filename, "application/json")
		done.call(true)
		return
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.current_file = filename
	dialog.add_filter("*.json", "JSON")
	dialog.file_selected.connect(func(path: String) -> void:
		var file := FileAccess.open(path, FileAccess.WRITE)
		var ok := false
		if file != null:
			ok = file.store_string(text) and file.get_error() == OK
			file.close()
		dialog.queue_free()
		done.call(ok))
	dialog.canceled.connect(dialog.queue_free)
	owner.add_child(dialog)
	dialog.popup_centered()


## Picks a JSON file and imports it into `save`. Calls `done.call(ok)` when a
## file was chosen (nothing is called if the user cancels).
static func import_save(owner: Node, save: SaveGame, done: Callable) -> void:
	if OS.has_feature("web"):
		_web_callback = JavaScriptBridge.create_callback(func(args: Array) -> void:
			var text := str(args[0]) if not args.is_empty() else ""
			done.call(save.import_json(text)))
		var win := JavaScriptBridge.get_interface("window")
		win.lucianImportCb = _web_callback
		JavaScriptBridge.eval("var i=document.createElement('input');i.type='file';i.accept='.json,application/json';i.onchange=function(e){var f=e.target.files[0];if(!f)return;var r=new FileReader();r.onload=function(){if(window.lucianImportCb)window.lucianImportCb(String(r.result||''));};r.readAsText(f);};i.click();")
		return
	var dialog := FileDialog.new()
	dialog.use_native_dialog = true
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.json", "JSON")
	dialog.file_selected.connect(func(path: String) -> void:
		var text := FileAccess.get_file_as_string(path)
		dialog.queue_free()
		done.call(save.import_json(text)))
	dialog.canceled.connect(dialog.queue_free)
	owner.add_child(dialog)
	dialog.popup_centered()
