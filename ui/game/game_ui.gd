class_name GameUI
extends CanvasLayer

const scene = preload("res://ui/game/game_ui.tscn")

signal ui_shown();
signal ui_hidden();
signal contents_loaded();

static var instance: GameUI;
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var debug: Label = %Debug
@onready var content_selector: ContentSelectorWindow = %ContentSelectorWindow

func _ready() -> void:
    instance = self
    Vars.core.state.state_changed.connect(_on_state_changed)
    hide_ui.call_deferred()

func _on_state_changed(state: Vars_Core.State, from: Vars_Core.State) -> void:
    if Vars.core.is_in_game():
        show_ui()
    else:
        hide_ui()

func show_ui() -> void:
    visible = true
    ui_shown.emit()

func hide_ui() -> void:
    visible = false
    ui_hidden.emit()

func loaded() -> void:
    contents_loaded.emit()
