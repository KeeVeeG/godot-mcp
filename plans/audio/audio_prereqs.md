# Prerequisites for Audio Test Plan

**Source:** `server/src/test_plans/audio_test_plan.md`
**Tools covered (7):** `add_audio_player`, `remove_audio_player`, `add_audio_bus`, `add_audio_bus_effect`, `set_audio_bus`, `get_audio_bus_layout`, `get_audio_info`
**Total test scenarios:** 84

---

## Required Project State

- Godot 4.x project open in the editor (any project type; a basic Node2D project is sufficient)
- Godot MCP addon installed and **active** (`addons/godot_mcp/` present, plugin enabled in Project Settings → Plugins)
- MCP server connected to the Godot editor (WebSocket established on ports 6505–6514)
- No conflicting nodes in the scene (a fresh/empty scene is best before running the setup script)

---

## Required Scenes

A single scene with the following node hierarchy must exist before running any tests. This scene is the **test fixture** for nearly all scenarios.

### Scene Root
- **Type:** `Node2D` (or `Node3D`; `Node2D` preferred since `AudioStreamPlayer2D` tests reference 2D context)
- **Name:** `AudioTestScene` (or any name; the root itself is not referenced by tests)

### Node Hierarchy

```
AudioTestScene (Node2D)
├── AudioStreamPlayer              [DEFAULT name — matches add_audio_player default]
├── MyMusicPlayer                  [type: AudioStreamPlayer, custom name]
├── MusicPlayer                    [type: AudioStreamPlayer, stream = res://sounds/music.ogg]
├── PlayingMusic                   [type: AudioStreamPlayer, stream = res://sounds/music.ogg, autoplay = true]
├── SFXPlayer2D                    [type: AudioStreamPlayer2D, custom name]
├── Sprite2D                       [type: Sprite2D — non-audio node for negative test]
└── Player (Node2D)
    ├── AudioStreamPlayer2D        [type: AudioStreamPlayer2D, DEFAULT name]
    ├── Ambient3D                  [type: AudioStreamPlayer3D]
    └── Sprites (Node2D)
        └── Effects (Node2D)
```

### Node Details

| Node Path | Type | Attributes |
|-----------|------|------------|
| `AudioStreamPlayer` | `AudioStreamPlayer` | Default name (Godot auto-assigns `AudioStreamPlayer` when added without name) |
| `MyMusicPlayer` | `AudioStreamPlayer` | Custom name explicitly set to `MyMusicPlayer` |
| `MusicPlayer` | `AudioStreamPlayer` | `stream` = `res://sounds/music.ogg` |
| `PlayingMusic` | `AudioStreamPlayer` | `stream` = `res://sounds/music.ogg`, `autoplay` = `true`, `bus` = `Master` |
| `SFXPlayer2D` | `AudioStreamPlayer2D` | Custom name explicitly set to `SFXPlayer2D` |
| `Sprite2D` | `Sprite2D` | Basic 2D sprite node; no special properties |
| `Player` | `Node2D` | Parent container node |
| `Player/AudioStreamPlayer2D` | `AudioStreamPlayer2D` | Default name, nested under `Player` |
| `Player/Ambient3D` | `AudioStreamPlayer3D` | Named `Ambient3D`, nested under `Player` |
| `Player/Sprites` | `Node2D` | Container node; must exist for nested-path tests |
| `Player/Sprites/Effects` | `Node2D` | Deep container node for `add_audio_player` Scenario 3 |

---

## Required Resources

Audio stream files must exist on disk so `stream_path` assignments can resolve successfully:

| Resource Path | Format | Used By |
|---------------|--------|---------|
| `res://sounds/music.ogg` | OGG Vorbis audio | `add_audio_player` S9, S11; `MusicPlayer` node; `PlayingMusic` node; `get_audio_info` S4 |
| `res://sounds/explosion.wav` | WAV audio | `add_audio_player` S11 (all params smoke test) |

**Notes:**
- These files can be any valid audio file of the correct format. Synthetic 1-second silent audio is acceptable.
- The `sounds/` directory must exist at `res://sounds/`.
- If files are missing, Godot may still create the node but the `stream` property will be a broken reference.

---

## Required Audio Bus Layout

The following buses must exist in the project's audio bus layout **before** running tests:

| Index | Bus Name | Notes |
|-------|----------|-------|
| 0 | `Master` | Always present in any Godot project (automatically exists). Must be at index 0. |
| 1 | `Music` | Custom bus; added during setup. Needed by `add_audio_player` S10, `add_audio_bus_effect` S22, `set_audio_bus` S2/S5. |
| 2 | `SFX` | Custom bus; added during setup. Needed by `add_audio_player` S11, `add_audio_bus_effect` S25, `set_audio_bus` S3/S6. |

