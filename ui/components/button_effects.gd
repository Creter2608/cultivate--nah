extends Node
class_name ButtonEffects

## Utility class for adding tactile touch press animations and audio feedback to Godot buttons.

static var _default_click_stream: AudioStreamWAV = null

static func setup_all_buttons(root_node: Node) -> void:
	if not root_node:
		return
	
	if root_node is BaseButton:
		setup_button(root_node as BaseButton)
	
	for child in root_node.get_children():
		setup_all_buttons(child)

static func setup_button(
	button: BaseButton,
	press_scale: Vector2 = Vector2(0.92, 0.92),
	custom_sound: AudioStream = null,
	enable_haptics: bool = true
) -> void:
	if not button or button.has_meta("_button_effects_setup"):
		return
		
	button.set_meta("_button_effects_setup", true)
	
	_update_pivot(button)
	if not button.resized.is_connected(_update_pivot.bind(button)):
		button.resized.connect(_update_pivot.bind(button))
	
	var active_tween: Array[Tween] = []
	
	# Touch down on mobile screen: snappy compression feedback + sound effect + optional haptic
	button.button_down.connect(func():
		if not button.disabled:
			if enable_haptics:
				trigger_haptic(15)
			play_click_sound(custom_sound)
			_animate_scale(button, active_tween, press_scale, 0.06, Tween.TRANS_QUAD, Tween.EASE_OUT)
	)
	
	# Touch release on mobile screen: spring bounce back to normal size
	button.button_up.connect(func():
		if not button.disabled:
			_animate_scale(button, active_tween, Vector2.ONE, 0.18, Tween.TRANS_BACK, Tween.EASE_OUT)
	)
	
	# Touch drag off / exit handling
	button.mouse_exited.connect(func():
		if not button.disabled:
			_animate_scale(button, active_tween, Vector2.ONE, 0.1, Tween.TRANS_QUAD, Tween.EASE_OUT)
	)

## Triggers a short haptic vibration pulse on mobile platforms (Android/iOS).
## Safe to call on desktop (no-op).
static func trigger_haptic(duration_ms: int = 15) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)

## Gently pulses a button's scale up and back to normal to draw attention (e.g. for quest/reward CTA).
static func pulse_attention(button: Control, duration: float = 0.6) -> void:
	_update_pivot(button)
	var tween: Tween = button.create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), duration * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, duration * 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func play_click_sound(sound_stream: AudioStream = null) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return
		
	var player := AudioStreamPlayer.new()
	player.volume_db = -6.0
	
	if sound_stream != null:
		player.stream = sound_stream
	elif ResourceLoader.exists("res://assets/audio/sfx/click.wav"):
		player.stream = load("res://assets/audio/sfx/click.wav")
	elif ResourceLoader.exists("res://addons/dialogic/Example Assets/sound-effects/typing1.wav"):
		player.stream = load("res://addons/dialogic/Example Assets/sound-effects/typing1.wav")
	else:
		player.stream = _get_procedural_click_sound()
		
	tree.root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

static func _update_pivot(button: Control) -> void:
	button.pivot_offset = button.size / 2.0

static func _animate_scale(
	button: Control,
	tween_holder: Array[Tween],
	target_scale: Vector2,
	duration: float,
	trans_type: Tween.TransitionType,
	ease_type: Tween.EaseType
) -> void:
	if not tween_holder.is_empty() and tween_holder[0] and tween_holder[0].is_running():
		tween_holder[0].kill()
	
	var tween := button.create_tween()
	tween.tween_property(button, "scale", target_scale, duration).set_trans(trans_type).set_ease(ease_type)
	
	if tween_holder.is_empty():
		tween_holder.append(tween)
	else:
		tween_holder[0] = tween

static func _get_procedural_click_sound() -> AudioStreamWAV:
	if _default_click_stream != null:
		return _default_click_stream

	var sample_rate := 44100
	var duration := 0.035
	var num_samples := int(sample_rate * duration)
	var byte_array := PackedByteArray()
	byte_array.resize(num_samples * 2)

	var freq := 800.0
	for i in range(num_samples):
		var t := float(i) / float(sample_rate)
		var envelope := exp(-t * 120.0)
		var sample := sin(2.0 * PI * freq * t) * envelope
		freq = max(150.0, freq - 15.0)
		
		var sample_int := int(sample * 12000.0)
		sample_int = clamp(sample_int, -32768, 32767)
		
		byte_array[i * 2] = sample_int & 0xFF
		byte_array[(i * 2) + 1] = (sample_int >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = byte_array
	_default_click_stream = stream
	return stream
