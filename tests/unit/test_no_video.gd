extends GutTest
## T802 Nada de vídeo (008 SC-804; constituição IX): nenhum arquivo de vídeo no projeto — as
## cutscenes rodam no motor.

const VIDEO_EXT: PackedStringArray = ["ogv", "webm", "mp4", "mov", "avi", "mkv"]
const SKIP_DIRS: PackedStringArray = [".godot", ".git", "build", "addons"]


func _scan(dir: String, found: PackedStringArray) -> int:
	var n: int = 0
	for f: String in DirAccess.get_files_at(dir):
		n += 1
		if VIDEO_EXT.has(f.get_extension().to_lower()):
			found.append(dir + f)
	for d: String in DirAccess.get_directories_at(dir):
		if not SKIP_DIRS.has(d):
			n += _scan(dir + d + "/", found)
	return n


func test_project_has_no_video_files() -> void:
	var found := PackedStringArray()
	var scanned: int = _scan("res://", found)
	assert_gt(scanned, 50, "varreu o projeto")
	assert_eq(found, PackedStringArray(), "sem vídeo")
