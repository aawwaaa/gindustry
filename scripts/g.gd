extends Node

class G_Object extends Node:
    pass

var objects: Array[G_Object] = []

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

func add(obj: G_Object, init = true) -> G_Object:
    if init: add_child(obj)
    return obj

func init() -> void:
    temp = add(G_Temp.new())

    configs = add(G_Configs.new())
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
