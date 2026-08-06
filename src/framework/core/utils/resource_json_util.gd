class_name ResourceJsonUtil
extends RefCounted

## Resource / Variant <-> JSON-compatible Dictionary conversion utility.
##
## Round trip:
##   Resource        -> resource_to_dict() -> Dictionary -> JSON.stringify()
##   JSON.parse_string() -> Dictionary -> dict_to_resource() -> Resource
##
## Custom Resource subclasses are restored automatically as long as the resource was
## produced by resource_to_dict() (which embeds the originating script path under
## SCRIPT_PATH_KEY), or via an explicit script_path_dict override.


#region Constants

const SCRIPT_PATH_KEY := "_script_path" ## Reserved dictionary key that remembers a Resource's script.

const DEFAULT_SKIP_PROPERTY_NAMES: Array[String] = [
	"resource_local_to_scene",
	"resource_name",
	"resource_path",
	"script",
] ## Built-in Resource properties that are never serialized.

#endregion


#region Public API

## Serializes the storage-relevant properties of [param resource] into a JSON-compatible
## Dictionary. Nested Resources, Arrays and Dictionaries are handled recursively.
## [param extra_skip_property_names] excludes additional properties for this call only.
static func resource_to_dict(
		resource: Resource,
		extra_skip_property_names: Array[String] = []
	) -> Dictionary:
	if resource == null:
		return {}

	var result := {}

	var script_path := _get_script_path(resource)
	if not script_path.is_empty():
		result[SCRIPT_PATH_KEY] = script_path

	var skip_names := _build_skip_list(extra_skip_property_names)
	for prop in resource.get_property_list():
		if not _is_serializable_property(prop, skip_names):
			continue
		result[prop.name] = value_to_json(resource.get(prop.name))

	return result


## Recursively converts [param value] into a JSON-compatible Variant, expanding any
## nested Resource, Array or Dictionary values it contains.
static func value_to_json(value: Variant) -> Variant:
	if value == null:
		return null
	if value is Resource:
		return resource_to_dict(value)
	if value is Array:
		return value.map(func(item: Variant) -> Variant: return value_to_json(item))
	if value is Dictionary:
		var dict := {}
		for key: Variant in value:
			dict[key] = value_to_json(value[key])
		return dict
	return value


## Reconstructs a Resource (the correct subclass, when known) from [param dict].
## [param script_path_dict] optionally maps property keys to explicit script paths and
## takes priority over any script path embedded in the dictionary itself.
## [param current_key] identifies which property this call is reconstructing; leave
## empty for the root call.
static func dict_to_resource(
		dict: Dictionary,
		script_path_dict: Dictionary = {},
		current_key: String = ""
	) -> Resource:
	return _dict_to_resource_with_hint(dict, script_path_dict, current_key, "")

#endregion


#region Dictionary -> Resource population

## Same contract as [method dict_to_resource], plus [param class_name_hint]: a fallback
## class to instantiate against when no explicit or embedded script path is available
## (used internally when reconstructing typed-array / typed-object properties).
static func _dict_to_resource_with_hint(
		dict: Dictionary,
		script_path_dict: Dictionary,
		current_key: String,
		class_name_hint: String
	) -> Resource:
	var script_path: String = script_path_dict.get(current_key, "")
	if script_path.is_empty():
		script_path = str(dict.get(SCRIPT_PATH_KEY, ""))

	var res := _instantiate_resource(script_path, class_name_hint)
	_apply_dict_to_resource(res, dict, script_path_dict)
	return res


## Applies every applicable entry of [param dict] onto [param res], recursing into
## nested Resources and Arrays as needed.
static func _apply_dict_to_resource(res: Resource, dict: Dictionary, script_path_dict: Dictionary) -> void:
	for key: Variant in dict:
		if key == SCRIPT_PATH_KEY:
			continue
		if not _has_property(res, key):
			continue

		var value: Variant = dict[key]
		if value is Dictionary:
			_apply_dict_value(res, key, value, script_path_dict)
		elif value is Array and _is_array_property(res, key):
			_set_property(res, key, _parse_array(res, key, value, script_path_dict))
		else:
			_set_property(res, key, value)


static func _apply_dict_value(res: Resource, key: String, value: Dictionary, script_path_dict: Dictionary) -> void:
	var current: Variant = res.get(key)
	if current is Resource:
		# Property already holds a live Resource instance (e.g. an inline default) -
		# populate it in place instead of replacing it.
		_apply_dict_to_resource(current, value, script_path_dict)
		return

	if _should_treat_as_resource(res, key, value, script_path_dict):
		var class_name_hint := _get_object_class_name(res, key)
		_set_property(res, key, _dict_to_resource_with_hint(value, script_path_dict, key, class_name_hint))
	else:
		_set_property(res, key, value)


static func _should_treat_as_resource(res: Resource, key: String, value: Dictionary, script_path_dict: Dictionary) -> bool:
	if _get_property_type(res, key) == TYPE_OBJECT:
		return true
	if script_path_dict.has(key):
		return true
	# A dict that itself declares its origin script is unambiguously a Resource,
	# regardless of what the (possibly loosely-typed) destination property claims.
	return value.has(SCRIPT_PATH_KEY)


