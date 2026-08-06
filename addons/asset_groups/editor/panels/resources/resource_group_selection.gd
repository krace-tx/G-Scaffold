@tool
class_name ResourceGroupSelection
extends RefCounted

enum Mode { EMPTY, SINGLE_RESOURCE, MULTI_RESOURCE, GROUP }

var mode: Mode = Mode.EMPTY
var resource_id: StringName = &""
var resource_ids: Array[StringName] = []
var group_name: StringName = ResourceGroupConstants.NO_GROUP_SELECTED


static func empty() -> ResourceGroupSelection:
	return ResourceGroupSelection.new()


static func single_resource(res_id: StringName) -> ResourceGroupSelection:
	var snapshot := ResourceGroupSelection.new()
	snapshot.mode = Mode.SINGLE_RESOURCE
	snapshot.resource_id = res_id
	snapshot.resource_ids = [res_id]
	return snapshot


static func multi_resources(res_ids: Array[StringName]) -> ResourceGroupSelection:
	var snapshot := ResourceGroupSelection.new()
	snapshot.mode = Mode.MULTI_RESOURCE
	snapshot.resource_ids = res_ids.duplicate()
	return snapshot


static func group(g_name: StringName) -> ResourceGroupSelection:
	var snapshot := ResourceGroupSelection.new()
	snapshot.mode = Mode.GROUP
	snapshot.group_name = g_name
	return snapshot
