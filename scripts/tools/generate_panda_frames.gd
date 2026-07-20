extends SceneTree
## Dev tool: builds panda_{female,male}_frames.tres from the sprite sheets
## using the exact frame rects Unity's Sprite Editor already detected
## (converted from Unity's bottom-left origin to Godot's top-left origin).
## Both sheets share the same layout -- the male one is derived pixel-wise
## from the female one (see scratchpad make_male_panda.py).
## Run with: godot --headless --script res://scripts/tools/generate_panda_frames.gd

const SHEETS := {
	"res://assets/sprites/panda/panda_female_sheet.png": "res://assets/sprites/panda/panda_female_frames.tres",
	"res://assets/sprites/panda/panda_male_sheet.png": "res://assets/sprites/panda/panda_male_frames.tres",
}

const IDLE_RECTS := [
	[130, 43, 81, 85],
	[223, 43, 71, 85],
	[306, 42, 67, 86],
	[387, 44, 72, 84],
]
const RUN_RECTS := [
	[101, 168, 78, 87],
	[178, 169, 67, 85],
	[247, 168, 77, 88],
	[323, 168, 67, 85],
	[392, 168, 74, 88],
	[471, 168, 65, 88],
]
const JUMP_RECTS := [
	[101, 314, 73, 73],
	[182, 297, 61, 80],
	[254, 297, 62, 80],
	[326, 297, 70, 80],
	[399, 298, 59, 83],
	[468, 297, 63, 82],
]

func _initialize() -> void:
	var failed := false
	for sheet_path in SHEETS:
		var tex: Texture2D = load(sheet_path)
		if not tex:
			printerr("Could not load ", sheet_path)
			failed = true
			continue

		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		_add_animation(frames, "idle", 6.0, true, IDLE_RECTS, tex)
		_add_animation(frames, "run", 10.0, true, RUN_RECTS, tex)
		_add_animation(frames, "jump", 8.0, false, JUMP_RECTS, tex)

		var out_path: String = SHEETS[sheet_path]
		var err := ResourceSaver.save(frames, out_path)
		if err == OK:
			print("Saved ", out_path)
		else:
			printerr("Failed to save SpriteFrames: ", err)
			failed = true
	quit(1 if failed else 0)

func _add_animation(frames: SpriteFrames, anim_name: String, speed: float, loop: bool, rects: Array, tex: Texture2D) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, speed)
	frames.set_animation_loop(anim_name, loop)
	for r in rects:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(r[0], r[1], r[2], r[3])
		frames.add_frame(anim_name, atlas)
