extends Node

const MIX_RATE: float = 22050.0
const MAX_VOICES: int = 8
const ENGINE_IDLE_PITCH: float = 0.85
const ENGINE_MOVING_PITCH: float = 1.15
const BGM_BPM: float = 125.0
const BGM_BARS: int = 2
const BGM_VOLUME_DB: float = -12.0

# One-shots end with silence longer than the generator buffer. `_process` stops the
# voice as soon as the last sample is pushed, and at that moment the buffer still
# holds up to `buffer_length` of audio that has not been heard yet; if that audio
# is the silent tail, the stop discards only silence instead of the sound's decay.
const ONE_SHOT_TAIL: float = 0.25

var _players: Array[AudioStreamPlayer] = []
var _active: Dictionary = {}
var _engine_player: AudioStreamPlayer = null
var _bgm_player: AudioStreamPlayer = null
var last_sfx: StringName = &""
var _engine_moving: bool = false
var _hit: PackedVector2Array
var _bgm: PackedVector2Array

var _cannon: PackedVector2Array
var _ricochet: PackedVector2Array
var _explosion: PackedVector2Array
var _engine: PackedVector2Array

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.player_died.connect(_on_player_died)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	for i: int in MAX_VOICES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "Voice%d" % i
		add_child(player)
		_players.append(player)
	_cannon = _render_burst(0.35, 0.09, 90.0)
	_explosion = _render_burst(0.8, 0.22, 45.0)
	_ricochet = _render_ping(0.3, 2400.0, 900.0)
	_engine = _render_engine(1.0)
	_hit = _render_hit()
	_bgm = _render_bgm()
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.enemy_destroyed.connect(_on_enemy_destroyed)

func _on_game_state_changed(new_state: int) -> void:
	if new_state == GameManager.State.PLAYING:
		if _engine_player == null:
			play_engine(_engine_moving)
		start_bgm()
	else:
		stop_engine()
		stop_bgm()

func _exit_tree() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
		player.stream = null
	_active.clear()
	_engine_player = null
	_bgm_player = null

func play_cannon() -> void:
	last_sfx = &"cannon"
	_play(_cannon, 1.0, false)

func play_ricochet() -> void:
	last_sfx = &"ricochet"
	_play(_ricochet, randf_range(0.9, 1.1), false)

func play_explosion() -> void:
	last_sfx = &"explosion"
	_play(_explosion, 1.0, false)

func play_hit() -> void:
	last_sfx = &"hit"
	_play(_hit, randf_range(0.95, 1.05), false)

func play_enemy_cannon() -> void:
	last_sfx = &"enemy_cannon"
	_play(_cannon, 0.8, false)

func play_engine(moving: bool) -> void:
	last_sfx = &"engine"
	_engine_moving = moving
	var pitch: float = ENGINE_MOVING_PITCH if moving else ENGINE_IDLE_PITCH
	if _engine_player != null and not _active.has(_engine_player):
		_engine_player = null
	if _engine_player != null:
		_engine_player.pitch_scale = pitch
		return
	_engine_player = _play(_engine, pitch, true)

func stop_engine() -> void:
	if _engine_player == null:
		return
	_engine_player.stop()
	_active.erase(_engine_player)
	_engine_player = null

func start_bgm() -> void:
	if is_bgm_playing():
		return
	last_sfx = &"bgm"
	_bgm_player = _play(_bgm, 1.0, true)
	if _bgm_player != null:
		_bgm_player.volume_db = BGM_VOLUME_DB

func stop_bgm() -> void:
	if _bgm_player == null:
		return
	_bgm_player.volume_db = 0.0
	_bgm_player.stop()
	_active.erase(_bgm_player)
	_bgm_player = null

func is_bgm_playing() -> bool:
	return _bgm_player != null and _active.has(_bgm_player)

func _on_player_died() -> void:
	stop_engine()
	play_explosion()
	stop_bgm()

func _render_hit() -> PackedVector2Array:
	var count: int = int(MIX_RATE * 0.18)
	var frames: PackedVector2Array = PackedVector2Array()
	frames.resize(count + int(MIX_RATE * ONE_SHOT_TAIL))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261108
	for i: int in count:
		var t: float = float(i) / MIX_RATE
		var envelope: float = exp(-t / 0.03)
		var noise: float = rng.randf_range(-1.0, 1.0)
		var tone: float = sin(TAU * 520.0 * t) * 0.3
		var value: float = clampf((noise * 0.7 + tone) * envelope, -1.0, 1.0)
		frames[i] = Vector2(value, value)
	return frames

func _on_player_damaged(_current_hp: int, _max_hp: int) -> void:
	play_hit()

func _on_enemy_destroyed(_pos: Vector2, _score: int, _was_ricochet: bool) -> void:
	play_explosion()

func _process(_delta: float) -> void:
	_retry_playback()
	for player: AudioStreamPlayer in _players:
		if not _active.has(player):
			continue
		var playback: AudioStreamGeneratorPlayback = player.get_stream_playback() as AudioStreamGeneratorPlayback
		if playback == null:
			continue
		var state: Dictionary = _active[player]
		var samples: PackedVector2Array = state["samples"]
		var index: int = state["index"]
		var looping: bool = state["loop"]
		var available: int = playback.get_frames_available()
		while available > 0 and (index < samples.size() or looping):
			if index >= samples.size():
				index = 0
			if not playback.push_frame(samples[index]):
				break
			index += 1
			available -= 1
		state["index"] = index
		if not looping and index >= samples.size():
			player.stop()
			_active.erase(player)

