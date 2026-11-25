class_name LeaveGuard
extends RefCounted
## Web-only browser `beforeunload` guard: asks the browser to show its
## standard leave prompt while progress is unsaved or a stage is open.
## All browser calls are gated behind `OS.has_feature("web")` so headless
## tests that set `GameSettings.web = true` never touch `JavaScriptBridge`.

static var _installed := false
static var _last_unsafe := false


## True when closing the browser tab could lose progress (unsaved changes
## or an active stage). Static so GUT tests can verify it without a browser.
static func is_unsafe(save: SaveGame, in_stage: bool) -> bool:
	return in_stage or (save != null and save.unsaved)


## Registers the `beforeunload` listener once on Web.
static func install() -> void:
	if _installed or not OS.has_feature("web"):
		return
	_installed = true
	_last_unsafe = false
	JavaScriptBridge.eval("window.lucianUnsafe=false;window.addEventListener('beforeunload',function(e){if(window.lucianUnsafe){e.preventDefault();e.returnValue='';}});document.addEventListener('fullscreenchange',function(){if(!navigator.keyboard)return;if(document.fullscreenElement){if(navigator.keyboard.lock)navigator.keyboard.lock(['Escape']).catch(function(){});}else if(navigator.keyboard.unlock){navigator.keyboard.unlock();}});")


## Updates `window.lucianUnsafe` in the browser when it changes.
static func set_unsafe(unsafe: bool) -> void:
	if not OS.has_feature("web"):
		return
	install()
	if unsafe == _last_unsafe:
		return
	_last_unsafe = unsafe
	JavaScriptBridge.eval("window.lucianUnsafe=%s;" % ("true" if unsafe else "false"))
