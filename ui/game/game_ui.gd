class_name GameUI
extends Control

signal ui_shown();
signal ui_hidden();

static var instance: GameUI;
@onready var player_inventory: PlayerInventory = $PlayerInventory
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var debug: Label = %Debug
@onready var input_handler_ui: Control = %InputHandlerUI

func _ready() -> void:
    instance = self

func show_ui() -> void:
    visible = true
    ui_shown.emit()

func hide_ui() -> void:
    visible = false
    ui_hidden.emit()