**Bus Effects:**
- `reverb` effect must be added to the `Music` bus (required for `get_audio_bus_layout` Scenario 2 — end-to-end verification that effects appear in layout output).

---

## Required Editor/Game State

| State Requirement | Scenarios Requiring It | Notes |
|-------------------|------------------------|-------|
| **Editor mode** (not play mode) | All scenarios except `get_audio_info` S5 | Default state; all node creation, bus configuration, and most queries run in editor mode. |
| **Play mode** (game running) | `get_audio_info` S5 only | `PlayingMusic` node must be actively playing audio. Start the scene with play button, and the node's `autoplay = true` will begin playback automatically. |

---

## Required Settings/Config

No special project settings, input actions, autoloads, or collision layers are required beyond what Godot provides by default for a new Node2D project.

The default audio settings (stereo, 44100 Hz, default bus layout with only `Master`) are the correct starting point. The setup script below establishes the required buses and effects.

---

## Setup Script

Run this GDScript in the Godot editor via `execute_editor_script` **before** any audio tests. It creates the scene hierarchy, audio buses, audio bus effects, and placeholder audio resource files.

```gdscript
# === Audio Test Prerequisites — Setup Script ===
# Run in Godot editor via execute_editor_script before executing audio_test_plan.md scenarios.
# Creates: test scene with audio player nodes, audio buses with effects,
# and placeholder audio resource files.

@tool
extends EditorScript

func _run() -> void:
	var root: Node
	var scene_root: Node

	# ── 1. Create or locate the test scene ─────────────────────────────
	var scene_path := "res://test_scenes/audio_test.tscn"
	var scene_file := ResourceLoader.load(scene_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if scene_file:
		print("[SETUP] Scene found: ", scene_path)
	else:
		print("[SETUP] Creating scene at: ", scene_path)
		var new_scene := PackedScene.new()
		scene_root = Node2D.new()
		scene_root.name = "AudioTestScene"
		new_scene.pack(scene_root)
		DirAccess.make_dir_recursive_absolute("res://test_scenes")
		ResourceSaver.save(new_scene, scene_path)
		scene_root.queue_free()

	# ── 2. Open and populate the scene ─────────────────────────────────
	var scene := get_editor_interface().open_scene_from_path(scene_path)
	scene_root = scene if scene else get_tree().edited_scene_root
	if not scene_root:
		printerr("[SETUP] Failed to get scene root. Aborting.")
		return

	# Helper: add a child node if it doesn't already exist
	func add_if_missing(parent: Node, child_type: String, child_name: String = "") -> Node:
		var existing := parent.get_node_or_null(child_name) if child_name else null
		if not child_name:
			# For default-named nodes, search by type
			for c in parent.get_children():
				if c.get_class() == child_type and c.name == child_type:
					print("[SETUP] Node already exists: ", parent.get_path(), "/", child_type)
					return c
		if existing:
			print("[SETUP] Node already exists: ", existing.get_path())
			return existing
		var node: Node = ClassDB.instantiate(child_type)
		if child_name:
			node.name = child_name
		parent.add_child(node)
		node.owner = scene_root
		print("[SETUP] Created: ", node.get_path())
		return node

	# ── 3. Build node hierarchy ────────────────────────────────────────
	# Root-level nodes
	var audio_default := add_if_missing(scene_root, "AudioStreamPlayer", "AudioStreamPlayer")
	var my_music_player := add_if_missing(scene_root, "AudioStreamPlayer", "MyMusicPlayer")
	var music_player := add_if_missing(scene_root, "AudioStreamPlayer", "MusicPlayer")
	var playing_music := add_if_missing(scene_root, "AudioStreamPlayer", "PlayingMusic")
	var sfx_player_2d := add_if_missing(scene_root, "AudioStreamPlayer2D", "SFXPlayer2D")
	var sprite_2d := add_if_missing(scene_root, "Sprite2D", "Sprite2D")

	# Player subtree
	var player_node := add_if_missing(scene_root, "Node2D", "Player")
	var player_audio_2d := add_if_missing(player_node, "AudioStreamPlayer2D", "AudioStreamPlayer2D")
	var ambient_3d := add_if_missing(player_node, "AudioStreamPlayer3D", "Ambient3D")

	var sprites_node := add_if_missing(player_node, "Node2D", "Sprites")
	var effects_node := add_if_missing(sprites_node, "Node2D", "Effects")

	# ── 4. Create placeholder audio resource files ─────────────────────
	DirAccess.make_dir_recursive_absolute("res://sounds")

	func ensure_audio_file(filepath: String) -> void:
		if FileAccess.file_exists(filepath):
			print("[SETUP] Audio file already exists: ", filepath)
			return
		# Create a minimal valid OGG/WAV header so Godot recognizes the file.
		# For a placeholder, we write a very small valid file.
		var f := FileAccess.open(filepath, FileAccess.WRITE)
		if not f:
			printerr("[SETUP] Cannot write: ", filepath)
			return
		if filepath.ends_with(".ogg"):
			# Minimal OGG/Vorbis — bare minimum header
			var ogg_header := PackedByteArray([
				0x4F, 0x67, 0x67, 0x53,  # "OggS"
				0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				0x00, 0x00, 0x00, 0x00, 0xB6, 0xBC, 0xD3, 0x7B, 0x01, 0x00, 0x00, 0x00,
				0x01, 0x76, 0x6F, 0x72, 0x62, 0x69, 0x73, 0x00, 0x00, 0x00, 0x00, 0x02,
				0x44, 0xAC, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xD8, 0x01
			])
			f.store_buffer(ogg_header)
		else:
			# Minimal WAV header (44 bytes, silent, mono, 44100 Hz, 16-bit PCM)
			var wav_header := PackedByteArray([
				0x52, 0x49, 0x46, 0x46,  # "RIFF"
				0x24, 0x00, 0x00, 0x00,  # ChunkSize = 36
				0x57, 0x41, 0x56, 0x45,  # "WAVE"
				0x66, 0x6D, 0x74, 0x20,  # "fmt "
				0x10, 0x00, 0x00, 0x00,  # Subchunk1Size = 16
				0x01, 0x00,              # AudioFormat = PCM
				0x01, 0x00,              # NumChannels = 1
				0x44, 0xAC, 0x00, 0x00,  # SampleRate = 44100
				0x88, 0x58, 0x01, 0x00,  # ByteRate = 88200
				0x02, 0x00,              # BlockAlign = 2
				0x10, 0x00,              # BitsPerSample = 16
				0x64, 0x61, 0x74, 0x61,  # "data"
				0x00, 0x00, 0x00, 0x00   # Subchunk2Size = 0 (no audio data)
			])
			f.store_buffer(wav_header)
		f.close()
		print("[SETUP] Created placeholder audio file: ", filepath)

	ensure_audio_file("res://sounds/music.ogg")
	ensure_audio_file("res://sounds/explosion.wav")

	# Refresh asset database so Godot picks up the new audio files
	get_editor_interface().get_resource_filesystem().scan()

	# ── 5. Assign stream resources to audio players (after file creation) ──
	var music_stream := ResourceLoader.load("res://sounds/music.ogg", "", ResourceLoader.CACHE_MODE_IGNORE)
	if music_stream:
		music_player.set("stream", music_stream)
		playing_music.set("stream", music_stream)
		playing_music.set("autoplay", true)
		print("[SETUP] Assigned music.ogg stream to MusicPlayer and PlayingMusic")
	else:
		printerr("[SETUP] Could not load music.ogg — stream property NOT set")

	# ── 6. Configure audio buses ──────────────────────────────────────
	# Godot always has Master at index 0.
	# Add Music and SFX buses if they don't exist.

	var bus_count := AudioServer.bus_count
	print("[SETUP] Current bus count: ", bus_count)

	# Check if buses already exist by name
	var has_music := false
	var has_sfx := false
	for i in range(bus_count):
		var bus_name := AudioServer.get_bus_name(i)
		if bus_name == "Music":
			has_music = true
		elif bus_name == "SFX":
			has_sfx = true

	if not has_music:
		AudioServer.add_bus(bus_count)
		var music_idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(music_idx, "Music")
		print("[SETUP] Added 'Music' bus at index: ", music_idx)
	else:
		print("[SETUP] 'Music' bus already exists")

	if not has_sfx:
		AudioServer.add_bus(bus_count + 1)  # bus_count may have changed
		var sfx_idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		print("[SETUP] Added 'SFX' bus at index: ", sfx_idx)
	else:
		print("[SETUP] 'SFX' bus already exists")

	# ── 7. Add reverb effect to Music bus ──────────────────────────────
	# Required for get_audio_bus_layout Scenario 2.
	var music_idx := -1
	for i in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i) == "Music":
			music_idx = i
			break

	if music_idx >= 0:
		var has_reverb := false
		for e_idx in range(AudioServer.get_bus_effect_count(music_idx)):
			var effect := AudioServer.get_bus_effect(music_idx, e_idx)
			if effect and effect.get_class() == "AudioEffectReverb":
				has_reverb = true
				break

		if not has_reverb:
			var reverb := AudioEffectReverb.new()
			AudioServer.add_bus_effect(music_idx, reverb, -1)  # -1 = append
			print("[SETUP] Added reverb effect to 'Music' bus")
		else:
			print("[SETUP] Reverb effect already on 'Music' bus")
	else:
		printerr("[SETUP] Could not find 'Music' bus index — reverb not added")

	# ── 8. Save the scene ──────────────────────────────────────────────
	var packed := PackedScene.new()
	packed.pack(scene_root)
	ResourceSaver.save(packed, scene_path)
	print("[SETUP] Scene saved: ", scene_path)
	print("[SETUP] === Audio test prerequisites complete ===")
```