static func _parse_array(res: Resource, key: String, values: Array, script_path_dict: Dictionary) -> Array:
	var element_class_name := _get_array_element_class_name(res, key)
	var elements_are_resources := script_path_dict.has(key) or not element_class_name.is_empty()

	var items: Array = []
	for item: Variant in values:
		if item is Dictionary and (elements_are_resources or item.has(SCRIPT_PATH_KEY)):
			items.append(_dict_to_resource_with_hint(item, script_path_dict, key, element_class_name))
		else:
			items.append(item)

	return _build_typed_array(element_class_name, items)

#endregion


#region Resource instantiation

static func _instantiate_resource(script_path: String, class_name_hint: String = "") -> Resource:
	var resolved_path := script_path
	if resolved_path.is_empty():
		resolved_path = _find_script_path_for_class(class_name_hint)

	if not resolved_path.is_empty() and ResourceLoader.exists(resolved_path):
		var script := load(resolved_path)
		if script is Script:
			var inst: Variant = script.new()
			if inst is Resource:
				return inst

	# Built-in engine Resource subclasses (e.g. "GradientTexture2D") are registered with
	# ClassDB and can be instantiated directly, without any script path.
	if not class_name_hint.is_empty() and ClassDB.class_exists(class_name_hint) \
			and ClassDB.can_instantiate(class_name_hint):
		var inst: Variant = ClassDB.instantiate(class_name_hint)
		if inst is Resource:
			return inst

	return Resource.new()


static func _find_script_path_for_class(class_name_hint: String) -> String:
	if class_name_hint.is_empty():
		return ""
	for entry in ProjectSettings.get_global_class_list():
		if entry.get("class", "") == class_name_hint:
			return entry.get("path", "")
	return ""


static func _get_script_path(resource: Resource) -> String:
	var script: Variant = resource.get_script()
	if script is Script:
		return script.resource_path
	return ""

#endregion


#region Reflection helpers

static func _find_property_info(obj: Object, prop_name: String) -> Dictionary:
	for prop in obj.get_property_list():
		if prop.name == prop_name:
			return prop
	return {}


static func _has_property(obj: Object, prop_name: String) -> bool:
	return not _find_property_info(obj, prop_name).is_empty()


static func _get_property_type(obj: Object, prop_name: String) -> int:
	return _find_property_info(obj, prop_name).get("type", TYPE_NIL)


static func _is_array_property(obj: Object, prop_name: String) -> bool:
	return _get_property_type(obj, prop_name) == TYPE_ARRAY


## Returns the readable class name of a plain Object/Resource-typed property (not an
## array), or "" if it isn't one. For these, hint_string already IS the class name.
static func _get_object_class_name(obj: Object, prop_name: String) -> String:
	var info := _find_property_info(obj, prop_name)
	if info.get("type", TYPE_NIL) != TYPE_OBJECT:
		return ""
	return str(info.get("hint_string", ""))


## Returns the readable element type/class name of a typed array property (e.g. "int",
## "String", or a Resource subclass name), or "" if [param prop_name] isn't a typed array.
static func _get_array_element_class_name(obj: Object, prop_name: String) -> String:
	var info := _find_property_info(obj, prop_name)
	if info.is_empty():
		return ""
	var hint: int = info.get("hint", PROPERTY_HINT_NONE)
	if hint != PROPERTY_HINT_ARRAY_TYPE and hint != PROPERTY_HINT_TYPE_STRING:
		return ""

	# Godot encodes typed-array hints as "{elem_type}[/{elem_hint}]:{elem_hint_string}",
	# e.g. "1:bool", "4:String", "24/17:MyResource" - the readable name we want is
	# always the part after the first ":".
	var hint_string := str(info.get("hint_string", ""))
	var colon_idx := hint_string.find(":")
	return hint_string if colon_idx == -1 else hint_string.substr(colon_idx + 1)


static func _set_property(obj: Object, key: String, value: Variant) -> void:
	obj.set(key, value)


static func _build_skip_list(extra_skip_property_names: Array[String]) -> Array[String]:
	var skip_names := DEFAULT_SKIP_PROPERTY_NAMES.duplicate()
	for skip_name in extra_skip_property_names:
		if skip_name not in skip_names:
			skip_names.append(skip_name)
	return skip_names


static func _is_serializable_property(prop: Dictionary, skip_names: Array[String]) -> bool:
	if not (prop.usage & PROPERTY_USAGE_STORAGE):
		return false
	return prop.name not in skip_names

#endregion


#region Typed array construction

static func _build_typed_array(element_class_name: String, items: Array) -> Array:
	if element_class_name.is_empty():
		return items

	var typed_array := _create_empty_typed_array(element_class_name)
	for item: Variant in items:
		typed_array.append(item)
	return typed_array


static func _create_empty_typed_array(element_class_name: String) -> Array:
	match element_class_name:
		"String":
			return Array([], TYPE_STRING, "", null)
		"int":
			return Array([], TYPE_INT, "", null)
		"float":
			return Array([], TYPE_FLOAT, "", null)
		"bool":
			return Array([], TYPE_BOOL, "", null)
		_:
			var script_path := _find_script_path_for_class(element_class_name)
			if not script_path.is_empty() and ResourceLoader.exists(script_path):
				var script := load(script_path) as Script
				if script != null:
					return Array([], TYPE_OBJECT, script.get_instance_base_type(), script)
			return Array([], TYPE_OBJECT, element_class_name, null)

#endregion
