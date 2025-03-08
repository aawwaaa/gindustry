class_name ServerHandler
extends Node

static var default_server_handler: Callable = func(): return ServerHandler.new()
static var default_server_handler_priority: int = 0

static func set_default_server_handler(handler: Callable, priority: int = 0) -> void:
    if priority < default_server_handler_priority: return
    default_server_handler = handler
    default_server_handler_priority = priority

static func create() -> ServerHandler:
    return default_server_handler.call()

var client: Vars_Client:
    get: return Vars.client
var server: Vars_Server:
    get: return Vars.server

func _ready() -> void:
    name = "ServerHandler"
    client.player_joined.connect(player_joined)
    client.player_left.connect(player_left)

func _reset() -> void: pass
func reset() -> void:
    _reset()

func _load_server() -> void:
    server.server_ready()
func load_server() -> void:
    _load_server()

func _client_request_join(_peer_data: PeerData) -> bool:
    return true
func client_request_join(peer_data: PeerData) -> bool:
    return _client_request_join(peer_data)

func _client_message(peer_data: PeerData, message: String) -> bool:
    server.send_message("[color=yellow][[color=white]{name}[/color]][/color]: {message}".format({ \
            name = peer_data.player_name,
            message = message
    }))
    return true
func client_message(peer_data: PeerData, message: String) -> bool:
    return _client_message(peer_data, message)

func _client_request_auto_complete(_peer_data: PeerData, _message: String) -> void: pass
func client_request_auto_complete(peer_data: PeerData, message: String) -> void:
    _client_request_auto_complete(peer_data, message)

func _player_joined(player: Player) -> void:
    server.send_message("[color=yellow][color=white]{name}[/color] joined[/color]".format({ \
            name = player.player_name
    }))
func _player_left(player: Player) -> void:
    server.send_message("[color=yellow][color=white]{name}[/color] left[/color]".format({ \
            name = player.player_name
    }))

func player_joined(player: Player) -> void:
    _player_joined(player)
func player_left(player: Player) -> void:
    _player_left(player)

func _has_permission(_player: Player, _permission: String) -> bool:
    return true
func has_permission(player: Player, permission: String) -> bool:
    return _has_permission(player, permission)