**How to run the setup:**
1. Open the Godot editor with the target project.
2. Use the MCP tool: `godot_execute_editor_script` with the script above.
3. Alternatively, paste the script into a new `EditorScript` in the Godot script editor and run it.
4. After setup, the scene `res://test_scenes/audio_test.tscn` will exist with all required nodes.
5. The audio files `res://sounds/music.ogg` and `res://sounds/explosion.wav` will exist as placeholders.

---

## Post-Setup Verification Checklist

After running the setup script, verify these items before starting tests:

- [ ] Scene `res://test_scenes/audio_test.tscn` is open in the editor
- [ ] `AudioStreamPlayer` (default-named) exists at scene root
- [ ] `MyMusicPlayer` (AudioStreamPlayer) exists at scene root
- [ ] `MusicPlayer` (AudioStreamPlayer) has `stream` = `res://sounds/music.ogg`
- [ ] `PlayingMusic` (AudioStreamPlayer) has `stream` = `res://sounds/music.ogg` and `autoplay` = `true`
- [ ] `SFXPlayer2D` (AudioStreamPlayer2D) exists at scene root
- [ ] `Sprite2D` exists at scene root
- [ ] `Player` (Node2D) exists at scene root
- [ ] `Player/AudioStreamPlayer2D` exists
- [ ] `Player/Ambient3D` (AudioStreamPlayer3D) exists
- [ ] `Player/Sprites/Effects` full path exists
- [ ] Audio bus `Music` exists (check via `get_audio_bus_layout`)
- [ ] Audio bus `SFX` exists (check via `get_audio_bus_layout`)
- [ ] `reverb` effect is on the `Music` bus
- [ ] `res://sounds/music.ogg` exists on disk
- [ ] `res://sounds/explosion.wav` exists on disk
- [ ] No editor errors in output log
- [ ] Editor is in **editor mode** (not play mode) for most tests
- [ ] For `get_audio_info` Scenario 5 only: start play mode — `PlayingMusic` will auto-play

