class_name InputHandlerModule
extends Node

var handler: InputHandler

var player: Player:
    get: return handler.player
var controller: PlayerController:
    get: return handler.controller
var target: ControllerAdapter:
    get: return handler.target
var entity: Entity:
    get: return handler.entity

func _init(handler: InputHandler) -> void:
    self.handler = handler

func _ready() -> void:
    pass

func _unhandled_input(event: InputEvent) -> void:
    if player == null: return
    _handle_unhandled_input(event)

func _input(event: InputEvent) -> void:
    if player == null: return
    _handle_input(event)

func _process(delta: float) -> void:
    if player == null: return
    _handle_process(delta)

func _handle_unhandled_input(event: InputEvent) -> void:
    pass

func _handle_input(event: InputEvent) -> void:
    pass

func _handle_process(delta: float) -> void:
    pass

func _handle_interact(target: Entity, input: InputEvent) -> bool:
    return false
