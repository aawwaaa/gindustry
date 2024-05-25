extends Node

# rename to Vars

class Vars_Object extends Node:
    pass

var gobjects: Array[Vars_Object] = []
var logger: Log.Logger = Log.register_logger("G_LogSource");

var main: MainNode
var tree: SceneTree

var core: Vars_Core

var temp: Vars_Temp
var objects: Vars_Objects

var configs: Vars_Configs
var mods: Vars_Mods

var types: Vars_Types
var contents: Vars_Contents

var game: Vars_Game
var players: Vars_Players
var worlds: Vars_Worlds

var presets: Vars_Presets
var saves: Vars_Saves

var client: Vars_Client
var server: Vars_Server

var headless: Vars_Headless
var input: Vars_Input

func _ready() -> void:
    tree = get_tree()

func add(obj: Vars_Object, n = obj.name, add_child_to_self = true) -> Vars_Object:
    if add_child_to_self: add_child(obj)
    obj.name = n
    gobjects.append(obj)
    return obj

func add_obj(obj: Node, n = obj.name, add_child_to_self = true) -> Node:
    if add_child_to_self: add_child(obj)
    obj.name = n
    return obj

func init() -> void:
    core = add(Vars_Core.new(), "Core")

    temp = add(Vars_Temp.new(), "Temp")
    objects = add(Vars_Objects.new(), "Objects")

    configs = add(Vars_Configs.new(), "Configs")
    mods = add(Vars_Mods.new(), "Mods")

    types = add(Vars_Types.new(), "Types")
    contents = add(Vars_Contents.new(), "Contents")

    game = add(Vars_Game.new(), "Game")
    players = add(Vars_Players.new(), "Players")
    worlds = add(Vars_Worlds.new(), "Worlds")

    presets = add(Vars_Presets.new(), "Presets")
    saves = add(Vars_Saves.new(), "Saves")

    client = add(Vars_Client.new(), "Client")
    server = add(Vars_Server.new(), "Server")

    headless = add(Vars_Headless.new(), "Headless")
    input = add(Vars_Input.new(), "Input")
