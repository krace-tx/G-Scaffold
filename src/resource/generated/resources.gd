class_name Resources
extends RefCounted

## -----------------------------------------------------------------------------
## AUTO-GENERATED FILE. DO NOT EDIT.
## Generator : Asset Groups
## Source    : res://src/resource/data/resource_map.tres
##
## Edit the source manifest in Asset Groups and regenerate this file.
## Any manual changes will be overwritten.
## -----------------------------------------------------------------------------

## Static resource path registry. Use [Resources] constants instead of raw [code]res://[/code] strings.

#region Constants & State
## Group -> file paths (leaf assets only, dirs excluded).
const _GROUP_PATHS: Dictionary = {
}

## Group -> leaf filename -> first matching file path.
const _GROUP_BY_FILENAME: Dictionary = {
}
#endregion

#region Public API
## Returns every file path registered under [param group_name].
static func paths_in_group(group_name: StringName) -> Array[String]:
	var raw: Array = _GROUP_PATHS.get(group_name, [])
	var result: Array[String] = []
	for path: String in raw:
		result.append(String(path))
	return result

## Returns the first file path in [param group_name] whose leaf filename equals [param filename].
## [param filename] must be the full leaf name (e.g. [code]01-01.png[/code]).
static func find_path_by_filename(group_name: StringName, filename: String) -> String:
	var index: Dictionary = _GROUP_BY_FILENAME.get(group_name, {})
	return String(index.get(filename, ""))
#endregion