---

## Dependency Map: Which Prereqs Each Tool Needs

| Tool | Scenarios | Scene Nodes Needed | Buses Needed | Resources Needed | Editor State |
|------|-----------|-------------------|-------------|-----------------|-------------|
| `add_audio_player` | S1–S14 | `Player` (S2), `Player/Sprites/Effects` (S3) | `Music` (S10), `SFX` (S11) | `music.ogg` (S9), `explosion.wav` (S11) | Editor mode |
| `remove_audio_player` | S1–S5 | `AudioStreamPlayer` (S1), `Player/AudioStreamPlayer2D` (S2), `MyMusicPlayer` (S3) | — | — | Editor mode |
| `add_audio_bus` | S1–S9 | — | `Master` (all, always present) | — | Editor mode |
| `add_audio_bus_effect` | S1–S30 | — | `Master` (S1–S21, S23–S24), `Music` (S22), `SFX` (S25) | — | Editor mode |
| `set_audio_bus` | S1–S13 | — | `Master` (S1, S4, S9, S11–S13), `Music` (S2, S5), `SFX` (S3, S6) | — | Editor mode |
| `get_audio_bus_layout` | S1–S4 | — | `Master`, `Music` (with reverb), `SFX` (S2) | — | Editor mode |
| `get_audio_info` | S1–S9 | `AudioStreamPlayer` (S1), `SFXPlayer2D` (S2), `Player/Ambient3D` (S3), `MusicPlayer` (S4), `PlayingMusic` (S5), `Sprite2D` (S7) | — | `music.ogg` (S4, S5) | Editor (S1–S4, S6–S9); **Play mode** (S5) |

---

## Reset / Teardown Between Test Runs

To reset the audio bus layout to default (only `Master` at index 0) between runs:

1. Use `set_audio_bus_layout` with `buses: [{ "name": "Master" }]`.
2. Re-run the bus setup portion of the script (steps 6–7).
3. This ensures `add_audio_bus` tests start from a clean state with only `Master`.

For the scene, reload the saved scene from disk: `godot_open_scene` with `path = "res://test_scenes/audio_test.tscn"`.

---

**Generated:** 2026-07-08
**Plan analyzed:** `server/src/test_plans/audio_test_plan.md` (823 lines, 84 scenarios, 7 tools)