func _retry_playback() -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	if _find_voice() == null:
		return
	if _engine_player == null or not _active.has(_engine_player):
		play_engine(_engine_moving)
	if not is_bgm_playing():
		start_bgm()

func _play(samples: PackedVector2Array, pitch: float, looping: bool) -> AudioStreamPlayer:
	if samples.is_empty():
		return null
	var player: AudioStreamPlayer = _find_voice()
	if player == null:
		return null

	var stream: AudioStreamGenerator = AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = 0.2
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = 0.0
	player.play()

	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		player.stop()
		return null

	_active[player] = {"samples": samples, "index": 0, "loop": looping}
	return player

func _find_voice() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not _active.has(player) and not player.playing:
			return player
	return null

func _render_bgm() -> PackedVector2Array:
	var count: int = int(MIX_RATE * float(BGM_BARS * 4) * 60.0 / BGM_BPM)
	var frames: PackedVector2Array = PackedVector2Array()
	frames.resize(count)
	for i: int in count:
		frames[i] = Vector2.ZERO
	var beat_frames: int = int(MIX_RATE * 60.0 / BGM_BPM)
	var total_beats: int = BGM_BARS * 4
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 125125
	for beat: int in total_beats:
		var beat_start: int = beat * beat_frames
		var beat_length: int = mini(beat_frames, count - beat_start)
		var kick_phase: float = 0.0
		for i: int in beat_length:
			var t: float = float(i) / MIX_RATE
			var frequency: float = lerpf(60.0, 45.0, minf(t / 0.3, 1.0))
			kick_phase += TAU * frequency / MIX_RATE
			var value: float = frames[beat_start + i].x + sin(kick_phase) * 0.55 * exp(-t / 0.06)
			if beat % 4 == 1 or beat % 4 == 3:
				value += rng.randf_range(-1.0, 1.0) * 0.35 * exp(-t / 0.05)
			frames[beat_start + i] = Vector2(value, value)
		for half: int in 2:
			var hat_start: int = beat_start + half * (beat_frames / 2)
			var hat_length: int = mini(int(MIX_RATE * 0.08), count - hat_start)
			for i: int in hat_length:
				var t: float = float(i) / MIX_RATE
				var value: float = frames[hat_start + i].x + rng.randf_range(-1.0, 1.0) * 0.16 * exp(-t / 0.015)
				frames[hat_start + i] = Vector2(value, value)
	var fade_frames: int = int(MIX_RATE * 0.01)
	for i: int in count:
		var t: float = float(i) / MIX_RATE
		var fade: float = minf(1.0, minf(float(i), float(count - 1 - i)) / float(fade_frames))
		var drone: float = sin(TAU * 55.0 * t) * 0.12 + sin(TAU * 82.5 * t) * 0.08
		var value: float = clampf((frames[i].x + drone) * fade, -1.0, 1.0)
		frames[i] = Vector2(value, value)
	return frames

func _render_burst(duration: float, decay: float, tone_hz: float) -> PackedVector2Array:
	var count: int = int(MIX_RATE * duration)
	var frames: PackedVector2Array = PackedVector2Array()
	frames.resize(count + int(MIX_RATE * ONE_SHOT_TAIL))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261106
	var low: float = 0.0
	for i: int in count:
		var t: float = float(i) / MIX_RATE
		var envelope: float = exp(-t / decay)
		low += 0.15 * (rng.randf_range(-1.0, 1.0) - low)
		var tone: float = sin(TAU * tone_hz * t) * 0.4
		var value: float = clampf((low * 0.9 + tone) * envelope, -1.0, 1.0)
		frames[i] = Vector2(value, value)
	return frames

func _render_ping(duration: float, start_hz: float, end_hz: float) -> PackedVector2Array:
	var count: int = int(MIX_RATE * duration)
	var frames: PackedVector2Array = PackedVector2Array()
	frames.resize(count + int(MIX_RATE * ONE_SHOT_TAIL))
	var phase: float = 0.0
	for i: int in count:
		var t: float = float(i) / MIX_RATE
		var progress: float = t / duration
		var frequency: float = lerpf(start_hz, end_hz, progress)
		phase += TAU * frequency / MIX_RATE
		var envelope: float = exp(-t / 0.08)
		var value: float = clampf(sin(phase) * envelope * 0.35, -1.0, 1.0)
		frames[i] = Vector2(value, value)
	return frames

func _render_engine(duration: float) -> PackedVector2Array:
	var count: int = int(MIX_RATE * duration)
	var frames: PackedVector2Array = PackedVector2Array()
	frames.resize(count)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 4242
	var low: float = 0.0
	for i: int in count:
		var t: float = float(i) / MIX_RATE
		var fade: float = minf(1.0, minf(t, duration - t) / 0.02)
		low += 0.05 * (rng.randf_range(-1.0, 1.0) - low)
		var value: float = (sin(TAU * 55.0 * t) * 0.25 + sin(TAU * 82.5 * t) * 0.15 + low * 0.4) * fade
		value = clampf(value, -1.0, 1.0)
		frames[i] = Vector2(value, value)
	return frames
