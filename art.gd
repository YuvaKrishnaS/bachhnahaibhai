class_name Art

const FONT_SCALE := 1.5
const FONT_PATH := "res://assets/font.ttf"

static var tex_cache := {}
static var cached_font: Font


static func get_tex(path: String) -> Texture2D:
	if tex_cache.has(path):
		return tex_cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	tex_cache[path] = t
	return t


static func get_font() -> Font:
	if cached_font == null:
		var f = null
		if ResourceLoader.exists(FONT_PATH):
			f = load(FONT_PATH)
		if f != null:
			cached_font = f
		else:
			cached_font = ThemeDB.fallback_font
	return cached_font
