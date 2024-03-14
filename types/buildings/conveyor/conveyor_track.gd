class_name EntityNode_Conveyor_ConveyorTrack
extends Node2D

const ITEM_SIZE = Vector2(Global.TILE_SIZE_VECTOR) / 4
const ITEM_SCALE = ITEM_SIZE / Vector2(Global.TILE_SIZE_VECTOR)

class SingleTrack extends Node2D:
    var base_position: Vector2
    var reached_item: TrackItem = null
    var items: Array[TrackItem] = []

    func add_item(item: Item, position: Vector2) -> void:
        var track_item = TrackItem.new(self, item)
        track_item.position = position
        items.append(track_item)
        track_item.position_updated()

    func item_reach(item: TrackItem) -> void:
        if reached_item: return
        reached_item = item

    func get_reached_item() -> Item:
        return reached_item.item

    func set_reached_item(item: Item) -> void:
        if reached_item: return
        var track_item = TrackItem.new(self, item)
        track_item.position = Vector2.ZERO
        items.append(track_item)
        track_item.position_updated()
        reached_item = track_item

    func remove_reached_item() -> void:
        if not reached_item: return
        reached_item.remove()
        reached_item = null

    func process_update(speed: float, delta: float) -> void:
        for item in items:
            if item == reached_item: continue
            item.process_move(speed, delta)

class TrackItem extends RefCounted:
    var item: Item
    var display: ItemDisplay
    var position: Vector2
    var track: SingleTrack

    func _init(track: SingleTrack, item: Item) -> void:
        self.item = item
        self.track = track
        display = item.create_display()
        track.add_child(display)

    func check_collide(other: TrackItem) -> bool:
        if track != other.track: return false
        if other == self: return false
        var delta = position - other.position
        if delta.abs() > ITEM_SIZE: return false
        return true

    func try_move_to(new_position: Vector2) -> void:
        var old_position = position
        position = new_position
        for item in track.items:
            if check_collide(item):
                position = old_position
                break
        position_updated()

    func position_updated() -> void:
        display.position = position + track.base_position
        if position.length_squared() < 1:
            track.item_reach(self)

    func process_move(speed: float, delta: float) -> void:
        var total_length = speed * delta
        var y_length = minf(absf(position.y), total_length)
        var x_length = minf(absf(position.x), total_length - y_length)
        var move_delta = Vector2((1 if position.x < 0 else -1) * x_length, \
                (1 if position.y < 0 else -1) * y_length)
        try_move_to(position + move_delta)

    func remove() -> void:
        track.remove_child(display)

var speed: float
@export var left_track_end: Vector2:
    set(v):
        left_track_end = v
        left_track.base_position = v
@export var right_track_end: Vector2:
    set(v):
        right_track_end = v
        right_track.base_position = v

var left_track: SingleTrack
var right_track: SingleTrack

func _init() -> void:
    left_track = SingleTrack.new()
    right_track = SingleTrack.new()
    add_child(left_track)
    add_child(right_track)

func _process(delta: float) -> void:
    left_track.process_update(speed, delta)
    right_track.process_update(speed, delta)
