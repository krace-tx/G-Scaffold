class_name AppleSignIn
extends RefCounted

signal apple_output_signal(id: String, email: String, name: String, token: String, error: String)

# Variable for the extension instance
var my_library: Object = null
@export var verbose: bool = true

# Plugin configuration for Apple Sign-In (exported so you can change it in the editor)
@export var APPLE_PLUGIN_NAME: String = "AppleSignInLibrary"  # Matches your Swift extension name

func _init():
	if my_library == null && ClassDB.class_exists(APPLE_PLUGIN_NAME):
		my_library = ClassDB.instantiate(APPLE_PLUGIN_NAME)
		print("底层插件支持的信号: ", my_library.get_signal_list())
		# Connect to signals defined in AppleSignInLibrary.swift
		my_library.connect("output", on_apple_output_signal)


func sign_in() -> void:
	if my_library && my_library.has_method("signIn"):
		print("[AppleSignIn Sign in called] ")
		my_library.signIn()


func on_apple_output_signal(id: String, email: String, name: String, token: String, error: String):
	print("[AppleSignIn Output] ", id, email, name, token, error)
	apple_output_signal.emit(id, email, name, token, error)
