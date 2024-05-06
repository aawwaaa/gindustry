extends Node

class G_Object extends Node:
    pass

var objects: Array[G_Object] = []
var logger: Log.Logger = Log.register_logger("G_LogSource");

var main: MainNode
var tree: SceneTree

var temp: G_Temp

var configs: G_Configs
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

func add(obj: G_Object, name = obj.name, init = true) -> G_Object:
    if init: add_child(obj)
    obj.name = name
    return obj

func init() -> void:
    temp = add(G_Temp.new(), "Temp")

    configs = add(G_Configs.new(), "Configs")
    mods = add(G_Mods.new(), "Mods")

    types = add(G_Types.new(), "Types")
    contents = add(G_Contents.new(), "Contents")

    game = add(G_Game.new(), "Game")
    players = add(G_Players.new(), "Players")
    worlds = add(G_Worlds.new(), "Worlds")

    presets = add(G_Presets.new(), "Presets")
    saves = add(G_Saves.new(), "Saves")

    client = add(G_Client.new(), "Client")
    server = add(G_Server.new(), "Server")

    headless = add(G_Headless.new(), "Headless")
    input = add(G_Input.new(), "Input")
