class_name Player
extends Node

static var scene = load("res://src/game/player/player.tscn")

static func create() -> Player:
    return scene.instantiate();

var player_id: int
var peer_data: PeerData

var player_name: String

func init_player() -> void:
    player_name = "unnamed"

func _ready() -> void:
    name = "Player#" + str(player_id)
    set_multiplayer_authority(peer_data.peer_id, true)

func get_datas_node() -> Node:
    return %Datas

func get_data(type: String) -> PlayerData:
    return get_datas_node().get_node(type)
