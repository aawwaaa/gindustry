class_name DebugMenu
extends CanvasLayer

const scene = preload("res://ui/debug_menu/debug_menu.tscn")

var debug_enabled: bool = false:
    set(v):
        debug_enabled = v;
        visible = v
        if v: Vars.ui.focus.set_focused(self)
@onready var basic: DebugMenu_Basic = %Basic
@onready var network: DebugMenu_Network = %Network

func _ready() -> void:
    basic.menu = self
    network.menu = self
    visible = false

func _input(event: InputEvent) -> void:
    if not OS.is_debug_build(): return
    if event.is_action_pressed("debug_open_menu"):
        debug_enabled = not debug_enabled
