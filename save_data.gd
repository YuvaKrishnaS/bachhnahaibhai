class_name SaveData

const PATH := "user://bachhnahaibhai.cfg"


static func load_data() -> Dictionary:
	var result := {"time": 0.0, "score": 0}
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		result["time"] = float(cfg.get_value("best", "time", 0.0))
		result["score"] = int(cfg.get_value("best", "score", 0))
	return result


static func save_data(best_time: float, best_score: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("best", "time", best_time)
	cfg.set_value("best", "score", best_score)
	cfg.save(PATH)
