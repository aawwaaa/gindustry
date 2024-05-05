extends Node

class G_Object:
    func _ready() -> void:
        pass

    func _process(delta: float) -> void:
        pass

    func _physics_process(delta: float) -> void:
        pass

    func _input(event: InputEvent) -> void:
        pass

    func _unhandled_input(event: InputEvent) -> void:
        pass

var objects: Array[G_Object] = []

var main: MainNode
var tree: SceneTree

var temp: G_Temp

var config: G_Config
var mods: G_Mods

var types: G_Types
var contents: G_Contents

var game: G_Game
var players: G_Players
var worlds: G_Worlds

var presets: G_Presets
var saves: G_Saves

var client: G_Client
var server: G_Server

var headless: G_Headless
var input: G_Input

func _ready() -> void:
    tree = get_tree()

func add(obj: G_Object, init = true) -> G_Object:
    if init: obj._ready()
    return obj

func _process(delta: float) -> void:
    for obj in objects:
        obj._process(delta)

func _physics_process(delta: float) -> void:
    for obj in objects:
        obj._physics_process(delta)

func _input(event: InputEvent) -> void:
    for obj in objects:
        obj._input(event)

func _unhandled_input(event: InputEvent) -> void:
    for obj in objects:
        obj._unhandled_input(event)

func init() -> void:
    temp = add(G_Temp.new())

    config = add(G_Config.new())
    mods = add(G_Mods.new())

    types = add(G_Types.new())
    contents = add(G_Contents.new())

    game = add(G_Game.new())
    players = add(G_Players.new())
    worlds = add(G_Worlds.new())

    presets = add(G_Presets.new())
    saves = add(G_Saves.new())

    client = add(G_Client.new())
    server = add(G_Server.new())

    headless = add(G_Headless.new())
    input = add(G_Input.new())
