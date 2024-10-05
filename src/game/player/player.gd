class_name Player
extends Node

static func create() -> Player:
    return Player.new()

var player_id: int
var peer_data: PeerData

var player_name: String
var datas: Node
var controller: PlayerController

func init_player() -> void:
    player_name = "unnamed"

func _init() -> void:
    datas = Node.new()
    datas.name = "Datas"
    add_child(datas)

    controller = PlayerController.new()
    controller.name = "Controller"
    add_child(controller)

func _ready() -> void:
    name = "Player#" + str(player_id)
    set_multiplayer_authority(peer_data.peer_id, true)

func get_datas_node() -> Node:
    return datas

func get_data(type: String) -> PlayerData:
    return get_datas_node().get_node(type)

func get_controller() -> PlayerController:
    return controller

func _load_data(stream: Stream) -> Error:
    return Utils.load_data_with_version(stream, [func():
        for _1 in range(stream.get_32()):
            var type = stream.get_string()
            var inst = Vars.players.player_data_types[type].call()
            inst.player = self
            inst.player_data_type = type
            inst._load_data(stream)
            var has_private_data = stream.get_8() == 1
            if has_private_data:
                inst.has_private_data = true
                inst._load_private_data(stream)
            inst.name = type
            get_datas_node().add_child(inst)

        controller.load_data(stream)
        return OK
    ])

func load_data(stream: Stream) -> Error:
    return _load_data(stream)

func _save_data(stream: Stream, with_private_data: bool) -> void:
    Utils.save_data_with_version(stream, [func():
        stream.store_32(get_datas_node().get_child_count())
        for child in get_datas_node().get_children():
            stream.store_string(child.player_data_type)
            child._save_data(stream)
            stream.store_8(1 if with_private_data else 0)
            if with_private_data:
                child._save_private_data(stream)

        controller.save_data(stream)
    ])

func save_data(stream: Stream, with_private_data: bool) -> void:
    _save_data(stream, with_private_data)

