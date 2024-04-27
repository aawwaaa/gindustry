class_name GameUI
extends Control

signal ui_shown();
signal ui_hidden();
signal contents_loaded();

static var instance: GameUI;
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var debug: Label = %Debug
@onready var input_handler_ui: Control = %InputHandlerUI
@onready var content_selector: ContentSelectorWindow = %ContentSelectorWindow

func _ready() -> void:
    instance = self

func show_ui() -> void:
    visible = true
    ui_shown.emit()

func hide_ui() -> void:
    visible = false
    ui_hidden.emit()

func loaded() -> void:
    contents_loaded.emit()
