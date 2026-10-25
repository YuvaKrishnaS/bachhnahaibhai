class_name Sfx
extends Node

const DIR := "res://assets/sfx/"
const POOL := 8

var players: Array = []
var cache := {}
var next := 0
var muted := false


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)


func get_stream(sound_name: String):
	if cache.has(sound_name):
		return cache[sound_name]
	var path := DIR + sound_name + ".wav"
	var stream = null
	if ResourceLoader.exists(path):
		stream = load(path)
	cache[sound_name] = stream
	return stream


func play(sound_name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if muted:
		return
	var stream = get_stream(sound_name)
	if stream == null:
		return
	var p: AudioStreamPlayer = players[next]
	next = (next + 1) % POOL
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()
