class_name PersistItem 
extends RefCounted

var key: String = ""              ## 资源ID
var path: String = ""             ## 持久化到磁盘的路径（user://xxxx）
var backup_path: String = ""      ## 本地兜底资源路径（res://xxxx）
var pull_url: String = ""         ## 拉取数据的http地址
var pull_method: String = "GET"   ## 拉取数据的http方法（GET/POST）
var push_url: String = ""         ## 推送数据的http地址
var push_method: String = "POST"  ## 推送数据的http方法（GET/POST）
var script_path_dict: Dictionary = {
} ## json数据返回后，哪个字段映射为哪一个tres资源的声明脚本地址

func _init(
	p_key: String = "",
	p_path: String = "",
	p_backup_path: String = "",
	p_pull_url: String = "",
	p_pull_method: String = "GET",
	p_push_url: String = "",
	p_push_method: String = "POST",
	p_script_path_dict: Dictionary = {}
) -> void:
	key = p_key
	path = p_path
	backup_path = p_backup_path
	pull_url = p_pull_url
	pull_method = p_pull_method
	push_url = p_push_url
	push_method = p_push_method
	script_path_dict = p_script_path_dict
