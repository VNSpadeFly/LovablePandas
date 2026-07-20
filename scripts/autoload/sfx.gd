extends Node
## Music + sound effects. Autoloaded as "Sfx".
## Background music loops across every scene; effects share a small
## player pool. Call Sfx.play("jump" / "collect" / "land" / "note").

const MUSIC_DB := -10.0
const SFX_DB := -6.0
const POOL_SIZE := 4

var _streams: Dictionary = {}
var _music_player: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_streams = {
		"collect": load("res://assets/audio/collect.wav"),
		"land": load("res://assets/audio/land.wav"),
		"note": _make_chime(),
	}

	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		add_child(p)
		_pool.append(p)

	var music: AudioStream = load("res://assets/audio/music_loop.ogg")
	if music:
		music.loop = true
		_music_player = AudioStreamPlayer.new()
		_music_player.stream = music
		_music_player.volume_db = MUSIC_DB
		add_child(_music_player)
		_music_player.play()

func play(sound_name: String) -> void:
	var stream: AudioStream = _streams.get(sound_name)
	if not stream:
		return
	for p in _pool:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	# All busy: steal the first player.
	_pool[0].stream = stream
	_pool[0].play()

## Soft two-note chime (E5 -> A5) for love-note unlocks, generated in
## code so it needs no asset and always fits the cozy mood.
func _make_chime() -> AudioStreamWAV:
	var rate := 22050
	var bytes := PackedByteArray()
	bytes.append_array(_tone_bytes(659.25, 0.18, 7.0, rate))
	bytes.append_array(_tone_bytes(880.0, 0.4, 5.0, rate))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

func _tone_bytes(freq: float, dur: float, decay: float, rate: int) -> PackedByteArray:
	var n := int(dur * rate)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		# Fundamental plus a quiet octave for a bell-like timbre.
		var v := (sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)) * exp(-t * decay) * 0.35
		bytes.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return bytes
